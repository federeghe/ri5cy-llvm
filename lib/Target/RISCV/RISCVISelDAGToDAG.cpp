//===-- RISCVISelDAGToDAG.cpp - A dag to dag inst selector for RISCV ------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file defines an instruction selector for the RISCV target.
//
//===----------------------------------------------------------------------===//

#include "RISCVTargetMachine.h"
#include "RISCVRI5CYPasses.h"
#include "llvm/CodeGen/SelectionDAGISel.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/raw_ostream.h"

#warning REMOVE ME

using namespace llvm;

#define DEBUG_TYPE "riscv-isel"

namespace {
// Used to build addressing modes.
struct RISCVAddressingMode {
  // The shape of the address.
  enum AddrForm {
    // base+offset
    FormBO
  };
  AddrForm Form;

  // The type of displacement. 
  enum OffRange {
    Off12Only
  };
  OffRange OffR;

  // The parts of the address.  The address is equivalent to:
  //
  //     Base + Offset + Index + (IncludesDynAlloc ? ADJDYNALLOC : 0)
  SDValue Base;
  int64_t Offset;

  RISCVAddressingMode(AddrForm form, OffRange offr)
    : Form(form), OffR(offr), Base(), Offset(0) {}

  void dump() {
    errs() << "RISCVAddressingMode " << this << '\n';

    errs() << " Base ";
    if (Base.getNode() != 0)
      Base.getNode()->dump();
    else
      errs() << "null\n";

    errs() << " Offset " << Offset;
  }
};

class RISCVDAGToDAGISel : public SelectionDAGISel {
  const RISCVTargetLowering &Lowering;
  const RISCVSubtarget &Subtarget;

  // Used by RISCVOperands.td to create integer constants.
  inline SDValue getImm(const SDNode *Node, uint64_t Imm) {
    return CurDAG->getTargetConstant(Imm, SDLoc(Node), Node->getValueType(0));
  }
  /// getI32Imm - Return a target constant with the specified value, of type
  /// i32.
  SDValue getI32Imm(unsigned Imm, SDLoc DL) {
    return CurDAG->getTargetConstant(Imm, DL, MVT::i32);
  }

  // Try to fold more of the base or index of AM into AM, where IsBase
  // selects between the base and index.
  bool expandAddress(RISCVAddressingMode &AM, bool IsBase);

  // Try to describe N in AM, returning true on success.
  bool selectAddress(SDValue N, RISCVAddressingMode &AM);

  // Extract individual target operands from matched address AM.
  void getAddressOperands(const RISCVAddressingMode &AM, EVT VT,
                          SDValue &Base, SDValue &Disp);
  void getAddressOperands(const RISCVAddressingMode &AM, EVT VT,
                          SDValue &Base, SDValue &Disp, SDValue &Index);

  //RISCV
  bool selectMemRegAddr(SDValue Addr, SDValue &Offset, SDValue &Base) {
      
    EVT ValTy = Addr.getValueType();

    // if Address is FI, get the TargetFrameIndex.
    if (FrameIndexSDNode *FIN = dyn_cast<FrameIndexSDNode>(Addr)) {
      Base   = CurDAG->getTargetFrameIndex(FIN->getIndex(), ValTy);
      Offset = CurDAG->getTargetConstant(0, SDLoc(Addr), ValTy);
      return true;
    }

    if (TM.getRelocationModel() != Reloc::PIC_) {
      if ((Addr.getOpcode() == ISD::TargetExternalSymbol ||
          Addr.getOpcode() == ISD::TargetGlobalAddress))
        return false;
    }

    // Addresses of the form FI+const or FI|const
    if (CurDAG->isBaseWithConstantOffset(Addr)) {
      ConstantSDNode *CN = dyn_cast<ConstantSDNode>(Addr.getOperand(1));
      if (isInt<12>(CN->getSExtValue())) {
  
        // If the first operand is a FI, get the TargetFI Node
        if (FrameIndexSDNode *FIN = dyn_cast<FrameIndexSDNode>
                                    (Addr.getOperand(0)))
          Base = CurDAG->getTargetFrameIndex(FIN->getIndex(), ValTy);
        else
          Base = Addr.getOperand(0);
  
        Offset = CurDAG->getTargetConstant(CN->getZExtValue(), SDLoc(Addr), ValTy);
        return true;
      }
    }

    //Last case
    Base = Addr;
    Offset = CurDAG->getTargetConstant(0, SDLoc(Addr), Addr.getValueType());
    return true;
  }

  bool selectRegAddr(SDValue Addr, SDValue &Base) {
    //always just register
    Base = Addr;
    return true;
  }

  bool replaceUsesWithZeroReg(MachineRegisterInfo *MRI,
                              const MachineInstr& MI) {
    unsigned DstReg = 0, ZeroReg = 0;
  
    // Check if MI is "addiu $dst, $zero, 0" or "daddiu $dst, $zero, 0".
    if ((MI.getOpcode() == RISCV::ADDI) &&
        (MI.getOperand(1).isReg()) && //avoid frame-index
        (MI.getOperand(1).getReg() == RISCV::zero) &&
        (MI.getOperand(2).getImm() == 0)) {
      DstReg = MI.getOperand(0).getReg();
      ZeroReg = RISCV::zero;
    } else if ((MI.getOpcode() == RISCV::ADDI64) &&
               (MI.getOperand(1).isReg()) && //avoid frame-index
               (MI.getOperand(1).getReg() == RISCV::zero_64) &&
               (MI.getOperand(2).getImm() == 0)) {
      DstReg = MI.getOperand(0).getReg();
      ZeroReg = RISCV::zero_64;
    } else if ((MI.getOpcode() == RISCV::ADDIW) &&
               (MI.getOperand(1).isReg()) && //avoid frame-index
               (MI.getOperand(1).getReg() == RISCV::zero_64) &&
               (MI.getOperand(2).getImm() == 0)) {
      DstReg = MI.getOperand(0).getReg();
      ZeroReg = RISCV::zero_64;
    }
  
    if (!DstReg)
      return false;
  
    // Replace uses with ZeroReg.
    for (MachineRegisterInfo::use_iterator U = MRI->use_begin(DstReg),
         E = MRI->use_end(); U != E;) {
      MachineOperand &MO = *U;
      unsigned OpNo = U.getOperandNo();
      MachineInstr *MI = MO.getParent();
      ++U;
  
      // Do not replace if it is a phi's operand or is tied to def operand.
      if (MI->isPHI() || MI->isRegTiedToDefOperand(OpNo) || MI->isPseudo())
        continue;
  
      MO.setReg(ZeroReg);
    }
  
    return true;
  }

  //End RISCV

  // PC-relative address matching routines used by RISCVOperands.td.
  bool selectPCRelAddress(SDValue Addr, SDValue &Target) {
    if (Addr.getOpcode() == RISCVISD::PCREL_WRAPPER) {
      Target = Addr.getOperand(0);
      return true;
    }
    return false;
  }

  // If Op0 is null, then Node is a constant that can be loaded using:
  //
  //   (Opcode UpperVal LowerVal)
  //
  // If Op0 is nonnull, then Node can be implemented using:
  //
  //   (Opcode (Opcode Op0 UpperVal) LowerVal)
  SDNode *splitLargeImmediate(unsigned Opcode, SDNode *Node, SDValue Op0,
                              uint64_t UpperVal, uint64_t LowerVal);


 bool SelectPCLIP(SDValue Dest, SDValue &SRC1, SDValue &SRC2);

public:
  RISCVDAGToDAGISel(RISCVTargetMachine &TM, CodeGenOpt::Level OptLevel)
    : SelectionDAGISel(TM, OptLevel),
      Lowering(*TM.getSubtargetImpl()->getTargetLowering()),
      Subtarget(*TM.getSubtargetImpl()) { }

  // Override MachineFunctionPass.
  const char *getPassName() const override {
    return "RISCV DAG->DAG Pattern Instruction Selection";
  }

  // Override SelectionDAGISel.
  virtual bool runOnMachineFunction(MachineFunction &MF);
  SDNode *Select(SDNode *Node) override;
  virtual void processFunctionAfterISel(MachineFunction &MF);
  bool SelectInlineAsmMemoryOperand(const SDValue &Op, unsigned ConstraintID,
                                    std::vector<SDValue> &OutOps) override;

  // Include the pieces autogenerated from the target description.
  #include "RISCVGenDAGISel.inc"
};
} // end anonymous namespace

bool RISCVDAGToDAGISel::runOnMachineFunction(MachineFunction &MF) {
  bool ret = SelectionDAGISel::runOnMachineFunction(MF);

  processFunctionAfterISel(MF);

  return ret;
}

FunctionPass *llvm::createRISCVISelDag(RISCVTargetMachine &TM,
                                         CodeGenOpt::Level OptLevel) {
  return new RISCVDAGToDAGISel(TM, OptLevel);
}

// Return true if Val should be selected as a displacement for an address
// with range DR.  Here we're interested in the range of both the instruction
// described by DR and of any pairing instruction.
static bool selectOffset(RISCVAddressingMode::OffRange OffR, int64_t Val) {
  switch (OffR) {
  case RISCVAddressingMode::Off12Only:
    return isInt<12>(Val);
  }
  llvm_unreachable("Unhandled offset range");
}

// The base or index of AM is equivalent to Op0 + Op1, where IsBase selects
// between the base and index.  Try to fold Op1 into AM's displacement.
static bool expandOffset(RISCVAddressingMode &AM, bool IsBase,
                       SDValue Op0, ConstantSDNode *Op1) {
  // First try adjusting the displacement.
  int64_t TestOffset = AM.Offset + Op1->getSExtValue();
  if (selectOffset(AM.OffR, TestOffset)) {
    //changeComponent(AM, IsBase, Op0);
    AM.Base = Op0;
    AM.Offset = TestOffset;
    return true;
  }

  // We could consider forcing the displacement into a register and
  // using it as an index, but it would need to be carefully tuned.
  return false;
}

bool RISCVDAGToDAGISel::expandAddress(RISCVAddressingMode &AM,
                                        bool IsBase) {
  //SDValue N = IsBase ? AM.Base : AM.Index;
  SDValue N = AM.Base;
  unsigned Opcode = N.getOpcode();
  if (Opcode == ISD::TRUNCATE) {
    N = N.getOperand(0);
    Opcode = N.getOpcode();
  }
  if (Opcode == ISD::ADD || CurDAG->isBaseWithConstantOffset(N)) {
    SDValue Op0 = N.getOperand(0);
    SDValue Op1 = N.getOperand(1);

    unsigned Op0Code = Op0->getOpcode();
    unsigned Op1Code = Op1->getOpcode();

    if (Op0Code == ISD::Constant)
      return expandOffset(AM, IsBase, Op1, cast<ConstantSDNode>(Op0));
    if (Op1Code == ISD::Constant)
      return expandOffset(AM, IsBase, Op0, cast<ConstantSDNode>(Op1));

  }
  return false;
}

// Return true if an instruction with displacement range DR should be
// used for displacement value Val.  selectDisp(DR, Val) must already hold.
static bool isValidOffset(RISCVAddressingMode::OffRange OffR, int64_t Val) {
  assert(selectOffset(OffR, Val) && "Invalid displacement");
  switch (OffR) {
  case RISCVAddressingMode::Off12Only:
    return true;
  }
  llvm_unreachable("Unhandled displacement range");
}

// Return true if Addr is suitable for AM, updating AM if so.
bool RISCVDAGToDAGISel::selectAddress(SDValue Addr,
                                        RISCVAddressingMode &AM) {
  // Start out assuming that the address will need to be loaded separately,
  // then try to extend it as much as we can.
  AM.Base = Addr;

  // First try treating the address as a constant.
  if (Addr.getOpcode() == ISD::Constant &&
      expandOffset(AM, true, SDValue(), cast<ConstantSDNode>(Addr)))
  { }

  // Reject cases where the other instruction in a pair should be used.
  if (!isValidOffset(AM.OffR, AM.Offset))
    return false;

  DEBUG(AM.dump());
  return true;
}

// Insert a node into the DAG at least before Pos.  This will reposition
// the node as needed, and will assign it a node ID that is <= Pos's ID.
// Note that this does *not* preserve the uniqueness of node IDs!
// The selection DAG must no longer depend on their uniqueness when this
// function is used.
static void insertDAGNode(SelectionDAG *DAG, SDNode *Pos, SDValue N) {
  if (N.getNode()->getNodeId() == -1 ||
      N.getNode()->getNodeId() > Pos->getNodeId()) {
    DAG->RepositionNode(Pos->getIterator(), N.getNode());
    N.getNode()->setNodeId(Pos->getNodeId());
  }
}

void RISCVDAGToDAGISel::getAddressOperands(const RISCVAddressingMode &AM,
                                             EVT VT, SDValue &Base,
                                             SDValue &Offset) {
  Base = AM.Base;
  if (!Base.getNode())
    // Register 0 means "no base".  This is mostly useful for shifts.
    Base = CurDAG->getRegister(0, VT);
  else if (Base.getOpcode() == ISD::FrameIndex) {
    // Lower a FrameIndex to a TargetFrameIndex.
    int64_t FrameIndex = cast<FrameIndexSDNode>(Base)->getIndex();
    Offset = CurDAG->getTargetFrameIndex(FrameIndex, VT);
    Base = CurDAG->getTargetConstant(AM.Offset, SDLoc(Base), VT);
    return;
  } else if (Base.getValueType() != VT) {
    // Truncate values from i64 to i32, for shifts.
    assert(VT == MVT::i32 && Base.getValueType() == MVT::i64 &&
           "Unexpected truncation");
    SDLoc DL(Base);
    SDValue Trunc = CurDAG->getNode(ISD::TRUNCATE, DL, VT, Base);
    insertDAGNode(CurDAG, Base.getNode(), Trunc);
    Base = Trunc;
  }

  // Lower the displacement to a TargetConstant.
  Offset = CurDAG->getTargetConstant(AM.Offset, SDLoc(Base), VT);
}


SDNode *RISCVDAGToDAGISel::splitLargeImmediate(unsigned Opcode, SDNode *Node,
                                                 SDValue Op0, uint64_t UpperVal,
                                                 uint64_t LowerVal) {
  EVT VT = Node->getValueType(0);
  SDLoc DL(Node);
  SDValue Upper = CurDAG->getConstant(UpperVal, DL, VT);
  if (Op0.getNode())
    Upper = CurDAG->getNode(Opcode, DL, VT, Op0, Upper);
  Upper = SDValue(Select(Upper.getNode()), 0);

  SDValue Lower = CurDAG->getConstant(LowerVal, DL, VT);
  SDValue Or = CurDAG->getNode(Opcode, DL, VT, Upper, Lower);
  return Or.getNode();
}

SDNode *RISCVDAGToDAGISel::Select(SDNode *Node) {
  SDLoc DL(Node);
  // Dump information about the Node being selected
  DEBUG(errs() << "Selecting: "; Node->dump(CurDAG); errs() << "\n");

  // If we have a custom node, we already have selected!
  if (Node->isMachineOpcode()) {
    DEBUG(errs() << "== "; Node->dump(CurDAG); errs() << "\n");
    return 0;
  }

  unsigned Opcode = Node->getOpcode();
  switch (Opcode) {
  case ISD::FrameIndex: {
    SDValue imm = CurDAG->getTargetConstant(0, DL, Subtarget.isRV64() ? MVT::i64 : MVT::i32);
    int FI = cast<FrameIndexSDNode>(Node)->getIndex();
    SDValue TFI =
        CurDAG->getTargetFrameIndex(FI, getTargetLowering()->getPointerTy(CurDAG->getDataLayout()));
    unsigned Opc = Subtarget.isRV64() ? RISCV::ADDI64 : RISCV::ADDI;
    EVT VT = Subtarget.isRV64() ? MVT::i64 : MVT::i32;
    
    if(Node->hasOneUse()) //don't create a new node just morph this one
      return CurDAG->SelectNodeTo(Node, Opc, VT, TFI, imm);
    return CurDAG->getMachineNode(Opc, DL, VT, TFI, imm);
  }
  }//end special selections

  // Select the default instruction
  SDNode *ResNode = SelectCode(Node);

  DEBUG(errs() << "=> ";
        if (ResNode == NULL || ResNode == Node)
          Node->dump(CurDAG);
        else
          ResNode->dump(CurDAG);
        errs() << "\n";
        );
  return ResNode;
}

bool RISCVDAGToDAGISel::
SelectInlineAsmMemoryOperand(const SDValue &Op,
                             unsigned ConstraintID,
                             std::vector<SDValue> &OutOps) {
  switch(ConstraintID) {
  default:
    llvm_unreachable("Unexpected asm memory constraint");
  case InlineAsm::Constraint_m:

    SDValue Base, Offset;
    selectMemRegAddr(Op, Base, Offset);
    OutOps.push_back(Base);
    OutOps.push_back(Offset);
    return false;
  }
  return false;
}

void RISCVDAGToDAGISel::processFunctionAfterISel(MachineFunction &MF) {

  for (auto &MBB: MF)
    for (auto &I: MBB) {
      //replaceUsesWithZeroReg(MRI, *I);
    }
}


bool RISCVDAGToDAGISel::SelectPCLIP(SDValue Dest, SDValue &SRC1, SDValue &SRC2) {
	if (Dest.getOpcode() != ISD::SELECT) return false;
	if (Dest.getOperand(0).getOpcode() != ISD::SETCC) return false;

  int select;
  int pos_constant_low;

	if (   Dest.getOperand(1).getOpcode() == ISD::SELECT 
      && Dest.getOperand(2).getOpcode() == ISD::Constant) {
    select = 1;
    pos_constant_low = 2;
  } else
	if (   Dest.getOperand(1).getOpcode() == ISD::Constant 
      && Dest.getOperand(2).getOpcode() == ISD::SELECT) {
    select = 2;
    pos_constant_low = 1;
  } else { 
    return false;
  }

  /** Select one check **/

  auto setcc_outer = Dest.getOperand(0);
  const SDValue *reg_in;
  int pos_constant_low_cc;
  // Check setCC
  if (setcc_outer.getOperand(0).getOpcode() == ISD::Constant) {
    pos_constant_low_cc = 0;
    reg_in = &setcc_outer.getOperand(1);
  } else
  if (setcc_outer.getOperand(1).getOpcode() == ISD::Constant)
  {
    reg_in = &setcc_outer.getOperand(0);
    pos_constant_low_cc = 1;
  } else {
    return false;
  }

  int32_t low_constant = Dest.getConstantOperandVal(pos_constant_low);

  if ( low_constant >= 0) {
    return false;
  }
  if (__builtin_popcount(-low_constant) != 1) {
    return false;
  }

  int32_t low_constant_cc = setcc_outer.getConstantOperandVal(pos_constant_low_cc);


  if (setcc_outer.getOperand(2).getOpcode() == ISD::CONDCODE && cast<CondCodeSDNode>(*setcc_outer.getOperand(2).getNode()).get() == ISD::SETLT) {

    if (low_constant_cc != low_constant+1 ) {
      return false;
    }
  } else {
    // TODO: Manage case with different orders
    return false;
  }

  /* Check the inner select */
  auto setcc_inner = Dest.getOperand(select).getOperand(0);
  auto reg_xxx = &Dest.getOperand(select).getOperand(1);

  const SDValue *reg_out;
  int inner_pos_constant_low_cc;
  if (setcc_inner.getOperand(0).getOpcode() == ISD::Constant) {
    inner_pos_constant_low_cc = 0;
    reg_out = &setcc_inner.getOperand(1);
  } else 
  if (setcc_outer.getOperand(1).getOpcode() == ISD::Constant)
  {
    reg_out = &setcc_inner.getOperand(0);
    inner_pos_constant_low_cc = 1;
  } else {
    return false;
  } 


  MemSDNode *mem_in = cast<MemSDNode>(*reg_in);
  MemSDNode *mem_out = cast<MemSDNode>(*reg_out);
  MemSDNode *mem_xxx = cast<MemSDNode>(*reg_xxx);

  if(*(mem_in->getMemOperand()) != *(mem_out->getMemOperand())   ||
     *(mem_in->getMemOperand()) != *(mem_xxx->getMemOperand()) ) {
    return false;
  }

  
  int32_t inner_low_constant_cc = setcc_inner.getConstantOperandVal(inner_pos_constant_low_cc);

 
  if (setcc_inner.getOperand(2).getOpcode() == ISD::CONDCODE && cast<CondCodeSDNode>(*setcc_inner.getOperand(2).getNode()).get() == ISD::SETLT) {
    if (inner_low_constant_cc != -low_constant_cc) {
      return false;
    }
  } else {
    // TODO: Manage case with different orders
    return false;
  }

  unsigned int imm = 32-__builtin_clz(-low_constant)-1;
  
  SRC1 = *reg_in;
  SRC2 = CurDAG->getConstant(imm, SDLoc(Dest), MVT::i32);
  errs() << "CHECKED OK IMM=" << imm << "!\n"; 


	return true;
}
