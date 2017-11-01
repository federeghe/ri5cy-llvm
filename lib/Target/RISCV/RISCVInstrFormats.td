//===- RISCVInstrFormats.td - RISCV Instruction Formats ----*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Basic RISCV instruction definition
//===----------------------------------------------------------------------===//

class InstRISCV<int size, dag outs, dag ins, string asmstr,
                  list<dag> pattern> : Instruction {
  let Namespace = "RISCV";

  dag OutOperandList = outs;
  dag InOperandList = ins;
  let Size = size;
  let Pattern = pattern;
  let AsmString = asmstr;

  let AddedComplexity = 1;


  // Used to identify a group of related instructions, such as ST and STY.
  string Function = "";

  // "12" for an instruction that has a ...Y equivalent, "20" for that
  // ...Y equivalent.
  string PairType = "none";

  // True if this instruction is a simple load of a register
  // (with no sign or zero extension).
  bit SimpleLoad = 0;

  // True if this instruction is a simple store of a register
  // (with no truncation).
  bit SimpleStore = 0;

  let TSFlags{0} = SimpleLoad;
  let TSFlags{1} = SimpleStore;
}

/***************
*RISCV Instruction Formats
*/

//R-Type
class InstR<string mnemonic, bits<7> op, bits<7> funct7, bits<3> funct3,
            SDPatternOperator operator, RegisterOperand cls1, 
            RegisterOperand cls2>
  : InstRISCV<4, (outs cls1:$dst), (ins cls2:$src1, cls2:$src2),
                mnemonic#"\t$dst, $src1, $src2", 
                [(set cls1:$dst, (operator cls2:$src1, cls2:$src2))]> {
  field bits<32> Inst;

  bits<5> RD;
  bits<5> RS1;
  bits<5> RS2;

  let Inst{31-25} = funct7;
  let Inst{24-20} = RS2;
  let Inst{19-15} = RS1;
  let Inst{14-12} = funct3;
  let Inst{11- 7} = RD;
  let Inst{6 - 0} = op;
}
//grep -rnw -e 'SDPatternOperator'

//LR/SC
class InstLR<string mnemonic, bits<3> funct3,
             RegisterOperand cls1, Operand cls2>
  : InstRISCV<4, (outs cls1:$dst), (ins cls2:$src2), 
                mnemonic#"\t$dst, $src2", 
                []> {
  field bits<32> Inst;

  bits<5> RD;
  bits<5> RS1;

  let Inst{31-27} = 0b00010;
  let Inst{26} = 0;//aq
  let Inst{25} = 0;//rl
  let Inst{24-20} = 0b00000;
  let Inst{19-15} = RS1;
  let Inst{14-12} = funct3;
  let Inst{11- 7} = RD;
  let Inst{6 - 0} = 0b0101111;
}

class InstSC<string mnemonic, bits<3> funct3,
             RegisterOperand reg, Operand memOp>
  : InstRISCV<4, (outs reg:$dst), (ins reg:$src2, memOp:$src1), 
                mnemonic#"\t$dst, $src2, $src1", 
                []> {
  field bits<32> Inst;

  bits<5> RD;
  bits<5> RS1;
  bits<5> RS2;

  let Inst{31-27} = 0b00011;
  let Inst{26} = 0;//aq
  let Inst{25} = 0;//rl
  let Inst{24-20} = RS2;
  let Inst{19-15} = RS1;
  let Inst{14-12} = funct3;
  let Inst{11- 7} = RD;
  let Inst{6 - 0} = 0b0101111;
}

//A-Type
class InstA<string mnemonic, bits<7> op, bits<5> funct5, bits<3> funct3,
            SDPatternOperator operator, RegisterOperand cls1, 
            Operand cls2>
  : InstRISCV<4, (outs cls1:$dst), (ins cls1:$src1, cls2:$src2), 
                mnemonic#"\t$dst, $src1, $src2", 
                [(set cls1:$dst, (operator regaddr:$src2, cls1:$src1))]> {
  field bits<32> Inst;

  bits<5> RD;
  bits<5> RS1;
  bits<5> RS2;

  let Inst{31-27} = funct5;
  let Inst{26} = 0;//aq
  let Inst{25} = 0;//rl
  let Inst{24-20} = RS2;
  let Inst{19-15} = RS1;
  let Inst{14-12} = funct3;
  let Inst{11- 7} = RD;
  let Inst{6 - 0} = op;
}

//Load-Type
class InstLoad<string mnemonic, bits<7> op, bits<3> funct3,
            SDPatternOperator opNode,
            RegisterOperand cls1,
            Operand memOp>
  : InstRISCV<4, (outs cls1:$dst), (ins memOp:$addr), 
                mnemonic#"\t$dst, $addr", 
                [(set cls1:$dst, (opNode addr:$addr))]> {
  field bits<32> Inst;

  bits<5> RD;
  bits<5> RS1;
  bits<12> IMM;

  let Inst{31-27} = RD;
  let Inst{26-22} = RS1;
  let Inst{21-17} = IMM{11-7};
  let Inst{16-10} = IMM{6 -0};
  let Inst{9 - 7} = funct3;
  let Inst{6 - 0} = op;
}

class InstStore<string mnemonic, bits<7> op, bits<3> funct3,
                SDPatternOperator opNode,
                RegisterOperand cls1,
                Operand memOp>
  : InstRISCV<4, (outs), (ins cls1:$src, memOp:$addr),
              mnemonic#"\t$src, $addr", 
              [(opNode cls1:$src, addr:$addr)]> {
  field bits<32> Inst;

  bits<5> RS2;
  bits<5> RS1;
  bits<12> IMM;

  let Inst{31-27} = IMM{11-7};
  let Inst{26-22} = RS1;
  let Inst{21-17} = RS2;
  let Inst{16-10} = IMM{6 -0};
  let Inst{9 - 7} = funct3;
  let Inst{6 - 0} = op;
}

//I-Type
class InstI<string mnemonic, bits<7> op, bits<3> funct3,
            SDPatternOperator operator, RegisterOperand cls1, RegisterOperand cls2,
            Immediate imm>
  : InstRISCV<4, (outs cls1:$dst), (ins cls2:$src1, imm:$src2), 
                mnemonic#"\t$dst, $src1, $src2", 
                [(set cls1:$dst, (operator cls2:$src1, imm:$src2))]> {
  field bits<32> Inst;

  bits<5> RD;
  bits<5> RS1;
  bits<12> IMM;

  let Inst{31-20} = IMM;
  let Inst{19-15} = RS1;
  let Inst{14-12} = funct3;
  let Inst{11- 7} = RD;
  let Inst{6 - 0} = op;
}

//ISYS-Type
class InstISYS<string mnemonic, bits<12> funct12,
             RegisterOperand cls1>
  : InstRISCV<4, (outs cls1:$dst), (ins), 
                mnemonic#"\t$dst", 
                []> {
  field bits<32> Inst;

  bits<5> RD;

  let Inst{31-20} = funct12;
  let Inst{19-15} = 0b00000;
  let Inst{14-12} = 0b010;
  let Inst{11- 7} = RD;
  let Inst{6 - 0} = 0b1110011;
}

//B-Type, too different to consolidate further
class InstB<bits<7> op, bits<3> funct3, dag outs, dag ins, string asmstr, list<dag> pattern>
  : InstRISCV<4, outs, ins, asmstr, pattern> {
  field bits<32> Inst;

  bits<12> IMM;
  bits<5> RS1;
  bits<5> RS2;

  let Inst{31-27} = IMM{11-7};
  let Inst{26-22} = RS1;
  let Inst{21-17} = RS2;
  let Inst{16-10} = IMM{6 -0};
  let Inst{9 - 7} = funct3;
  let Inst{6 - 0} = op;
}

//U-Type, only two instructions fit here so no further condensation
class InstU<bits<7> op, dag outs, dag ins, string asmstr, list<dag> pattern>
  : InstRISCV<4, outs, ins, asmstr, pattern> {
  field bits<32> Inst;

  bits<5> RD;
  bits<20> IMM;

  let Inst{31-12} = IMM{19-0};
  let Inst{11- 7} = RD;
  let Inst{6 - 0} = op;
}

//J-Type, only 2 instructions no further consolidation
class InstJ<bits<7> op, dag outs, dag ins, string asmstr, list<dag> pattern>
  : InstRISCV<4, outs, ins, asmstr, pattern> {
  field bits<32> Inst;

  bits<25> IMM;

  let Inst{31- 7} = IMM{24-0};
  let Inst{6 - 0} = op;
}

//MAC-Type
/*
class InstMAC<string mnemonic, bits<7> op, bits<3> funct3, bits<2> f2,
            RegisterOperand cls1, 
            RegisterOperand cls2, Immediate imm, string asmstr,
                  list<dag> pattern>
  : InstRISCV<4, (outs cls1:$dst), (ins cls2:$src1, cls2:$src2, imm:$ls3),
                asmstr, pattern> {
  field bits<32> Inst;
  bits<5> RD;
  bits<5> RS1;
  bits<5> RS2;
  bits<5> LS3;

  let Inst{31-30} = f2;
  let Inst{29-25} = LS3;
  let Inst{24-20} = RS2;
  let Inst{19-15} = RS1;
  let Inst{14- 12} = funct3;
  let Inst{11- 7} = RD;
  let Inst{6 - 0} = op;
}
*/
//p.mac p.msu
class InstMAC2<string mnemonic, bits<7> op, bits<7> funct7, bits<3> funct3,
            SDPatternOperator operator, SDPatternOperator operator2, RegisterOperand cls1, 
            RegisterOperand cls2, RegisterOperand cls3>
  : InstRISCV<4, (outs cls1:$dst), (ins cls2:$src1, cls3:$src2, cls3:$rd),
                mnemonic#"\t$dst, $src1, $src2", 
                [(set cls1:$dst, (operator (operator2 cls2:$src1, cls3:$src2), cls1:$rd))]> {
  field bits<32> Inst;

  let Constraints = "$rd = $dst";
  bits<5> RD;
  bits<5> RS1;
  bits<5> RS2;

  let Inst{31-25} = funct7;
  let Inst{24-20} = RS2;
  let Inst{19-15} = RS1;
  let Inst{14-12} = funct3;
  let Inst{11- 7} = RD;
  let Inst{6 - 0} = op;
}


//p.mulhhs p.mulhhu
class InstMACHB<string mnemonic, bits<7> op, bits<2> funct2, bits<3> funct3, 
            SDPatternOperator operator, SDPatternOperator operator2,  RegisterOperand cls1>
  : InstRISCV<4, (outs cls1:$dst), (ins cls1:$src1, cls1:$src2),
                mnemonic#"\t$dst, $src1, $src2", 
                [(set cls1:$dst, (operator (operator2 cls1:$src1, (i32 16)), (operator2 cls1:$src2, (i32 16))))]> {
  field bits<32> Inst;
  bits<5> RD;
  bits<5> RS1;
  bits<5> RS2;
  bits<5> IMM;

  let Inst{31-30} = funct2;
  let Inst{29-25} = 0b00000;
  let Inst{24-20} = RS2;
  let Inst{19-15} = RS1;
  let Inst{14-12} = funct3;
  let Inst{11- 7} = RD;
  let Inst{6 - 0} = op;
}

//p.muls p.mulu
class InstMACLB<string mnemonic, bits<7> op, bits<2> funct2, bits<3> funct3, 
            SDPatternOperator operator, SDPatternOperator operator2, 
	    RegisterOperand cls1>
  : InstRISCV<4, (outs cls1:$dst), (ins cls1:$src1, cls1:$src2),
                mnemonic#"\t$dst, $src1, $src2", 
                [(set cls1:$dst, (operator (operator2 cls1:$src1), (operator2 cls1:$src2)))]> {
  field bits<32> Inst;

  bits<5> RD;
  bits<5> RS1;
  bits<5> RS2;
  bits<5> IMM;

  let Inst{31-30} = funct2;
  let Inst{29-25} = 0b00000;
  let Inst{24-20} = RS2;
  let Inst{19-15} = RS1;
  let Inst{14-12} = funct3;
  let Inst{11- 7} = RD;
  let Inst{6 - 0} = op;
}

//p.mulsn p.mulun
class InstMACLBS<string mnemonic, bits<7> op, bits<2> funct2, bits<3> funct3,
            SDPatternOperator operator, SDPatternOperator operator2, SDPatternOperator operator3, 
	    RegisterOperand cls1, RegisterOperand cls2, RegisterOperand cls3, Immediate imm1>
  : InstRISCV<4, (outs cls1:$dst), (ins cls2:$src1, cls3:$src2, imm1:$imm1),
                mnemonic#"\t$dst, $src1, $src2", 
                [(set cls1:$dst, (operator (operator2 (operator3 cls2:$src1), (operator3 cls3:$src2)), imm1:$imm1))]> {
  field bits<32> Inst;

  bits<5> RD;
  bits<5> RS1;
  bits<5> RS2;
  bits<5> IMM;

  let Inst{31-30} = funct2;
  let Inst{29-25} = IMM;
  let Inst{24-20} = RS2;
  let Inst{19-15} = RS1;
  let Inst{14-12} = funct3;
  let Inst{11- 7} = RD;
  let Inst{6 - 0} = op;
}

//p.mulhhsn p.mulhhun
class InstMACHBS<string mnemonic, bits<7> op, bits<2> funct2, bits<3> funct3,
            SDPatternOperator operator, SDPatternOperator operator2, SDPatternOperator operator3, 
RegisterOperand cls1, RegisterOperand cls2, RegisterOperand cls3, Immediate imm1>
  : InstRISCV<4, (outs cls1:$dst), (ins cls2:$src1, cls2:$src2, imm1:$imm1),
                mnemonic#"\t$dst, $src1, $src2", 
                [(set cls1:$dst, (operator (operator2 (operator3 cls2:$src1, (i32 16)), (operator3 cls3:$src2, (i32 16))), imm1:$imm1))]> {
  field bits<32> Inst;

  bits<5> RD;
  bits<5> RS1;
  bits<5> RS2;
  bits<5> IMM;

  let Inst{31-30} = funct2;
  let Inst{29-25} = IMM;
  let Inst{24-20} = RS2;
  let Inst{19-15} = RS1;
  let Inst{14-12} = funct3;
  let Inst{11- 7} = RD;
  let Inst{6 - 0} = op;
}

//p.macsn p.macun
class InstMACLBSA<string mnemonic, bits<7> op, bits<2> funct2, bits<3> funct3,
            SDPatternOperator operator, SDPatternOperator operator2, SDPatternOperator operator3, SDPatternOperator operator4,
	    RegisterOperand cls1, RegisterOperand cls2, RegisterOperand cls3, Immediate imm1>
  : InstRISCV<4, (outs cls1:$dst), (ins cls2:$src1, cls3:$src2, cls1:$rd, imm1:$imm1),
                mnemonic#"\t$dst, $src1, $src2", 
                [(set cls1:$dst, (operator (operator2 (operator3 (operator4 cls2:$src1), (operator4 cls2:$src2)), cls1:$rd), imm1:$imm1))]> {
  field bits<32> Inst;
  let Constraints = "$rd = $dst";
  bits<5> RD;
  bits<5> RS1;
  bits<5> RS2;
  bits<5> IMM;

  let Inst{31-30} = funct2;
  let Inst{29-25} = IMM;
  let Inst{24-20} = RS2;
  let Inst{19-15} = RS1;
  let Inst{14-12} = funct3;
  let Inst{11- 7} = RD;
  let Inst{6 - 0} = op;
}

//p.machhsn p.machhun
class InstMACHBSA<string mnemonic, bits<7> op, bits<2> funct2, bits<3> funct3,
            SDPatternOperator operator, SDPatternOperator operator2, SDPatternOperator operator3, SDPatternOperator operator4, 		    		    
 RegisterOperand cls1, RegisterOperand cls2, RegisterOperand cls3, Immediate imm1>
  : InstRISCV<4, (outs cls1:$dst), (ins cls2:$src1, cls3:$src2, cls1:$rd, imm1:$imm1),
                mnemonic#"\t$dst, $src1, $src2", 
                [(set cls1:$dst, (operator (operator2 (operator3 (operator4 cls2:$src1, (i32 16)), (operator4 cls3:$src2, (i32 16))), cls1:$rd), imm1:$imm1))]> {
  field bits<32> Inst;

  let Constraints = "$rd = $dst";
  bits<5> RD;
  bits<5> RS1;
  bits<5> RS2;
  bits<5> IMM;

  let Inst{31-30} = funct2;
  let Inst{29-25} = IMM;
  let Inst{24-20} = RS2;
  let Inst{19-15} = RS1;
  let Inst{14-12} = funct3;
  let Inst{11- 7} = RD;
  let Inst{6 - 0} = op;
}


//===----------------------------------------------------------------------===//
// Pseudo instructions
//===----------------------------------------------------------------------===//
//
// Convenience instructions that get lowered to real instructions
// by either RISCVTargetLowering::EmitInstrWithCustomInserter()
// or RISCVInstrInfo::expandPostRAPseudo().
//
//===----------------------------------------------------------------------===//

class Pseudo<dag outs, dag ins, list<dag> pattern>
  : InstRISCV<0, outs, ins, "", pattern> {
  let isPseudo = 1;
  let isCodeGenOnly = 1;
}
// P-Type 2Reg + 1 Imm (custom)
class InstP2IC<string mnemonic, bits<7> opcode, bits<2> f2, bits<3> funct3,
            list<dag> pattern,
            RegisterOperand cls1, RegisterOperand cls2, Immediate imm>
  : InstRISCV<4, (outs cls1:$dst), (ins cls1:$src1, cls2:$src2, imm:$src3), 
                mnemonic#"\t$dst, $src1, $src2, $src3", pattern> {
  field bits<32> Inst;

  bits<5> RD;
  bits<5> RS1;
  bits<5> RS2;
  bits<5> IMM;

  let Inst{31-30} = f2;
  let Inst{29-25} = IMM;
  let Inst{24-20} = RS2;
  let Inst{19-15} = RS1;
  let Inst{14-12} = funct3;
  let Inst{11-7} = RD;
  let Inst{6 - 0} = opcode;
}

// P-Type 1 Reg (custom)
class InstP1C<string mnemonic, bits<7> opcode, bits<7> funct7, bits<3> funct3,
            list<dag> pattern,
            RegisterOperand cls1>
  : InstRISCV<4, (outs cls1:$dst), (ins cls1:$src1), 
                mnemonic#"\t$dst, $src1", pattern> {
  field bits<32> Inst;

  bits<5> RD;
  bits<5> RS1;

  let Inst{31-25} = funct7;
  let Inst{24-20} = 0;
  let Inst{19-15} = RS1;
  let Inst{14-12} = funct3;
  let Inst{11-7} = RD;
  let Inst{6 - 0} = opcode;
}

//pmulsrn, pmulurn
class PMUL<SDPatternOperator operator, SDPatternOperator operator2, SDPatternOperator operator3, SDPatternOperator operator4,
 RegisterOperand cls1, ImmLeaf imm1, Immediate imm2>
  : Pseudo<(outs cls1:$dst), (ins cls1:$src1, cls1:$src2, imm1:$imm1, imm2:$imm2), 
                [(set cls1:$dst, (operator (operator2 (operator3 (operator4 cls1:$src1), (operator4 cls1:$src2)), imm1:$imm1), imm2:$imm2))]> {

}

//pmulhhsrn, pmulhhurn
class PMULH<SDPatternOperator operator, SDPatternOperator operator2, SDPatternOperator operator3, SDPatternOperator operator4, 
 RegisterOperand cls1, ImmLeaf imm1, Immediate imm2>
  : Pseudo<(outs cls1:$dst), (ins cls1:$src1, cls1:$src2, imm1:$imm1, imm2:$imm2),
                [(set cls1:$dst, (operator (operator2 (operator3 (operator4 cls1:$src1, (i32 16)), (operator4 cls1:$src2, (i32 16))), imm1:$imm1), imm2:$imm2))]> {

}

//pmacsRN, pmacurn
class PMACL<SDPatternOperator operator, SDPatternOperator operator2, SDPatternOperator operator3, SDPatternOperator operator4, SDPatternOperator operator5,
 RegisterOperand cls1, ImmLeaf imm1, Immediate imm2>
  : Pseudo<(outs cls1:$dst), (ins cls1:$src1, cls1:$src2, imm1:$imm1, imm2:$imm2, cls1:$rd),
                [(set cls1:$dst, (operator (operator2 (operator3 (operator4 (operator5 cls1:$src1), (operator5 cls1:$src2)), cls1:$rd), imm1:$imm1), imm2:$imm2))]> {
let Constraints = "$rd = $dst";

}

//pmachhsrn, pmachhurn
class PMACH<SDPatternOperator operator, SDPatternOperator operator2, SDPatternOperator operator3, SDPatternOperator operator4, SDPatternOperator operator5, 
 RegisterOperand cls1, ImmLeaf imm1, Immediate imm2>
  : Pseudo<(outs cls1:$dst), (ins cls1:$src1, cls1:$src2, imm1:$imm1, imm2:$imm2, cls1:$rd), 
                [(set cls1:$dst, (operator (operator2 (operator3 (operator4 (operator5 cls1:$src1, (i32 16)), (operator5 cls1:$src2, (i32 16))), cls1:$rd), imm1:$imm1), imm2:$imm2))]> {
let Constraints = "$rd = $dst";

}

//grep -Ril "InstP2IC"

