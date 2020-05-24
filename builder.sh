#!/bin/bash

OUT_DIR=.pex
rm -rf $OUT_DIR
mkdir -p $OUT_DIR

# TODO: dont hard-code input file names
clang -emit-llvm -S hello/hello.c hello/write.c
mv hello.ll write.ll $OUT_DIR

tar -cvf prog.tar "$OUT_DIR"/*
rm -r $OUT_DIR

LOADER_SCRIPT=\
"#!/bin/bash

tail -n+11 \$0 | tar -x

clang -c .pex/*.ll
clang /*.o

exit 0
#__ARCHIVE__BELOW__
"

# save portable executable
echo "$LOADER_SCRIPT" > program.pex
cat prog.tar >> program.pex
rm prog.tar

