#!/bin/bash
# TODO: Add a comment that explains what this is.
# TODO: Add licensing comment

set -e

########## HELPERS ##########

function log {
	echo \[PEX\] $1
}
function print_usage {
	echo
	echo "Possible arguments for portable executable: "
	echo "    -t NAME Extract tar archive to directory NAME"
	echo "    -T Extract tar archive to directory tar"
	echo "    -r Force recompile"
	echo "    -a NAME Add the object files in NAME to the tar archive"
	echo "    -u NAME Use object files from NAME dir in tar archive"
	echo "    -h Display this help message"
	echo
}

##### ARGUMENT PARSING  #####

while getopts 't:Trha:u:' flag; do
  case "${flag}" in
    t) TARDIR="${OPTARG}";;
    T) TARDIR="tar";;
    r) FORCE_RECOMPILE=true;;
    a) ADD_OBJ_DIR="${OPTARG}";;
    u) OBJ_DIR="${OPTARG}";;
    h) print_usage
       exit 1;;
  esac
done

######### LOADER ############

BASE_DIR=$PWD
OUT_DIR=$(mktemp -d)

# Find the number of the line beginning with #__ARCHIVE__BELOW__ with grep.
# Add one to account for newline.
TAR_START_POSITION=$(( $( grep -na '^#__ARCHIVE__BELOW__' $0 | grep -o '^[0-9]*' ) + 1 ))

# Extract the tar archive.
tail -n+$TAR_START_POSITION $0 | tar -x -C $OUT_DIR

# If -t flag was set extract tar archive to $TARDIR and exit
if [[ $TARDIR ]]; then
	log "extracting tar from $0 to $TARDIR"
	rm -rf $TARDIR
	mkdir -p $TARDIR
	mv $OUT_DIR/* $TARDIR
	log "done"
	exit 0
fi

# determine current cpu architecture
ARCH=$( lscpu | head -n 1 | sed 's/Architecture:[[:space:]]*//g' )

# If -a flag was set, add new object files
if [[ $ADD_OBJ_DIR ]]; then
	cp -r $ADD_OBJ_DIR $OUT_DIR
	ARCH=$ADD_OBJ_DIR
fi

# If -u flag was set, use given folder name
if [[ $OBJ_DIR ]]; then
	log "using binaries in $OBJ_DIR"
	ARCH=$OBJ_DIR
fi

cd $OUT_DIR

# case 1: program is already compiled for the current architecture
if [[ -e $ARCH/a.out && ! $FORCE_RECOMPILE ]]; then
	log "executing existing binary for $ARCH"
	./$ARCH/a.out
	log "done"
	exit 0	
fi

# case 2: program needs to be compiled from IR
if [[ $FORCE_RECOMPILE && $OBJ_DIR ]]; then
	log "forcing recompilation from object files"
	rm -f $ARCH/a.out
elif [[ $FORCE_RECOMPILE && ! $OBJ_DIR ]]; then
	log "forcing recompilation from IR"
	rm -rf $ARCH
fi

# create sub directory for current architecture and change into it
mkdir -p $ARCH
cd $ARCH

if [[ -z $ADD_OBJ_DIR && -z $OBJ_DIR ]]; then
	# object files are not provided already
	log "generating object files from IR"
	clang -c ../*.ll 
fi

log "generating executable from object files"
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
