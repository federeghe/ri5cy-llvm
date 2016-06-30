#define DEBUG_TYPE "riscv-ri5cy-passes"

#include "RISCV.h"
#include "RISCVInstrBuilder.h"
#include "RISCVInstrInfo.h"
#include "llvm/ADT/Statistic.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/Support/MathExtras.h"
#include "llvm/Target/TargetMachine.h"
#include "RISCVTargetMachine.h"

using namespace llvm;


namespace llvm {
  void initializeRISCVRI5CYDagToDagPass(PassRegistry&);
}


namespace {
  struct RISCVRI5CYDagToDag : public MachineFunctionPass {
    static char ID;

    RISCVRI5CYDagToDag() : MachineFunctionPass(ID) {
       initializeRISCVRI5CYDagToDagPass(*PassRegistry::getPassRegistry());
    }

    virtual ~RISCVRI5CYDagToDag() {
        if (dag != NULL) {
            delete dag;
        } 
    }

    /// BlockSizes - The sizes of the basic blocks in the function.
    std::vector<unsigned> BlockSizes;

    virtual bool runOnMachineFunction(MachineFunction &MF);

    virtual const char *getPassName() const {
      return "RISCV RI5CY Dag-To-Dag pass";
    }

    const RISCVTargetMachine *TM; 
    SelectionDAG * dag = NULL;
    bool transform4BitManipulation(MachineFunction &MF);
  };

  char RISCVRI5CYDagToDag::ID = 0;

}
