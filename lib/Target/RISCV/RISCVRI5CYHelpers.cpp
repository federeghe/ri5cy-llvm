#define DEBUG_TYPE "riscv-ri5cy-passes"
#include "RISCV.h"
#include "RISCVInstrBuilder.h"
#include "RISCVInstrInfo.h"
#include "llvm/ADT/Statistic.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/Support/MathExtras.h"
#include "llvm/Analysis/TargetTransformInfo.h"
#include "llvm/Target/TargetMachine.h"
#include "RISCVRI5CYHelpers.h"

using namespace llvm;

INITIALIZE_PASS(RISCVRI5CYIR, "riscv-ri5cy-IR-pass", 
                "RISCV RI5CY IR pass",false, false)

/// createRISCVBranchSelectionPass - returns an instance of the Branch Selection
/// Pass
///
FunctionPass *llvm::createRISCVRI5CYIRPass() {
  return new RISCVRI5CYIR();
}

bool RISCVRI5CYIR::runOnFunction(Function &F) {

    // Check if we are RI5CY()
//    this->TM = static_cast<const RISCVTargetMachine*>(&F.getTarget());
//    assert(TM->getSubtargetImpl()->isR5CY());


    errs() << "runOnFunction(" << F.getName().str() << ")\n";


  return false;
}


bool RI5CY_bitIntervalExtraction( int n, unsigned int* l_pos, unsigned int* r_pos, bool invert) {

      unsigned int l_limit, r_limit;

			enum { BEFORE, IN, AFTER, INVALID } status;

			status = BEFORE;

			for(int i=0; i<32; i++) {
				if ( invert ^ ((bool)(( ((int32_t)1) << i) & n)) ) {
					if (status == IN) {
						status = AFTER;
						l_limit = i-1;
					}
				} else {
					if (status == BEFORE) {
						status = IN;
						r_limit = i;
					}
					else if (status == AFTER) {
						// We found another 0 after the first sequence 
						status = INVALID;
						return false;
					}
				}

			}

      if (status == BEFORE) {
        return false;
      }

      if (l_pos != NULL ) {
          *l_pos = l_limit;
      }

      if (r_pos != NULL ) {
          *r_pos = r_limit;
      }

      return true;  
}


extern bool RI5CY_pclip_check(SelectionDAG* CurDAG, const SDValue &Dest, SDValue &SRC1, SDValue &SRC2, bool unsign) {

	/* 
     This rule is a bit complicated to be matched. An example of generated 
     structure is:
    
                                        load       constant    setlt
                                           \__________|__________/
                                                      |
              load    constant     setlt            setcc              load        constant
                \________|__________/                 \__________________|_____________/
                         |                                               |
                       setcc                    constant               select
                         \________________________|_____________________/
                                                  |
                                                select
      
    However we have to match also different structurs, like the one with setgt
    and so on.                                            
	 */


  // As first, we check that the opcode of the main instruction is a select
  // and than that the first operand is a setcc. This is valid for any
  // structure
  if (Dest.getOpcode() != ISD::SELECT) return false;
  if (Dest.getOperand(0).getOpcode() != ISD::SETCC) return false;


  // Now, serach for the select and constant. In this case we have to check
  // in which position they are. Constant in this case is the lowerbound OR
  // the upperbound depending on subsequent setlt/setgt
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
    // If no constant and/or no select, we cannot manage this instruction with
    // p.clip
    return false;
  }

  // Now analyze the outer setcc.
  auto setcc_outer = Dest.getOperand(0);
  const SDValue *reg_in;
  int pos_constant_low_cc;
  // Check the position of constant and register. We are not interested in which
  // instruction generate the value in the register, we are only interested in
  // which register is.
  if (setcc_outer.getOperand(0).getOpcode() == ISD::Constant) {
    pos_constant_low_cc = 0;
    reg_in = &setcc_outer.getOperand(1);
  } else
  if (setcc_outer.getOperand(1).getOpcode() == ISD::Constant)
  {
    reg_in = &setcc_outer.getOperand(0);
    pos_constant_low_cc = 1;
  } else {
    // A constant is necessary, otherwise, cannot manage
    return false;
  }

  // This is the constant of the outer level (the select constant). If it is 0,
  // we can match pclip, otherwise we cannot
  int32_t low_constant = Dest.getConstantOperandVal(pos_constant_low);

  if (! unsign) {
    if ( low_constant >= 0) {
      return false;
    }
  } else {
    // If it is unsigned (p.clipu) we have to check that the outer constant is
    // zero, otherwise it is not possible.
    if ( low_constant != 0) {
      return false;
    }
  }

  // This is the inner constant. We noticed that llvm usually generates a setlt
  // with constant+1 operator (contrary to the requested setle and constant)
  int32_t low_constant_cc = setcc_outer.getConstantOperandVal(pos_constant_low_cc);

  if (setcc_outer.getOperand(2).getOpcode() == ISD::CONDCODE && cast<CondCodeSDNode>(*setcc_outer.getOperand(2).getNode()).get() == ISD::SETLT) {

    if ((!unsign && low_constant_cc != low_constant+1) || (unsign && low_constant_cc!=1) ) {
      return false;
    }
  } else {
    // TODO: Manage case with different orders
    return false;
  }

  // Proceed similar to the outer select for the inner one.
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

  // We have 3 reference to the register to clip. We have to check that all of
  // these references are actually the same register, otherwise we cannot apply
  // the pclip.
  MemSDNode *mem_in = cast<MemSDNode>(*reg_in);
  MemSDNode *mem_out = cast<MemSDNode>(*reg_out);
  MemSDNode *mem_xxx = cast<MemSDNode>(*reg_xxx);

  if(*(mem_in->getMemOperand()) != *(mem_out->getMemOperand())   ||
     *(mem_in->getMemOperand()) != *(mem_xxx->getMemOperand()) ) {
    return false;
  }
 
  // And finally check the last constant
  int32_t inner_low_constant_cc = setcc_inner.getConstantOperandVal(inner_pos_constant_low_cc);

 
  if (setcc_inner.getOperand(2).getOpcode() == ISD::CONDCODE && cast<CondCodeSDNode>(*setcc_inner.getOperand(2).getNode()).get() == ISD::SETLT) {
    // If it is usigned, we are not interested in this check
    if (!unsign && inner_low_constant_cc != -low_constant_cc) {
      return false;
    }
  } else {
    // TODO: Manage case with different orders
    return false;
  }

  // This is a strong check, but we have to test it only at this stage. Maybe it
  // can be anticipated if it is non-usigned to get more performance in compialtion
  // (TODO) 
  if (__builtin_popcount(inner_low_constant_cc+1) != 1) {
    return false;
  }


  // Get the exponent for the immediate (it should be in the form 2^n)
  unsigned int imm = 32-__builtin_clz(inner_low_constant_cc+1)-1;
  
  SRC1 = *reg_in;
  SRC2 = CurDAG->getConstant(imm, SDLoc(Dest), MVT::i32);

  return true;
}


