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

TEMPFILE=$(tempfile)
echo $TEMPFILE

clang -emit-llvm -S "$@" -o $TEMPFILE
# Remove line starting with "source_filename".
# Needed for compatibility between different clang
# versions. Should be subsituted with a better solution
# in the future.
sed -i 's/^source_filename.*$//g' $TEMPFILE

clang "$@"
objcopy --add-section .pex=$TEMPFILE \
    --set-section-flags .pex=noload,readonly $OUTPUT_FILE