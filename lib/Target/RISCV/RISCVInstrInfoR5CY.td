//==- RISCVInstrR5CY.td - Multiply Divide RISCV instructions --*- tblgen-*-==//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

//RI5CY
def MUL5CY   : InstR<"mul"  , 0b0110011, 0b0000001000, mul   , GR32, GR32>, Requires<[IsR5CY]>;

//
//
//         BIT MANIPULATION
//
//

def PCNT     : InstP1C<"p.cnt", 0b0110011,0b0001000,0b011,
               [(set GR32:$dst, (ctpop GR32:$src1))],GR32>, Requires<[IsR5CY]>;

def PCLB1    : InstP1C<"p.clb", 0b0110011,0b0001000,0b010,
               [(set GR32:$dst, (ctlz GR32:$src1))],GR32>, Requires<[IsR5CY]>;

def PCLB2    : InstP1C<"p.clb", 0b0110011,0b0001000,0b010,
               [(set GR32:$dst, (not (ctlz GR32:$src1)))],GR32>, Requires<[IsR5CY]>;

//
//
//          GENERAL ALU OPERATION (1)
//
//

def PABS     : InstP1C<"p.abs",
                     0b0110011,
                     0b0000010,
                     0b000,
                     [(set (i32 GR32:$dst),
                        (i32(select (
                          i32(setlt GR32:$src1, (i32 0)) 
                        ),
                        (i32(sub (i32 0), GR32:$src1)),
                        (i32 GR32:$src1)
                        ))
                      )],
                     GR32
					>, Requires<[IsR5CY]>;

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

def PADDRN    : InstP2IC<"p.addRN",
                     0b1011011,
                     0b00,
                     0b110,
                     [(set GR32:$dst, 
                        (sra 
                          (add 
                            (add GR32:$src1, GR32:$src2), 
                            (srl (i32 1), (sub uimm5:$src3, (i32 1))) 
                          ),
                          uimm5:$src3
                        )
                      ) ],
                     GR32,
                     GR32,
                     uimm5
					>, Requires<[IsR5CY]>;

def PADDURN    : InstP2IC<"p.adduRN",
                     0b1011011,
                     0b10,
                     0b110,
                     [(set GR32:$dst, 
                        (srl 
                          (add 
                            (add GR32:$src1, GR32:$src2), 
                            (srl (i32 1), (sub uimm5:$src3, (i32 1))) 
                          ),
                          uimm5:$src3
                        )
                      ) ],
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

def PSUBRN    : InstP2IC<"p.subRN",
                     0b1011011,
                     0b00,
                     0b111,
                     [(set GR32:$dst, 
                        (sra
                          (add 
                            (sub GR32:$src1, GR32:$src2), 
                            (srl (i32 1), (sub uimm5:$src3, (i32 1))) 
                          ),
                          uimm5:$src3
                        )
                      ) ],
                     GR32,
                     GR32,
                     uimm5
					>, Requires<[IsR5CY]>;

def PSUBURN    : InstP2IC<"p.subuRN",
                     0b1011011,
                     0b00,
                     0b111,
                     [(set GR32:$dst, 
                        (srl 
                          (add 
                            (sub GR32:$src1, GR32:$src2), 
                            (srl (i32 1), (sub uimm5:$src3, (i32 1))) 
                          ),
                          uimm5:$src3
                        )
                      ) ],
                     GR32,
                     GR32,
                     uimm5
					>, Requires<[IsR5CY]>;
