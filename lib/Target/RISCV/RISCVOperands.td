//===-- RISCVOperands.td - RISCV instruction operands --------*- tblgen-*--===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Class definitions
//===----------------------------------------------------------------------===//

class ImmediateAsmOperand<string name>
  : AsmOperandClass {
  let Name = name;
  let RenderMethod = "addImmOperands";
}

// Constructs both a DAG pattern and instruction operand for an immediate
// of type VT.  PRED returns true if a node is acceptable and XFORM returns
// the operand value associated with the node.  ASMOP is the name of the
// associated asm operand, and also forms the basis of the asm print method.
class Immediate<ValueType vt, code pred, SDNodeXForm xform, string asmop>
  : PatLeaf<(vt imm), pred, xform>, Operand<vt> {
  let PrintMethod = "print"##asmop##"Operand";
  let ParserMatchClass = !cast<AsmOperandClass>(asmop);
}

// Constructs both a DAG pattern and instruction operand for a PC-relative
// address with address size VT.  SELF is the name of the operand.
class PCRelAddress<ValueType vt, string self>
  : ComplexPattern<vt, 1, "selectPCRelAddress", [r_pcrel_wrapper]>,
    Operand<vt> {
  let MIOperandInfo = (ops !cast<Operand>(self));
}

class PCRelAddressNoWrap<ValueType vt, string self>
  : ComplexPattern<vt, 1, "selectPCRelAddress">,
    Operand<vt> {
  let MIOperandInfo = (ops !cast<Operand>(self));
}

// Constructs an AsmOperandClass for addressing mode FORMAT, treating the
// registers as having BITSIZE bits and displacements as having DISPSIZE bits.
class AddressAsmOperand<string format, string bitsize, string dispsize>
  : AsmOperandClass {
  let Name = format##bitsize##"Disp"##dispsize;
  let ParserMethod = "parse"##format##bitsize;
  let RenderMethod = "add"##format##"Operands";
}

//===----------------------------------------------------------------------===//
// Extracting immediate operands from nodes
// These all create MVT::i64 nodes to ensure the value is not sign-extended
// when converted from an SDNode to a MachineOperand later on.
//===----------------------------------------------------------------------===//

// Truncate an immediate to a 32-bit signed quantity.
def SIMM32 : SDNodeXForm<imm, [{
  return CurDAG->getTargetConstant(int32_t(N->getZExtValue()), MVT::i32);
}]>;

// Truncate an immediate to a 32-bit unsigned quantity.
def UIMM32 : SDNodeXForm<imm, [{
  return CurDAG->getTargetConstant(uint32_t(N->getZExtValue()), MVT::i32);
}]>;

// Truncate an immediate to a 64-bit signed quantity.
def SIMM64 : SDNodeXForm<imm, [{
  return CurDAG->getTargetConstant(int64_t(N->getZExtValue()), MVT::i64);
}]>;

// Truncate an immediate to a 64-bit unsigned quantity.
def UIMM64 : SDNodeXForm<imm, [{
  return CurDAG->getTargetConstant(uint64_t(N->getZExtValue()), MVT::i64);
}]>;

//===----------------------------------------------------------------------===//
// Immediate asm operands.
//===----------------------------------------------------------------------===//

def U4Imm  : ImmediateAsmOperand<"U4Imm">;
def S12Imm : ImmediateAsmOperand<"S12Imm">;
def U12Imm : ImmediateAsmOperand<"U12Imm">;
def S20Imm : ImmediateAsmOperand<"S20Imm">;
def U20Imm : ImmediateAsmOperand<"U20Imm">;
def S32Imm : ImmediateAsmOperand<"S32Imm">;
def U32Imm : ImmediateAsmOperand<"U32Imm">;
def S64Imm : ImmediateAsmOperand<"S64Imm">;
def U64Imm : ImmediateAsmOperand<"U64Imm">;

//===----------------------------------------------------------------------===//
// i32 immediates
//===----------------------------------------------------------------------===//

//sign-extended 12 bit immediate
def imm32sx12 : Immediate<i32, [{
  return isInt<12>(N->getSExtValue());
}], NOOP_SDNodeXForm, "S12Imm">;
def imm32sxu12 : Immediate<i32, [{
  return isUInt<12>(N->getSExtValue());
}], NOOP_SDNodeXForm, "U12Imm">;
//zero-extended 12 bit immediate
def imm32zx12 : Immediate<i32, [{
  return isUInt<12>(N->getZExtValue());
}], NOOP_SDNodeXForm, "U12Imm">;
//sign-extended 20 bit immediate
def imm32sx20 : Immediate<i32, [{
  return isInt<20>(N->getSExtValue());
}], NOOP_SDNodeXForm, "S20Imm">;
def imm32sxu20 : Immediate<i32, [{
  return isUInt<20>(N->getSExtValue());
}], NOOP_SDNodeXForm, "U20Imm">;
//zero-extended 20 bit immediate
def imm32zx20 : Immediate<i32, [{
  return isUInt<20>(N->getZExtValue());
}], NOOP_SDNodeXForm, "U20Imm">;

def simm32 : Immediate<i32, [{}], SIMM32, "S32Imm">;
def uimm32 : Immediate<i32, [{}], UIMM32, "U32Imm">;

def imm32 : ImmLeaf<i32, [{}]>, Operand<i32>;

//===----------------------------------------------------------------------===//
// 64-bit immediates
//===----------------------------------------------------------------------===//

//sign-extended 12 bit immediate
def imm64sx12 : Immediate<i64, [{
  return isInt<12>(N->getSExtValue());
}], NOOP_SDNodeXForm, "S12Imm">;
def imm64sxu12 : Immediate<i64, [{
  return isUInt<12>(N->getSExtValue());
}], NOOP_SDNodeXForm, "U12Imm">;
//zero-extended 12 bit immediate
def imm64zx12 : Immediate<i64, [{
  return isUInt<12>(N->getZExtValue());
}], NOOP_SDNodeXForm, "U12Imm">;
//sign-extended 20 bit immediate
def imm64sx20 : Immediate<i64, [{
  return isInt<20>(N->getSExtValue());
}], NOOP_SDNodeXForm, "S20Imm">;
def imm64sxu20 : Immediate<i64, [{
  return isUInt<20>(N->getSExtValue());
}], NOOP_SDNodeXForm, "U20Imm">;
//zero-extended 20 bit immediate
def imm64zx20 : Immediate<i64, [{
  return isUInt<20>(N->getZExtValue());
}], NOOP_SDNodeXForm, "U20Imm">;
//sign-extended 32bit immediate for LUI/ADDI max load size
def imm64sxu32 : Immediate<i64, [{
  return isUInt<32>(N->getSExtValue());
}], NOOP_SDNodeXForm, "U32Imm">;

def simm64 : Immediate<i64, [{}], SIMM64, "S64Imm">;
def uimm64 : Immediate<i64, [{}], UIMM64, "U64Imm">;

def imm64 : ImmLeaf<i64, [{}]>, Operand<i64>;

//===----------------------------------------------------------------------===//
// Fence immediates
//===----------------------------------------------------------------------===//

def fenceImm : Immediate<i32, [{
  return isUInt<4>(N->getZExtValue());
}], NOOP_SDNodeXForm, "U4Imm">;
def fenceImm64 : Immediate<i64, [{
  return isUInt<4>(N->getZExtValue());
}], NOOP_SDNodeXForm, "U4Imm">;

//===----------------------------------------------------------------------===//
// Floating-point immediates
//===----------------------------------------------------------------------===//

// Floating-point zero.
def fpimm0 : PatLeaf<(fpimm), [{ return N->isExactlyValue(+0.0); }]>;

//===----------------------------------------------------------------------===//
// Memory address operands
//===----------------------------------------------------------------------===//

def mem : Operand<i32> {
  let MIOperandInfo = (ops imm32sx12, GR32);
  //let EncoderMethod = "getMemRegEncoding";
  let OperandType = "OPERAND_MEMORY";
  let PrintMethod = "printMemOperand";
}

def mem64 : Operand<i64> {
  let MIOperandInfo = (ops imm64sx12, GR64);
  //let EncoderMethod = "getMemRegEncoding";
  let OperandType = "OPERAND_MEMORY";
  let PrintMethod = "printMemOperand";
}

def jalrmem : Operand<i32> {
  let MIOperandInfo = (ops imm32sx12, GR32);
  //let EncoderMethod = "getMemRegEncoding";
  let OperandType = "OPERAND_MEMORY";
  let PrintMethod = "printJALRMemOperand";
}

def jalrmem64 : Operand<i64> {
  let MIOperandInfo = (ops imm64sx12, GR64);
  //let EncoderMethod = "getMemRegEncoding";
  let OperandType = "OPERAND_MEMORY";
  let PrintMethod = "printJALRMemOperand";
}

def memreg : Operand<i32> {
  let MIOperandInfo = (ops GR32);
  //let EncoderMethod = "getMemRegEncoding";
  let OperandType = "OPERAND_MEMORY";
  let PrintMethod = "printMemRegOperand";
}

def memreg64 : Operand<i64> {
  let MIOperandInfo = (ops GR64);
  //let EncoderMethod = "getMemRegEncoding";
  let OperandType = "OPERAND_MEMORY";
  let PrintMethod = "printMemRegOperand";
}


def regaddr : ComplexPattern<iPTR, 1, "selectRegAddr">;
def addr    : ComplexPattern<iPTR, 2, "selectMemRegAddr">;
def raaddr  : ComplexPattern<i64 , 2, "selectMemRegAddr", [add]>;

//===----------------------------------------------------------------------===//
// Symbolic address operands
//===----------------------------------------------------------------------===//

def jumptarget : Operand<OtherVT> {
  let EncoderMethod = "getJumpTargetEncoding";
}

def brtarget : Operand<OtherVT> {
  let PrintMethod = "printBranchTarget";
  let EncoderMethod = "getBranchTargetEncoding";
}

def pcimm : PCRelAddress<i32, "pcimm"> {
  let EncoderMethod = "getPCImmEncoding";
}

def pcimm64 : PCRelAddress<i64, "pcimm64"> {
  let EncoderMethod = "getPCImm64Encoding";
}

def pcrel32call : PCRelAddress<i32, "pcrel32call"> {
  let PrintMethod = "printCallOperand";
  let EncoderMethod = "getCallEncoding";
}

def pcrel64call : PCRelAddressNoWrap<i64, "pcrel64call"> {
  let PrintMethod = "printCallOperand";
  let EncoderMethod = "getCallEncoding";
}

//===----------------------------------------------------------------------===//
// Addressing modes
//===----------------------------------------------------------------------===//

// 12-bit displacement operands.
def disp12imm32 : Operand<i32>;
def disp12imm64 : Operand<i64>;

// 20-bit displacement operands.
def disp20imm32 : Operand<i32>;
def disp20imm64 : Operand<i64>;


//===----------------------------------------------------------------------===//
//RI5CY Extension
//===----------------------------------------------------------------------===//
def U5Imm  : ImmediateAsmOperand<"U5Imm">;
def uimm5 : Immediate<i32, [{
  return isUInt<5>(N->getSExtValue());
}], NOOP_SDNodeXForm, "U5Imm">;

def Uimm32contig0  : ImmediateAsmOperand<"Uimm32contig0">;
def imm32contig0 : Immediate<i32, [{
  if(isUInt<12>(N->getSExtValue()))
    return false;

  if(isInt<32>(N->getSExtValue())) {
      return RI5CY_bitIntervalExtraction(N->getSExtValue());
  }
  return false;
}], NOOP_SDNodeXForm, "Uimm32contig0">;

def Uimm32contig1  : ImmediateAsmOperand<"Uimm32contig1">;
def imm32contig1 : Immediate<i32, [{
  if(isUInt<12>(N->getSExtValue()))
    return false;

  if(isInt<32>(N->getSExtValue())) {
      return RI5CY_bitIntervalExtraction(N->getSExtValue(), NULL, NULL, true);
  }
  return false;
}], NOOP_SDNodeXForm, "Uimm32contig1">;

def Uimm32contig1End  : ImmediateAsmOperand<"Uimm32contig1End">;
def imm32contig1end : Immediate<i32, [{
  if(isInt<32>(N->getSExtValue())) {
      unsigned int end;
      RI5CY_bitIntervalExtraction(N->getSExtValue(), NULL, &end, true);
      if (end == 0) { 
        return true;
      }
  }
  return false;
}], NOOP_SDNodeXForm, "Uimm32contig1">;
