//===- RISCVInstrInfoR5CY.td - RI5CY RISCV extension (Pulpino) --*- tblgen-*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//



def PEXTHS    : InstP1C<"p.exths",0b0110011,0b0001000,0b100,
                [(set GR32:$dst,(sext16 GR32:$src1))],GR32>, Requires<[IsR5CY]>;

def PEXTHZ    : InstP1C<"p.exthz",0b0110011,0b0001000,0b101,
                [(set GR32:$dst,(zext16 GR32:$src1))],GR32>, Requires<[IsR5CY]>;

def PEXTBZ    : InstP1C<"p.extbz",0b0110011,0b0001000,0b111,
                [(set GR32:$dst,(zext8  GR32:$src1))],GR32>, Requires<[IsR5CY]>;

def PEXTBS    : InstP1C<"p.extbs",0b0110011,0b0001000,0b110,
[(set GR32:$dst,(sext8 GR32:$src1))],GR32>, Requires<[IsR5CY]>;



 
def PMAC : InstMAC2<"p.mac", 0b0110011, 0b0100001, 0b000,
            add, mul, GR32, GR32, GR32>;

 def PMSU : InstMAC2<"p.msu", 0b0110011, 0b0100001, 0b001,
            sub, mul, GR32, GR32, GR32>;

  def PMULS : InstMACLB<"p.muls", 0b1011011, 0b10, 0b000, 
            mul, sext16, GR32>;

  def PMULHHS : InstMACHB<"p.mulhhs", 0b1011011, 0b11, 0b000, 
            mul, sra, GR32>;

  def PMULSN : InstMACLBS<"p.mulsn", 0b1011011, 0b10, 0b000,
            sra, mul, sext16, GR32, GR32, GR32, uimm5>;

  def PMULHHSN : InstMACHBS<"p.mulhhsn", 0b1011011, 0b11, 0b000,
            sra, mul, sra, GR32, GR32, GR32, uimm5>;

  def PMULU : InstMACLB<"p.mulu", 0b1011011, 0b00, 0b000, 
            mul, zext16, GR32>;

  def PMULHHU : InstMACHB<"p.mulhhu", 0b1011011, 0b01, 0b000, 
           mul, srl, GR32>;

  def PMULUN : InstMACLBS<"p.mulun", 0b1011011, 0b00, 0b000,
            srl, mul, zext16, GR32, GR32, GR32, uimm5>;

  def PMULHHUN : InstMACHBS<"p.mulhhun", 0b1011011, 0b01, 0b000,
            srl, mul, srl, GR32, GR32, GR32, uimm5>;

  def PMACSN : InstMACLBSA<"p.macsn", 0b1011011, 0b10, 0b001,
            sra, add, mul, sext16, GR32, GR32, GR32, uimm5>;
  def PMACHHSN : InstMACHBSA<"p.machhsn", 0b1011011, 0b11, 0b001,
           sra, add, mul, sra, GR32, GR32, GR32, uimm5>;
  def PMACUN : InstMACLBSA<"p.macun", 0b1011011, 0b00, 0b001,
            srl, add, mul, zext16,  GR32, GR32, GR32, uimm5>;
  def PMACHHUN : InstMACHBSA<"p.machhun", 0b1011011, 0b01, 0b001,
            srl, add, mul, srl,  GR32, GR32, GR32, uimm5>;

let usesCustomInserter = 1 in {
def PMULSRN_PSEUDO : PMUL<sra, add, mul, sext16, GR32, imm32, uimm5>, Requires<[IsR5CY]>;

def PMULHHSRN_PSEUDO : PMULH<sra, add, mul, sra, GR32, imm32, uimm5>, Requires<[IsR5CY]>;

def PMULURN_PSEUDO : PMUL<srl, add, mul, zext16, GR32, imm32, uimm5>, Requires<[IsR5CY]>;

def PMULHHURN_PSEUDO : PMULH<srl, add, mul, srl, GR32, imm32, uimm5>, Requires<[IsR5CY]>;


def PMACSRN_PSEUDO : PMACL<sra, add, add, mul, sext16, GR32, imm32, uimm5>, Requires<[IsR5CY]>;

def PMACHHSRN_PSEUDO : PMACH<sra, add, add, mul, sra, GR32, imm32, uimm5>, Requires<[IsR5CY]>;

def PMACURN_PSEUDO : PMACL<srl, add, add, mul, zext16, GR32, imm32, uimm5>, Requires<[IsR5CY]>;

def PMACHHURN_PSEUDO : PMACH<srl, add, add, mul, srl, GR32, imm32, uimm5>, Requires<[IsR5CY]>;

}


def PMULSRN : InstP2IC<"p.mulsrn",0b1011011,0b10,0b110,[],GR32,GR32,uimm5>, Requires<[IsR5CY]>;
def PMULHHSRN : InstP2IC<"p.mulhhsrn",0b1011011,0b10,0b110,[],GR32,GR32,uimm5>, Requires<[IsR5CY]>;
def PMULURN : InstP2IC<"p.mulurn",0b1011011,0b10,0b110,[],GR32,GR32,uimm5>, Requires<[IsR5CY]>;
def PMULHHURN : InstP2IC<"p.mulhhurn",0b1011011,0b10,0b110,[],GR32,GR32,uimm5>, Requires<[IsR5CY]>;
def PMACSRN : InstP2IC<"p.macsrn",0b1011011,0b10,0b110,[],GR32,GR32,uimm5>, Requires<[IsR5CY]>;
def PMACHHSRN : InstP2IC<"p.machhsrn",0b1011011,0b10,0b110,[],GR32,GR32,uimm5>, Requires<[IsR5CY]>;
def PMACURN : InstP2IC<"p.macurn",0b1011011,0b10,0b110,[],GR32,GR32,uimm5>, Requires<[IsR5CY]>;
def PMACHHURN : InstP2IC<"p.machhurn",0b1011011,0b10,0b110,[],GR32,GR32,uimm5>, Requires<[IsR5CY]>;


