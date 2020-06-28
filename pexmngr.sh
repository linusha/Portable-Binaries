#!/bin/bash
# This is helper program to interact with pex files in order to:
# - extract the tar archive,
# - force recompilation for the current architecture
# - merge two .pex files for the same program 
#   (assumes disjunct architecture sets)
# - list the content of the pex
# - remove an architecture from a pex

set -e

########## HELPERS ##########

function log {
	if [[ -n $PEX_VERBOSE ]]; then
		echo \[PEX-MNGR\] $1
	fi
}
function print_usage {
	echo
	echo "Possible arguments for portable executable: "
    echo "    First argument must be the PEX file you want to work with!"\
         "(except for help)."
    echo "    You have to specify exactly one file and operation."
	echo "    --extract NAME Extract tar archive to directory NAME"
	echo "    defaults to ./tar"
	echo "    --merge NAME2 adds the content of pex file NAME2 to PEX"
	echo "    --ls list the content of PEX"
    echo "    --rm ARCH delete the ARCH folder from the PEX"
    echo "    defaults to current architecture"
    echo "    --help Display this help message"
	echo
}

####### MANAGER LOGIC #######

# called without arguments or with --help
if [[ -z $1 || $1 == "--help" ]]; then
    print_usage
    exit 1
fi

if [[ -z $2 ]]; then
    log "You have to provide filename and operation."
    print_usage
    exit 1
fi


PEXFILE=$1
OPERATION=$2
ARGUMENT=$3
TEMPDIR=$(mktemp -d)

TAR_START_POSITION=$(( $( grep -na '^#__ARCHIVE__BELOW__' $PEXFILE | grep -o '^[0-9]*' ) + 1 ))
tail -n+$TAR_START_POSITION $PEXFILE | tar -x -C $TEMPDIR

if [[ $OPERATION == "--extract" ]]; then
    
    if [[ -z $ARGUMENT ]]; then
        ARGUMENT="tar"
    fi
    mkdir -p $ARGUMENT
    cp -r $TEMPDIR/* $ARGUMENT
    log "Extracting to: $ARGUMENT"
    exit 0
fi

if [[ $OPERATION == "--merge" ]]; then
    if [[ -z $ARGUMENT ]]; then
        log "You have to provide a PEX to merge with."
        exit 1
    fi
    $0 $ARGUMENT --extract $TEMPDIR
    BASEDIR=$(pwd)
    cd $TEMPDIR
    tar -cf prog.tar *
    cd $BASEDIR
    head -n $(( $TAR_START_POSITION - 1)) $PEXFILE | cat > "$TEMPDIR"/new_program.pex
    cat "$TEMPDIR"/prog.tar >> "$TEMPDIR"/new_program.pex
    mv "$TEMPDIR"/new_program.pex $PEXFILE
    chmod a+x $PEXFILE
    exit 0
fi

if [[ $OPERATION == "--ls" ]]; then
    ls -R $TEMPDIR
    exit 0
fi

if [[ $OPERATION == "--rm" ]]; then
    if [[ -z $ARGUMENT ]]; then
        ARGUMENT=$( clang -dumpmachine )
    fi
    BASEDIR=$(pwd)
    cd $TEMPDIR
    rm -rf $ARGUMENT
    tar -cf prog.tar *
    cd $BASEDIR
    head -n $(( $TAR_START_POSITION - 1)) $PEXFILE | cat > "$TEMPDIR"/new_program.pex
    cat "$TEMPDIR"/prog.tar >> "$TEMPDIR"/new_program.pex
    mv "$TEMPDIR"/new_program.pex $PEXFILE
    chmod a+x $PEXFILE
    exit 0
fi

exit 1
