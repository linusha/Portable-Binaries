#!/bin/bash
# 
# This is a wrapper around the clang linker that emits a .pex file.
# It assumes that the given object files contain the corresponding
# clang IR as a .pex Section in the object file.
# If you want to use a custom name for the bundle inside the created .pex
# set PEX_STORE_AS

set -e

########## HELPERS ##########

function log {
	if [[ -n $PEX_VERBOSE ]]; then
		echo \[PEX-LD\] $1
	fi
}
function print_usage {
	echo
	echo "Possible arguments for PEX Linker: "
	echo "    -o NAME name of the output"
    echo "All other flags are interpreted as flags for the clang linker."
	echo
}

##### ARGUMENT PARSING  #####

while getopts 'o:' flag; do
  case "${flag}" in
    o) OUTPUT_FILE="${OPTARG}";;
  esac
done

####### LINKING LOGIC ######
INSTDIR=$( dirname $( realpath $0 ) )
TEMPDIR=$(mktemp -d)
log "tar archive gets built in $TEMPDIR"

# use current arch as name when no name is given
if [[ -z $PEX_STORE_AS ]]; then
    PEX_STORE_AS=$(clang -dumpmachine)
fi
# loop over all arguments to detect then ones that are .o files
# get IR out of the .pex sections for each object file
# prepare .o files to be persisted in .pex

for arg in "$@"; do
    if [[ $arg =~ ^.*\.o$ ]]; then
        mkdir -p $( dirname $TEMPDIR/$PEX_STORE_AS/$arg )
        mkdir -p $( dirname $TEMPDIR/IR/$arg )
        objcopy --dump-section .pex="$TEMPDIR"/IR/"$arg".ll $arg
        cp "$arg" "$TEMPDIR"/"$PEX_STORE_AS"/"$arg"
        echo -n "$arg " >> $TEMPDIR/LINKER_FILES
    else
        echo -n "$arg " >> $TEMPDIR/LINKER_FLAGS
    fi
done

# remove -n from linker flags file, since it is a pex flag

sed -i "s/-n[[:space:]]\([[:alpha:]]\)*//" $TEMPDIR/LINKER_FLAGS

# linking for current arch in future .pex
BASEDIR=$( pwd )
cd "$TEMPDIR"/"$PEX_STORE_AS"
clang $( cat $TEMPDIR/LINKER_FLAGS ) $( cat $TEMPDIR/LINKER_FILES ) -o a.out
rm $TEMPDIR/LINKER_FILES
log "creating tar archive with the .ll files"
cd ..
tar -cf prog.tar *
cd $BASEDIR

# The script that will later be bundled with the tar archive
LOADER_SCRIPT=$(cat $INSTDIR/loader.sh)

log "merging loader script and tar archive to portable executable"
echo "$LOADER_SCRIPT" > $OUTPUT_FILE
cat "$TEMPDIR"/prog.tar >> $OUTPUT_FILE

# make loader script executable
# TODO: Maybe make this only executable for the current user?
## currently not possible, since we need to use sudo in fsoc lab
chmod a+x $OUTPUT_FILE