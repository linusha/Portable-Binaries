#!/bin/bash
# Uses env var PEX_USE_TAG to determine the bundle that should be run.
# If the env var is not set, use architecture triple as default

set -e
shopt -s globstar

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

# if the env variable PEX_USE_TAG is set, use corresponding bundle
if [[ -n $PEX_USE_TAG ]]; then
	log "pex tag is set to $PEX_USE_TAG"
	ARCH=$PEX_USE_TAG
fi

cd $OUT_DIR

# programs needs to be compiled from IR
if [[ ! -e $ARCH/a.out ]]; then
	# create sub directory for current architecture and change into it
	mkdir -p $ARCH
	cd $ARCH

	# object files are not provided already
	log "generating object files from IR"
	
	for file in ../IR/**/*.ll; do
		mkdir -p $( dirname ${file:6} ) 
		clang -c "$file" -o "${file:6}".o 
	done

	log "generating executable from object files"
	clang $( cat ../LINKER_FLAGS ) -o a.out **/*.o  

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

	log "Added binary for tag $ARCH to $0"
fi

# execute program in subshell, using directory and
# name of the original call to .pex
log "executing binary for tag $ARCH"
( cd $BASE_DIR && exec -a $0 $OUT_DIR/$ARCH/a.out $@ )

log "done"
exit 0	

# After this line the archive is injected.
#__ARCHIVE__BELOW__