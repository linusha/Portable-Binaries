#!/bin/bash
# Arguments:
# - name of the folder (wihtout /,...) in which the c files are
#
# IMPORTANT: currently there is no support for subfolders, multiple folders,...

BASE_DIR=$PWD
OUT_DIR=$(mktemp -d)

cd $OUT_DIR 

# create IR for every c file in the given directory
clang -emit-llvm -S $BASE_DIR/$1/*.c

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

BASE_DIR=\$PWD  # unused for now
OUT_DIR=\$(mktemp -d)

# Find the number of the line beginning with #__ARCHIVE__BELOW__ with grep.
# Add one to account for newline.
TAR_START_POSITION=\$(( \$( grep -na '^#__ARCHIVE__BELOW__' \$0 | grep -o '^[0-9]*' ) + 1 ))

# Extract the tar archive.
tail -n+\$TAR_START_POSITION \$0 | tar -x -C \$OUT_DIR

cd \$OUT_DIR

# compile the program
# TODO: don't save anything to disk
clang -c *.ll 
clang *.o 

# execute the program
# TODO execute program in its original context (aka in BASE_DIR)
./a.out

exit 0

# After this line the archive is injected.
#__ARCHIVE__BELOW__"

cd $BASE_DIR

# merge loader script and tar archive to portable executable
echo "$LOADER_SCRIPT" > program.pex
cat "$OUT_DIR"/prog.tar >> program.pex

# make loader script executable
# TODO: Maybe make this only executable for the current user?
chmod a+x program.pex
