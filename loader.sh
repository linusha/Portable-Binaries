#!/bin/bash
# TODO: Add a comment that explains what this is.
#

BASE_DIR=$PWD
OUT_DIR=$(mktemp -d)

# Find the number of the line beginning with #__ARCHIVE__BELOW__ with grep.
# Add one to account for newline.
TAR_START_POSITION=$(( $( grep -na '^#__ARCHIVE__BELOW__' $0 | grep -o '^[0-9]*' ) + 1 ))

# Extract the tar archive.
tail -n+$TAR_START_POSITION $0 | tar -x -C $OUT_DIR

cd $OUT_DIR

# create sub directory for current architecture and change into it
ARCH=$( lscpu | head -n 1 | sed 's/Architecture:[[:space:]]*//g' )
rm -rf $ARCH
mkdir $ARCH
cd $ARCH

# compile the program
clang -c ../*.ll 
clang *.o 

echo $OUT_DIR

# execute the program
# TODO execute program in its original context (aka in BASE_DIR)
./a.out

# Re-build tar archive
# 1. Create new tar archive
cd ..
tar -cvf prog.tar *
# merge loader script and tar archive to portable executable
cd $BASE_DIR
echo $TAR_START_POSITION
head -n $(( $TAR_START_POSITION - 1)) $0 | cat > "$OUT_DIR"/new_program.pex
cat "$OUT_DIR"/prog.tar >> "$OUT_DIR"/new_program.pex
mv "$OUT_DIR"/new_program.pex $0
chmod a+x $0
 
exit 0

# After this line the archive is injected.
#__ARCHIVE__BELOW__
