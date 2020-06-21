#!/bin/bash
# 
# This is a wrapper around the clang linker that emits a .pex file.
# It assumes that the given object files contain the corresponding
# clang IR as a .pex Section in the object file.

set -e

########## HELPERS ##########

function log {
	echo \[PEX-LD\] $1
}
function print_usage {
	echo
	echo "Possible arguments for PEX Linker: "
	echo "    -o NAME name of the output"
	echo "    -h Display this help message"
    # TODO: implement this
    # echo "    all other flags are interpreted as flags for the clang linker"
	echo
}

##### ARGUMENT PARSING  #####

while getopts 'o:' flag; do
  case "${flag}" in
    o) OUTPUT_FILE="${OPTARG}";;
  esac
done

####### LINKING LOGIC ######

TEMPDIR=$(mktemp -d)
log "tar archive gets built in $TEMPDIR"

# creating folder for current arch to persist object files in .pex
ARCH=$(clang -dumpmachine)

# loop over all arguments to detect then ones that are .o files
# get IR out of the .pex sections for each object file
# prepare .o files to be persisted in .pex
for arg in "$@"; do
    if [[ $arg =~ ^.*\.o$ ]]; then
        mkdir -p $( dirname $TEMPDIR/$ARCH/$arg )
        mkdir -p $( dirname $TEMPDIR/$arg )
        objcopy --dump-section .pex="$TEMPDIR"/"$arg".ll $arg
        cp "$arg" "$TEMPDIR"/"$ARCH"/"$arg"
    else
        echo -n "$arg " >> $TEMPDIR/LINKER_FLAGS
    fi
done

# linking for current arch in future .pex
BASEDIR=$( pwd )
cd "$TEMPDIR"/"$ARCH"
clang "$@" -o a.out

log "creating tar archive with the .ll files"
cd ..
tar -cf prog.tar *
cd $BASEDIR

# The script that will later be bundled with the tar archive
LOADER_SCRIPT=$(cat loader.sh)

log "merging loader script and tar archive to portable executable"
echo "$LOADER_SCRIPT" > $OUTPUT_FILE
cat "$TEMPDIR"/prog.tar >> $OUTPUT_FILE

# make loader script executable
# TODO: Maybe make this only executable for the current user?
## currently not possible, since we need to use sudo in fsoc lab
chmod a+x $OUTPUT_FILE