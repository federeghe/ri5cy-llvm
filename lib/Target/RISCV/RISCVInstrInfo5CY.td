//==- RISCVInstrM.td - Multiply Divide RISCV instructions --*- tblgen-*-==//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

//RI5CY
def MUL5CY   : InstR<"mul"  , 0b0110011, 0b0000001000, mul   , GR32, GR32>, Requires<[Is5CY]>;

