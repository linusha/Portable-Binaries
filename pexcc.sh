#!/bin/bash
# 
# This is a wrapper around the clang compiler that emits modified object files.
# In the output files is a .pex ELF-Section that contains the LLVM-IR.

set -e

########## HELPERS ##########

function log {
	if [[ -n $PEX_VERBOSE ]]; then
		echo \[PEX-CC\] $1
	fi
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

# extract output file name
argc=$#
argv=("$@")
for (( j=0; j<argc; j++ )); do
	if [[ "${argv[j]}" == -o ]]; then
		OUTPUT_FILE="${argv[j+1]}"
		break
	fi
done

for last; do true; done
if [[ -z $OUTPUT_FILE ]]; then 
	OUTPUT_FILE=$( echo $last | grep 's/\.c/\.o/' )
fi

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