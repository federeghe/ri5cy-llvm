#define DEBUG_TYPE "riscv-ri5cy-passes"
#include "RISCV.h"
#include "RISCVInstrBuilder.h"
#include "RISCVInstrInfo.h"
#include "llvm/ADT/Statistic.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/Support/MathExtras.h"
#include "llvm/Analysis/TargetTransformInfo.h"
#include "llvm/Target/TargetMachine.h"
#include "RISCVRI5CYPasses.h"

#warning REMOVE ME
#include <stdio.h>
#warning REMOVE ME

using namespace llvm;



INITIALIZE_PASS(RISCVRI5CYDagToDag, "riscv-ri5cy-dagtodag-pass", 
                "RISCV RI5CY Dag-To-Dag pass",false, false)

/// createRISCVBranchSelectionPass - returns an instance of the Branch Selection
/// Pass
///
FunctionPass *llvm::createRISCVRI5CYDagToDagPass() {
  return new RISCVRI5CYDagToDag();
}

bool RISCVRI5CYDagToDag::runOnMachineFunction(MachineFunction &MF) {

    // Check if we are RI5CY()
    this->TM = static_cast<const RISCVTargetMachine*>(&MF.getTarget());
    assert(TM->getSubtargetImpl()->isR5CY());


    dag = new SelectionDAG(*TM, TM->getOptLevel());
    dag->init(MF);

    printf("runOnMachineFunction(%s)\n", MF.getName().str().c_str());

    this->transform4BitManipulation(MF);

  return false;
}

bool RISCVRI5CYDagToDag::transform4BitManipulation(MachineFunction &MF) {

    printf("transform4BitManipulation()\n");

    for (ilist<SDNode>::iterator  it = dag->allnodes_begin(); it != dag->allnodes_end(); it++) {
        printf("HOP %s\n", it->getOperationName().c_str());
    }

    return false;
}
