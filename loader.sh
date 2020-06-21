#!/bin/bash
# TODO: Add a comment that explains what this is.

set -e

########## HELPERS ##########

function log {
	echo \[PEX\] $1
}

######### LOADER ############

BASE_DIR=$PWD
OUT_DIR=$(mktemp -d)

# Find the number of the line beginning with #__ARCHIVE__BELOW__ with grep.
# Add one to account for newline.
TAR_START_POSITION=$(( $( grep -na '^#__ARCHIVE__BELOW__' $0 | grep -o '^[0-9]*' ) + 1 ))

# Extract the tar archive.
tail -n+$TAR_START_POSITION $0 | tar -x -C $OUT_DIR

# determine current cpu architecture
ARCH=$(clang -dumpmachine)

# TODO: reuse for tagging system  
# If -u flag was set, use given folder name
if [[ $OBJ_DIR ]]; then
	log "using binaries in $OBJ_DIR"
	ARCH=$OBJ_DIR
fi

cd $OUT_DIR

# program is already compiled for the current architecture
if [[ -e $ARCH/a.out ]]; then
	log "executing existing binary for $ARCH"
	./$ARCH/a.out
	log "done"
	exit 0	
# programs needs to be compiled from IR
else
	# create sub directory for current architecture and change into it
	mkdir -p $ARCH
	cd $ARCH

	# object files are not provided already
	log "generating object files from IR"
	clang -c ../*.ll 

	log "generating executable from object files"
	clang $( cat ../LINKER_FLAGS ) -o a.out *.o  

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
fi
# After this line the archive is injected.
#__ARCHIVE__BELOW__
