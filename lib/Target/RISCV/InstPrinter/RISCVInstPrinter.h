//===- RISCVInstPrinter.h - Convert RISCV MCInst to assembly ----*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This class prints a RISCV MCInst to a .s file.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_RISCV_RISCVINSTPRINTER_H
#define LLVM_LIB_TARGET_RISCV_RISCVINSTPRINTER_H

#include "llvm/MC/MCInstPrinter.h"
#include "llvm/Support/Compiler.h"

namespace llvm {
class MCOperand;

class RISCVInstPrinter : public MCInstPrinter {
public:
  RISCVInstPrinter(const MCAsmInfo &MAI, const MCInstrInfo &MII,
                     const MCRegisterInfo &MRI)
    : MCInstPrinter(MAI, MII, MRI) {}

  // Automatically generated by tblgen.
  void printInstruction(const MCInst *MI, raw_ostream &O);
  static const char *getRegisterName(unsigned RegNo);

  // Print an address with the given base, displacement and index.
  static void printAddress(unsigned Base, int64_t Disp,
                           raw_ostream &O);

  // Print the given operand.
  static void printOperand(const MCOperand &MO, raw_ostream &O);

  // Override MCInstPrinter.
  void printRegName(raw_ostream &O, unsigned RegNo) const override;
  void printInst(const MCInst *MI, raw_ostream &O, StringRef Annot,
      const MCSubtargetInfo &STI) override;

private:
  // Print various types of operand.
  void printOperand(const MCInst *MI, int OpNum, raw_ostream &O);
  void printBranchTarget(const MCInst *MI, int OpNum, raw_ostream &O);
  void printBDAddrOperand(const MCInst *MI, int OpNum, raw_ostream &O);
  void printBDXAddrOperand(const MCInst *MI, int OpNum, raw_ostream &O);
  void printU5ImmOperand(const MCInst *MI, int OpNum, raw_ostream &O);
  void printS12ImmOperand(const MCInst *MI, int OpNum, raw_ostream &O);
  void printU12ImmOperand(const MCInst *MI, int OpNum, raw_ostream &O);
  void printS20ImmOperand(const MCInst *MI, int OpNum, raw_ostream &O);
  void printU20ImmOperand(const MCInst *MI, int OpNum, raw_ostream &O);
  void printMemOperand(const MCInst *MI, int OpNUm, raw_ostream &O);
  void printJALRMemOperand(const MCInst *MI, int OpNUm, raw_ostream &O);
  void printMemRegOperand(const MCInst *MI, int OpNUm, raw_ostream &O);
  void printS32ImmOperand(const MCInst *MI, int OpNum, raw_ostream &O);
  void printU32ImmOperand(const MCInst *MI, int OpNum, raw_ostream &O);
  void printS64ImmOperand(const MCInst *MI, int OpNum, raw_ostream &O);
  void printU64ImmOperand(const MCInst *MI, int OpNum, raw_ostream &O);
  void printCallOperand(const MCInst *MI, int OpNum, raw_ostream &O);
  void printAccessRegOperand(const MCInst *MI, int OpNum, raw_ostream &O);

  void printUimm32contig0Operand(const MCInst *MI, int OpNum, raw_ostream &O);
  void printUimm32contig1Operand(const MCInst *MI, int OpNum, raw_ostream &O);
  void printUimm32contig1endOperand(const MCInst *MI, int OpNum, raw_ostream &O);
  // Print the mnemonic for a condition-code mask ("ne", "lh", etc.)
  // This forms part of the instruction name rather than the operand list.
  void printCond4Operand(const MCInst *MI, int OpNum, raw_ostream &O);
};
} // end namespace llvm

#endif
