#!/bin/bash
# takes exactly one argument which is the name of the folder 
# inside the current dir in which the .c files are

OUT_DIR=.pex

rm -rf $OUT_DIR
mkdir -p $OUT_DIR
cd $OUT_DIR 

# create IR for every c file in the given directory
clang -emit-llvm -S ../$1/*.c

# create a tar archive with the .ll files
tar -cvf prog.tar *

# The script that will later be bundled with the tar archive
LOADER_SCRIPT=\
"#!/bin/bash
mkdir -p .pex

# Find the tar archive inside the script and extract it.
# In the option -n+XX , XX indicates the line in which
# the tar archive starts.
tail -n+21 \$0 | tar -x -C .pex

cd .pex

# compile the program
clang -c *.ll 
clang *.o 

# execute the program
./a.out

exit 0

# after this the archive will be injected
#__ARCHIVE__BELOW__
"

cd ..

# merge loader script and tar archive to portable executable
echo "$LOADER_SCRIPT" > program.pex
cat "$OUT_DIR"/prog.tar >> program.pex

# make loader script executable
chmod a+x program.pex

# clean up
rm -r $OUT_DIR
