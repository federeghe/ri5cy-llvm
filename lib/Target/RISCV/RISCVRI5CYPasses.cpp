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

using namespace llvm;



INITIALIZE_PASS(RISCVRI5CYIR, "riscv-ri5cy-IR-pass", 
                "RISCV RI5CY IR pass",false, false)

/// createRISCVBranchSelectionPass - returns an instance of the Branch Selection
/// Pass
///
FunctionPass *llvm::createRISCVRI5CYIRPass() {
  return new RISCVRI5CYIR();
}

bool RISCVRI5CYIR::runOnFunction(Function &F) {

    // Check if we are RI5CY()
//    this->TM = static_cast<const RISCVTargetMachine*>(&F.getTarget());
//    assert(TM->getSubtargetImpl()->isR5CY());


    errs() << "runOnFunction(" << F.getName().str() << ")\n";

    this->transformBitManipulation(F);

  return false;
}

bool RISCVRI5CYIR::transformBitManipulation(Function &F) {

    for (auto& BB : F) {
        for (auto& I : BB) {
            errs() << "  Instruction: " << I.getOpcodeName() << '\n';
            
            if ( I.getOpcode() == Instruction::And ) {
                // Manage BSET and BCLR

                Value *op1 = I.getOperand(0);
                Value *op2 = I.getOperand(1);
                unsigned size = op2->getType()->getPrimitiveSizeInBits();          
			          unsigned int immediate = 0;
                if (isa<ConstantInt>(op1) && size >= 16 && size <=32) {
				          immediate = cast<ConstantInt>(op1)->getLimitedValue(~(uint32_t)0);
                } else if (isa<ConstantInt>(op2) && size >= 16 && size <=32) {
				          immediate = cast<ConstantInt>(op2)->getLimitedValue(~(uint32_t)0);
                }

		          	if (immediate == 0)	{ errs() << "IMM=0\n"; continue; }


                errs() << "MANAGING BCLR" << '\n';
			          // Now we have to check if the immediate is in the form 111100...00111
			          // or we cannot do anything.
			          unsigned int limit_l;
			          unsigned int limit_r;

/*
                if (!bitIntervalExtraction(immediate, limit_l, limit_r)) {
                    continue;
                }

		          	errs() << "ADD L " << limit_l << " R " << limit_r << '\n';
  
                RISCVMetadata md(RISCVMetadata::SPECIALIZED);
                md.addImmediate(0,limit_l);
                md.addImmediate(1,limit_r);
                ArrayRef arr_immediate( { md } );
                MDNode metanode( F.getContext(), RISCV_RI5CY_MNODE_ID, 
                                 MDNode::Uniqued, arr_immediate);  
                I.setMetadata(RISCVMetadata::Metadata_ID, metanode);*/
            }

      }
  }

    return false;
}


bool RI5CY_bitIntervalExtraction( int n, unsigned int* l_pos, unsigned int* r_pos, bool invert) {

      unsigned int l_limit, r_limit;

			enum { BEFORE, IN, AFTER, INVALID } status;

			status = BEFORE;

			for(int i=0; i<32; i++) {
				if ( invert ^ ((bool)(( ((int32_t)1) << i) & n)) ) {
					if (status == IN) {
						status = AFTER;
						l_limit = i-1;
					}
				} else {
					if (status == BEFORE) {
						status = IN;
						r_limit = i;
					}
					else if (status == AFTER) {
						// We found another 0 after the first sequence 
						status = INVALID;
						return false;
					}
				}

			}

      if (status == BEFORE) {
        return false;
      }

      if (l_pos != NULL ) {
          *l_pos = l_limit;
      }

      if (r_pos != NULL ) {
          *r_pos = r_limit;
      }

      return true;  
}

