#!/bin/bash

OUT_DIR=.pex
rm -rf $OUT_DIR
mkdir -p $OUT_DIR

# TODO: dont hard-code input file names
cd $OUT_DIR 
clang -emit-llvm -S ../$1/*.c

tar -cvf prog.tar *

LOADER_SCRIPT=\
"#!/bin/bash

mkdir -p .pex
tail -n+17 \$0 | tar -x -C .pex

cd .pex
clang -c *.ll 
clang *.o 

#rm -r .pex *.o

./a.out

exit 0
#__ARCHIVE__BELOW__
"

# save portable executable
cd ..
echo "$LOADER_SCRIPT" > program.pex
cat "$OUT_DIR"/prog.tar >> program.pex
chmod a+x program.pex

rm -r $OUT_DIR
