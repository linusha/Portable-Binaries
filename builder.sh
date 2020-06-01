#!/bin/bash
# Arguments:
# - name of the folder (wihtout /,...) in which the c files are
#
# IMPORTANT: currently there is no support for subfolders, multiple folders,...

OUT_DIR=.pex

rm -rf $OUT_DIR
mkdir -p $OUT_DIR
cd $OUT_DIR 

# create IR for every c file in the given directory
clang -emit-llvm -S ../$1/*.c

# Remove line starting with "source_filename".
# Needed for compatibility between different clang
# versions. Should be subsituted with a better solution
# in the future.
sed -i 's/^source_filename.*$//g' *.ll

# create a tar archive with the .ll files
tar -cvf prog.tar *

# The script that will later be bundled with the tar archive
LOADER_SCRIPT=\
"#!/bin/bash
# TODO: Add a comment that explains what this is.
#
rm -rf .pex
mkdir -p .pex

# Extract the tar archive.
# In the option -n+XX , XX indicates the line in which
# the tar archive starts.
#
# TODO: check this number if you edited the loader script
tail -n+28 \$0 | tar -x -C .pex

cd .pex

# compile the program
# TODO: don't save anything to disk
clang -c *.ll 
clang *.o 

# execute the program
./a.out

exit 0

# After this line the archive is injected.
#__ARCHIVE__BELOW__
"

cd ..

# merge loader script and tar archive to portable executable
echo "$LOADER_SCRIPT" > program.pex
cat "$OUT_DIR"/prog.tar >> program.pex

# make loader script executable
# TODO: Maybe make this only executable for the current user?
chmod a+x program.pex

# clean up
rm -r $OUT_DIR
