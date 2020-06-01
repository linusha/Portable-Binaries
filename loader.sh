#!/bin/bash
# TODO: Add a comment that explains what this is.
#

function log {
	echo \[PEX\] $1
}

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

# case 1: program is already compiled for the current architecture
# TODO: Support manually inserting .o files
if [ -d $ARCH ]; then
	log "executing existing binary for $ARCH"
	./$ARCH/a.out
	log "done"
	exit 0	
fi

# case 2: program needs to be compiled from IR
log "no precompiled binary for $ARCH detected"

mkdir $ARCH
cd $ARCH

log "compiling program from IR"
clang -c ../*.ll 
clang *.o 

# TODO execute program in its original context (aka in BASE_DIR)
log "executing program"
./a.out

log "re-building tar archive"
cd ..
tar -cf prog.tar *

log "generating new portable executable"
cd $BASE_DIR
head -n $(( $TAR_START_POSITION - 1)) $0 | cat > "$OUT_DIR"/new_program.pex
cat "$OUT_DIR"/prog.tar >> "$OUT_DIR"/new_program.pex

log "substituting existing portable executable"
mv "$OUT_DIR"/new_program.pex $0
chmod a+x $0

log "Added binary for arch $ARCH to $0"
 
log "done"
exit 0

# After this line the archive is injected.
#__ARCHIVE__BELOW__
