//===-- RISCVSubtarget.h - RISCV subtarget information ----------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file declares the RISCV specific subclass of TargetSubtargetInfo.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_RISCV_RISCVSUBTARGET_H
#define LLVM_LIB_TARGET_RISCV_RISCVSUBTARGET_H

#include "RISCVFrameLowering.h"
#include "RISCVISelLowering.h"
#include "RISCVInstrInfo.h"
#include "RISCVRegisterInfo.h"
#include "llvm/CodeGen/SelectionDAGTargetInfo.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/ADT/Triple.h"
#include "llvm/Target/TargetFrameLowering.h"
#include "llvm/Target/TargetSubtargetInfo.h"
#include <string>

#define GET_SUBTARGETINFO_HEADER
#include "RISCVGenSubtargetInfo.inc"

namespace llvm {
class GlobalValue;
class StringRef;

class RISCVSubtarget : public RISCVGenSubtargetInfo {
protected:
  enum RISCVArchEnum {
    RV32,
    RV64
  };

  RISCVArchEnum RISCVArchVersion;

  bool HasM;
  bool HasA;
  bool HasF;
  bool HasD;

  bool UseSoftFloat;

  bool IsR5CY;

private:
  Triple TargetTriple;
  RISCVInstrInfo InstrInfo;
  RISCVTargetLowering TLInfo;
  SelectionDAGTargetInfo TSInfo;
  RISCVFrameLowering FrameLowering;

  RISCVSubtarget &initializeSubtargetDependencies(StringRef CPU, StringRef FS);

public:
  RISCVSubtarget(const Triple &TT, const std::string &CPU,
                 const std::string &FS, const TargetMachine &TM);

  const TargetFrameLowering *getFrameLowering() const { return &FrameLowering; }
  const RISCVInstrInfo *getInstrInfo() const { return &InstrInfo; }
  const RISCVRegisterInfo *getRegisterInfo() const {
    return &InstrInfo.getRegisterInfo();
  }
  const RISCVTargetLowering *getTargetLowering() const { return &TLInfo; }
  const SelectionDAGTargetInfo *getSelectionDAGInfo() const { return &TSInfo; }

  bool isRV32() const { return RISCVArchVersion == RV32; };
  bool isRV64() const { return RISCVArchVersion == RV64; };

  bool hasM() const { return HasM; };
  bool hasA() const { return HasA; };
  bool hasF() const { return HasF; };
  bool hasD() const { return HasD; };

  bool useSoftFloat() const { return UseSoftFloat; }

  bool isR5CY() const { return IsR5CY; };


  // Automatically generated by tblgen.
  void ParseSubtargetFeatures(StringRef CPU, StringRef FS);

  // Return true if GV can be accessed using LARL for reloc model RM
  // and code model CM.
  bool isPC32DBLSymbol(const GlobalValue *GV, Reloc::Model RM,
                       CodeModel::Model CM) const;

  bool isTargetELF() const { return TargetTriple.isOSBinFormatELF(); }
};
} // end namespace llvm

#endif
