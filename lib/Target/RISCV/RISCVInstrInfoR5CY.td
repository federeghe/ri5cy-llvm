//==- RISCVInstrR5CY.td - Multiply Divide RISCV instructions --*- tblgen-*-==//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//


//
//
//         BIT MANIPULATION
//
//
 
/*def PBCLR    : Pseudo<(outs GR32:$dst),(ins GR32:$src, imm32:$imm),


"p.bclr",0b0110011,0b11,0b011,
                [(set GR32:$dst, (and GR32:$src1, imm32:$imm1
                          uimm32:$imm2 ) )) ]
              ,GR32,uimm32,uimm32>, Requires<[IsR5CY]>;

*/


let usesCustomInserter = 1 in {
  def PEXTRACT_PSEUDO : Pseudo<(outs GR32:$dst), (ins GR32:$src1, uimm5:$imm2, uimm5:$imm3),
                           [(set GR32:$dst, (shl (srl GR32:$src1, uimm5:$imm2), uimm5:$imm3 ))]>,
                           Requires<[IsR5CY]>;
  def PEXTRACT_PSEUDO_REV : Pseudo<(outs GR32:$dst), (ins GR32:$src1, uimm5:$imm2, uimm5:$imm3),
                           [(set GR32:$dst, (srl (shl GR32:$src1, uimm5:$imm3), uimm5:$imm2 ))]>,
                           Requires<[IsR5CY]>;

  def PEXTRACTU_PSEUDO : Pseudo<(outs GR32:$dst), (ins GR32:$src1, uimm5:$imm2, uimm5:$imm3),
                           [(set GR32:$dst, (shl (sra GR32:$src1, uimm5:$imm2), uimm5:$imm3 ))]>,
                           Requires<[IsR5CY]>;
  def PEXTRACTU_PSEUDO_REV : Pseudo<(outs GR32:$dst), (ins GR32:$src1, uimm5:$imm2, uimm5:$imm3),
                           [(set GR32:$dst, (sra (shl GR32:$src1, uimm5:$imm3), uimm5:$imm2 ))]>,
                           Requires<[IsR5CY]>;


  def PINSERT_PSEUDO : Pseudo_with_cstr<(outs GR32:$dst), (ins GR32:$rd, GR32:$src1, imm32contig0:$src2),
                           [(set GR32:$dst, (or GR32:$rd, (and GR32:$src1, imm32contig1:$src2)))],"$rd = $dst">,
                           Requires<[IsR5CY]>;

  def PBCLR_PSEUDO : Pseudo<(outs GR32:$dst), (ins GR32:$src1, imm32contig0:$src2),
                           [(set GR32:$dst, (and GR32:$src1, imm32contig0:$src2))]>,
                           Requires<[IsR5CY]>;

  def PBSET_PSEUDO : Pseudo<(outs GR32:$dst), (ins GR32:$src1, imm32contig1:$src2),
                           [(set GR32:$dst, (or GR32:$src1, imm32contig1:$src2))]>,
                           Requires<[IsR5CY]>;
}

def PEXTRACT: InstP1I2C<"p.extract", 0b0110011, 0b11, 0b000,
                       [], 
                        GR32, uimm5, uimm5>, Requires<[IsR5CY]>;

def PEXTRACTU: InstP1I2C<"p.extractu", 0b0110011, 0b11, 0b001,
                       [], 
                        GR32, uimm5, uimm5>, Requires<[IsR5CY]>;

def PINSERT  : InstP1I2C_DSTasSRC<"p.insert", 0b0110011, 0b11, 0b010, [], GR32, uimm5, uimm5>,
                           Requires<[IsR5CY]>;

def PBCLR: InstP1I2C<"p.bclr", 0b0110011, 0b11, 0b011, [], GR32, uimm5, uimm5>,
                           Requires<[IsR5CY]>;

def PBSET: InstP1I2C<"p.bset", 0b0110011, 0b11, 0b100, [], GR32, uimm5, uimm5>,
                           Requires<[IsR5CY]>;

def PFF1    : InstP1C<"p.ff1", 0b0110011,0b0001000,0b000,
               [(set GR32:$dst, (cttz GR32:$src1))],GR32>, Requires<[IsR5CY]>;

def PFL1    : InstP1C<"p.fl1", 0b0110011,0b0001000,0b001,
               [(set GR32:$dst, (xor  (ctlz GR32:$src1), (i32 31) ))],GR32>, Requires<[IsR5CY]>;

def PCNT     : InstP1C<"p.cnt", 0b0110011,0b0001000,0b011,
               [(set GR32:$dst, (ctpop GR32:$src1))],GR32>, Requires<[IsR5CY]>;

def PCLB1    : InstP1C<"p.clb", 0b0110011,0b0001000,0b010,
               [(set GR32:$dst, (ctlz GR32:$src1))],GR32>, Requires<[IsR5CY]>;

def PCLB2    : InstP1C<"p.clb", 0b0110011,0b0001000,0b010,
               [(set GR32:$dst, (not (ctlz GR32:$src1)))],GR32>, Requires<[IsR5CY]>;

def PROR     : InstP2C<"p.ror", 0b0110011,0b0000100,0b101,
               [(set GR32:$dst, (rotr GR32:$src1, GR32:$src2))],GR32,GR32>,
               Requires<[IsR5CY]>;

//
//
//          GENERAL ALU OPERATION (1)
//
//

def PABS     : InstP1C<"p.abs",
                     0b0110011,
                     0b0000010,
                     0b000,
                     [],
                     GR32
					>, Requires<[IsR5CY]>;

def : Pat<(select (i32 (setlt GR32:$src1, (i32 0))), (sub (i32 0), GR32:$src1), GR32:$src1),
        (PABS GR32:$src1)>, Requires<[IsR5CY]>;

def : Pat<(select (i32 (setgt GR32:$src1, (i32 0))), GR32:$src1, (sub (i32 0), GR32:$src1)),
        (PABS GR32:$src1)>, Requires<[IsR5CY]>;

def : Pat<(select (i32 (setle GR32:$src1, (i32 0))), (sub (i32 0), GR32:$src1), GR32:$src1),
        (PABS GR32:$src1)>, Requires<[IsR5CY]>;

def : Pat<(select (i32 (setge GR32:$src1, (i32 0))), GR32:$src1, (sub (i32 0), GR32:$src1)),
        (PABS GR32:$src1)>, Requires<[IsR5CY]>;


def : Pat<(xor 
              ( add 
                     GR32:$src1, 
                      (sra 
                             GR32:$src1, 
                             (i32 31)
                          )
                    
               ), 
               (sra 
                     GR32:$src1, 
                     (i32 31)
              )),(PABS GR32:$src1)>, Requires<[IsR5CY]>;

def PSLET   : InstP2C<"p.slet", 0b0110011, 0b0000010, 0b010,
                     [(set GR32:$dst, (setle GR32:$src1,  GR32:$src2))],
                     GR32, GR32>, Requires<[IsR5CY]>;

def PSLETU  : InstP2C<"p.sletu", 0b0110011, 0b0000010, 0b011,
                     [(set GR32:$dst, (setule GR32:$src1,  GR32:$src2))],
                     GR32, GR32>, Requires<[IsR5CY]>;

multiclass SetgeDedicatePats<RegisterOperand RC, Instruction PSLETOp, Instruction PSLETuOp> {
  def : Pat<(setge RC:$lhs, RC:$rhs),
            (PSLETOp RC:$lhs, RC:$rhs)>;
  def : Pat<(setuge RC:$lhs, RC:$rhs),
            (PSLETuOp RC:$lhs, RC:$rhs)>;
}

defm : SetgeDedicatePats<GR32, PSLET, PSLETU>, Requires<[IsR5CY]>;


def PMIN      : InstP2C<"p.min",0b0110011,0b0000010,0b100,
                [],GR32, GR32>, Requires<[IsR5CY]>;

def : Pat<(select (i32 (setle GR32:$lhs, GR32:$rhs)), GR32:$lhs, GR32:$rhs),
        (PMIN GR32:$lhs, GR32:$rhs)>, Requires<[IsR5CY]>;
def : Pat<(select (i32 (setge GR32:$rhs, GR32:$lhs)), GR32:$lhs, GR32:$rhs),
        (PMIN GR32:$lhs, GR32:$rhs)>, Requires<[IsR5CY]>;
def : Pat<(select (i32 (setlt GR32:$lhs, GR32:$rhs)), GR32:$lhs, GR32:$rhs),
        (PMIN GR32:$lhs, GR32:$rhs)>, Requires<[IsR5CY]>;
def : Pat<(select (i32 (setgt GR32:$rhs, GR32:$lhs)), GR32:$lhs, GR32:$rhs),
        (PMIN GR32:$lhs, GR32:$rhs)>, Requires<[IsR5CY]>;

def PMINU     : InstP2C<"p.minu",0b0110011,0b0000010,0b101,
                [],GR32, GR32>, Requires<[IsR5CY]>;

def : Pat<(select (i32 (setule GR32:$lhs, GR32:$rhs)), GR32:$lhs, GR32:$rhs),
        (PMINU GR32:$lhs, GR32:$rhs)>, Requires<[IsR5CY]>;
def : Pat<(select (i32 (setuge GR32:$rhs, GR32:$lhs)), GR32:$lhs, GR32:$rhs),
        (PMINU GR32:$lhs, GR32:$rhs)>, Requires<[IsR5CY]>;
def : Pat<(select (i32 (setult GR32:$lhs, GR32:$rhs)), GR32:$lhs, GR32:$rhs),
        (PMINU GR32:$lhs, GR32:$rhs)>, Requires<[IsR5CY]>;
def : Pat<(select (i32 (setugt GR32:$rhs, GR32:$lhs)), GR32:$lhs, GR32:$rhs),
        (PMINU GR32:$lhs, GR32:$rhs)>, Requires<[IsR5CY]>;

def PMAX      : InstP2C<"p.max",0b0110011,0b0000010,0b110,
                [],GR32, GR32>, Requires<[IsR5CY]>;

def : Pat<(select (i32 (setge GR32:$lhs, GR32:$rhs)), GR32:$lhs, GR32:$rhs),
        (PMAX GR32:$lhs, GR32:$rhs)>, Requires<[IsR5CY]>;
def : Pat<(select (i32 (setle GR32:$rhs, GR32:$lhs)), GR32:$lhs, GR32:$rhs),
        (PMAX GR32:$lhs, GR32:$rhs)>, Requires<[IsR5CY]>;
def : Pat<(select (i32 (setgt GR32:$lhs, GR32:$rhs)), GR32:$lhs, GR32:$rhs),
        (PMAX GR32:$lhs, GR32:$rhs)>, Requires<[IsR5CY]>;
def : Pat<(select (i32 (setlt GR32:$rhs, GR32:$lhs)), GR32:$lhs, GR32:$rhs),
        (PMAX GR32:$lhs, GR32:$rhs)>, Requires<[IsR5CY]>;

def PMAXU     : InstP2C<"p.maxu",0b0110011,0b0000010,0b111,
                [],GR32, GR32>, Requires<[IsR5CY]>;

def : Pat<(select (i32 (setuge GR32:$lhs, GR32:$rhs)), GR32:$lhs, GR32:$rhs),
        (PMAXU GR32:$lhs, GR32:$rhs)>, Requires<[IsR5CY]>;
def : Pat<(select (i32 (setule GR32:$rhs, GR32:$lhs)), GR32:$lhs, GR32:$rhs),
        (PMAXU GR32:$lhs, GR32:$rhs)>, Requires<[IsR5CY]>;
def : Pat<(select (i32 (setugt GR32:$lhs, GR32:$rhs)), GR32:$lhs, GR32:$rhs),
        (PMAXU GR32:$lhs, GR32:$rhs)>, Requires<[IsR5CY]>;
def : Pat<(select (i32 (setult GR32:$rhs, GR32:$lhs)), GR32:$lhs, GR32:$rhs),
        (PMAXU GR32:$lhs, GR32:$rhs)>, Requires<[IsR5CY]>;


def PEXTHS    : InstP1C<"p.exths",0b0110011,0b0001000,0b100,
                [(set GR32:$dst,(sext16 GR32:$src1))],GR32>, Requires<[IsR5CY]>;

def PEXTHZ    : InstP1C<"p.exthz",0b0110011,0b0001000,0b101,
                [(set GR32:$dst,(zext16 GR32:$src1))],GR32>, Requires<[IsR5CY]>;

def PEXTBZ    : InstP1C<"p.extbz",0b0110011,0b0001000,0b111,
                [(set GR32:$dst,(zext8  GR32:$src1))],GR32>, Requires<[IsR5CY]>;

def PEXTBS    : InstP1C<"p.extbs",0b0110011,0b0001000,0b110,
                [(set GR32:$dst,(sext8  GR32:$src1))],GR32>, Requires<[IsR5CY]>;

//
//
//          GENERAL ALU OPERATION (1)
//              P.CLIP(U) special instructions
//
//

def PCLIP_P   : ComplexPattern<i32, 2, "SelectPCLIP", [select], []>;
def PCLIPU_P  : ComplexPattern<i32, 2, "SelectPCLIPU", [select], []>;

// We need a custom instruction for pclip and pclipu
def PCLIP     : InstRISCV<4, (outs GR32:$dst), (ins GR32:$src1, uimm5:$imm2), 
                "p.clip\t$dst, $src1, $imm2", []> {
  field bits<32> Inst;

  bits<5> RD;
  bits<5> RS1;
  bits<5> IMM;

  let Inst{31-25} = 0b0001010;
  let Inst{24-20} = IMM;
  let Inst{19-15} = RS1;
  let Inst{14-12} = 0b001;
  let Inst{11-7} = RD;
  let Inst{6 - 0} = 0b0110011;
}

def PCLIPU    : InstRISCV<4, (outs GR32:$dst), (ins GR32:$src1, uimm5:$imm2), 
                "p.clipu\t$dst, $src1, $imm2", []> {
  field bits<32> Inst;

  bits<5> RD;
  bits<5> RS1;
  bits<5> IMM;

  let Inst{31-25} = 0b0001010;
  let Inst{24-20} = IMM;
  let Inst{19-15} = RS1;
  let Inst{14-12} = 0b010;
  let Inst{11-7} = RD;
  let Inst{6 - 0} = 0b0110011;
}

def : Pat<(PCLIP_P GR32:$src, uimm5:$imm1),
          (PCLIP GR32:$src, uimm5:$imm1)>, Requires<[IsR5CY]>;
def : Pat<(PCLIPU_P GR32:$src, uimm5:$imm1),
          (PCLIPU GR32:$src, uimm5:$imm1)>, Requires<[IsR5CY]>;

 
//
//
//          GENERAL ALU OPERATION (2)
//
//
def PADDN     : InstP2<"p.addN",
                     0b1011011,
                     0b00,
                     0b010,
                     add,
                     sra,
                     GR32,
                     GR32,
                     uimm5
					>, Requires<[IsR5CY]>;

def PADDUN    : InstP2<"p.adduN",
                     0b1011011,
                     0b10,
                     0b010,
                     add,
                     srl,
                     GR32,
                     GR32,
                     uimm5
					>, Requires<[IsR5CY]>;


def PSUBN     : InstP2<"p.subN",
                     0b1011011,
                     0b00,
                     0b011,
                     sub,
                     sra,
                     GR32,
                     GR32,
                     uimm5
					>, Requires<[IsR5CY]>;

def PSUBUN    : InstP2<"p.subuN",
                     0b1011011,
                     0b10,
                     0b011,
                     sub,
                     srl,
                     GR32,
                     GR32,
                     uimm5
					>, Requires<[IsR5CY]>;

//
//
//          GENERAL ALU OPERATION (2) - R Version
//
//


let usesCustomInserter = 1 in {
  def PADDRN_PSEUDO : Pseudo<(outs GR32:$dst), (ins GR32:$src1, GR32:$src2, imm32:$imm1, uimm5:$imm2),
                           [(set GR32:$dst, 
                        (sra 
                          (add 
                            (add GR32:$src1, GR32:$src2), 
                            imm32:$imm1 
                          ),
                          uimm5:$imm2
                        )
                      ) ]>,
                           Requires<[IsR5CY]>;
  def PADDURN_PSEUDO : Pseudo<(outs GR32:$dst), (ins GR32:$src1, GR32:$src2, imm32:$imm1, uimm5:$imm2),
                           [(set GR32:$dst, 
                        (srl 
                          (add 
                            (add GR32:$src1, GR32:$src2), 
                            imm32:$imm1 
                          ),
                          uimm5:$imm2
                        )
                      ) ]>,
                           Requires<[IsR5CY]>;
  def PSUBRN_PSEUDO : Pseudo<(outs GR32:$dst), (ins GR32:$src1, GR32:$src2, imm32:$imm1, uimm5:$imm2),
                           [(set GR32:$dst, 
                        (sra 
                          (add 
                            (sub GR32:$src1, GR32:$src2), 
                            imm32:$imm1 
                          ),
                          uimm5:$imm2
                        )
                      ) ]>,
                           Requires<[IsR5CY]>;
  def PSUBURN_PSEUDO : Pseudo<(outs GR32:$dst), (ins GR32:$src1, GR32:$src2, imm32:$imm1, uimm5:$imm2),
                           [(set GR32:$dst, 
                        (srl 
                          (add 
                            (sub GR32:$src1, GR32:$src2), 
                            imm32:$imm1 
                          ),
                          uimm5:$imm2
                        )
                      ) ]>,
                           Requires<[IsR5CY]>;
}

def PADDRN    : InstP2IC<"p.addRN",0b1011011,0b00,0b110,[],GR32,GR32,uimm5>, Requires<[IsR5CY]>;
def PADDURN   : InstP2IC<"p.adduRN",0b1011011,0b10,0b110,[],GR32,GR32,uimm5>, Requires<[IsR5CY]>;
def PSUBRN    : InstP2IC<"p.subRN",0b1011011,0b00,0b111,[],GR32,GR32,uimm5>, Requires<[IsR5CY]>;
def PSUBURN   : InstP2IC<"p.subuRN",0b1011011,0b10,0b111,[],GR32,GR32,uimm5>, Requires<[IsR5CY]>;

