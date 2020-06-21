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
    echo "    -n NAME name of the target inside output .pex file"
    echo "All other flags are interpreted as flags for the clang linker."
	echo
}

##### ARGUMENT PARSING  #####

while getopts 'o:n:' flag; do
  case "${flag}" in
    o) OUTPUT_FILE="${OPTARG}";;
    n) NAME="${OPTARG}";;
  esac
done

####### LINKING LOGIC ######

TEMPDIR=$(mktemp -d)
log "tar archive gets built in $TEMPDIR"

# use current arch as name when no name is given
if [[ -z $NAME ]]; then
    NAME=$(clang -dumpmachine)
fi
# loop over all arguments to detect then ones that are .o files
# get IR out of the .pex sections for each object file
# prepare .o files to be persisted in .pex

for arg in "$@"; do
    if [[ $arg =~ ^.*\.o$ ]]; then
        mkdir -p $( dirname $TEMPDIR/$NAME/$arg )
        mkdir -p $( dirname $TEMPDIR/IR/$arg )
        objcopy --dump-section .pex="$TEMPDIR"/IR/"$arg".ll $arg
        cp "$arg" "$TEMPDIR"/"$NAME"/"$arg"
        echo -n "$arg " >> $TEMPDIR/LINKER_FILES
    else
        echo -n "$arg " >> $TEMPDIR/LINKER_FLAGS
    fi
done

# remove -n from linker flags file, since it is a pex flag

sed -i "s/-n[[:space:]]\([[:alpha:]]\)*//" $TEMPDIR/LINKER_FLAGS

# linking for current arch in future .pex
BASEDIR=$( pwd )
cd "$TEMPDIR"/"$NAME"
clang $( cat $TEMPDIR/LINKER_FLAGS ) $( cat $TEMPDIR/LINKER_FILES ) -o a.out
rm $TEMPDIR/LINKER_FILES
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