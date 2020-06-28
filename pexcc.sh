#!/bin/bash
# 
# This is a wrapper around the clang compiler that emits modified object files.
# In the output files is a .pex ELF-Section that contains the LLVM-IR.

set -e

########## HELPERS ##########

function log {
	echo \[PEX-CC\] $1
}
function print_usage {
	echo
    echo "You may only pass a single .c File at a time."
	echo "Possible arguments for PEX Compiler:"
	echo "    -o NAME name of the output file"
	echo "    -h Display this help message"
	echo
}

##### ARGUMENT PARSING  #####

while getopts 'o:' flag; do
  case "${flag}" in
    o) OUTPUT_FILE="${OPTARG}";;
  esac
done

###### COMPILER LOGIC ######

TEMPFILE=$(mktemp)

log "Generating IR and storing it in $TEMPFILE"
clang -emit-llvm -S "$@" -o $TEMPFILE

# Remove line starting with "source_filename".
# Needed for compatibility between different clang
# versions. Should be subsituted with a better solution
# in the future.
sed -i 's/^source_filename.*$//g' $TEMPFILE

log "Compiling"
clang "$@"

# adds .pex Section in objectfile and store IR in it 
objcopy --add-section .pex=$TEMPFILE \
    --set-section-flags .pex=noload,readonly $OUTPUT_FILE