#!/bin/bash
# TODO: Add a comment that explains what this is.
# TODO: Add licensing comment
# TODO: make own object files name configurable

set -e

########## HELPERS ##########

function log {
	echo \[PEX\] $1
}
# function print_usage {
# 	echo
# 	echo "Possible arguments for portable executable: "
# 	echo "    -t NAME Extract tar archive to directory NAME"
# 	echo "    -T Extract tar archive to directory tar"
# 	echo "    -r Force recompile. If -u is given recompile from object files, else from IR"
# 	echo "    -a NAME Add the object files in NAME to the tar archive"
# 	echo "    -u NAME Use object files from NAME dir in tar archive"
# 	echo "    -h Display this help message"
# 	echo
# }

##### ARGUMENT PARSING  #####

while getopts 'o:' flag; do
  case "${flag}" in
    o) OUTPUT_FILE="${OPTARG}";;
  esac
done

TEMPDIR=$(mktemp -d)
echo $TEMPDIR

for i in "$@"; do
    if [[ $i =~ ^.*\.o$ ]]; then
        objcopy --dump-section .pex="$TEMPDIR"/"$i".ll $i
    fi
done

# create a tar archive with the .ll files
ls $TEMPDIR
tar -cf "$TEMPDIR"/prog.tar -C "$TEMPDIR" .

# The script that will later be bundled with the tar archive
LOADER_SCRIPT=$(cat loader.sh)

# merge loader script and tar archive to portable executable
echo "$LOADER_SCRIPT" > $OUTPUT_FILE
cat "$TEMPDIR"/prog.tar >> $OUTPUT_FILE

# make loader script executable
# TODO: Maybe make this only executable for the current user?
chmod a+x $OUTPUT_FILE