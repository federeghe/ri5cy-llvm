#define DEBUG_TYPE "riscv-ri5cy-passes"

#include <map>

#include "RISCV.h"
#include "RISCVInstrBuilder.h"
#include "RISCVInstrInfo.h"
#include "llvm/ADT/Statistic.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/Support/MathExtras.h"
#include "llvm/Target/TargetMachine.h"
#include "RISCVTargetMachine.h"

#define RISCV_RI5CY_MNODE_ID 9999

using namespace llvm;

extern bool RI5CY_bitIntervalExtraction( int n, unsigned int* l_pos=NULL, unsigned int* r_pos=NULL, bool invert=false);
extern bool RI5CY_pclip_check(SelectionDAG* CurDAG, const SDValue &Dest, SDValue &SRC1, SDValue &SRC2, bool unsign);


namespace llvm {
  void initializeRISCVRI5CYIRPass(PassRegistry&);
}


namespace {


class RISCVRI5CYIR : public FunctionPass {

public:
  static char ID;

  RISCVRI5CYIR() : FunctionPass(ID) {
     initializeRISCVRI5CYIRPass(*PassRegistry::getPassRegistry());
  }

  virtual ~RISCVRI5CYIR() {
      if (dag != NULL) {
          delete dag;
      } 
  }

  /// BlockSizes - The sizes of the basic blocks in the function.
  std::vector<unsigned> BlockSizes;

  virtual bool runOnFunction(Function &F);

  virtual const char *getPassName() const {
    return "RISCV RI5CY IR pass";
  }

  const RISCVTargetMachine *TM; 
  SelectionDAG * dag = NULL;
  bool transformBitManipulation(Function &F);

  private:

};

char RISCVRI5CYIR::ID = 0;


// Metadata class
class RISCVMetadata : public Metadata {


public:
    static const unsigned Metadata_ID=999;

    typedef enum RISCV_metadata_type_e { NONE, SPECIALIZED } RISCV_metadata_type_t;

    RISCVMetadata(RISCV_metadata_type_t t) :  Metadata(Metadata_ID,Uniqued), type(t) { }

    void addImmediate(int pos, int value) { immediates[pos]=value; }
    int getImmediate(int pos) { return immediates[pos]; }

private:
    RISCV_metadata_type_t type;

    std::map<int,int> immediates;

};



}
