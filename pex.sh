#!/bin/bash
#
#


function log {
	if [[ -n $PEX_VERBOSE ]]; then
		echo \[PEX-CC\] $1
	fi
}

O_SET=0
C_SET=0

argc=$#
argv=("$@")
for (( j=0; j<argc; j++ )); do
	if [[ "${argv[j]}" == -o ]]; then
		OUTPUT_FILE="${argv[j+1]}"
		O_SET=1
	fi
    if [[ "${argv[j]}" == -c ]]; then
		C_SET=1
	fi
done

# Case 1:
# kein -o kein -c
# chechen ob .c oder .o dateien
# IR für alle .c Files generieren und speichern
# TODO: nicht alle flags mit emit llvm -S kompatibel
# .c in .o kompilieren oder .o linken
# a.out generieren (clang call)
# alles in pex packen

# Case 2:
# -o, kein -c
# checken ob .c oder .o dateien
# IR für alle .c Files generieren und speichern
# TODO: nicht alle flags mit emit llvm -S kompatibel
# .c in .o kompilieren oder .o linken
# NAME.out generieren (clang call)
# alles in pex packen

# Case 3
# nur -c
# beliebig viele .c  
# generiere .o für jedes .c
# objcopy IR in jede .o
# namen bleiben gleich
#if [[ O_SET -eq 0 && C_SET -eq 1 ]]; then
    #for jede datei in $@:
    #    rufe compile_and_inject_ir auf
#fi

# takes three parameters
# arguments for compiler call 1
# name of source file 2
# assumes that its get called with -o flag
function compile_and_inject_ir {

    argc=$#
    argv=("$@")
    for (( j=0; j<argc; j++ )); do
    	if [[ "${argv[j]}" == -o ]]; then
    		OUTPUT_FILE="${argv[j+1]}"
    	fi
    done

    TEMPFILE=$(mktemp)

    log "Generating IR and storing it in $TEMPFILE"
    # later flag wins
    clang -emit-llvm -S $@ -o $TEMPFILE

    # Remove line starting with "source_filename".
    # Needed for compatibility between different clang
    # versions.
    sed -i 's/^source_filename.*$//g' $TEMPFILE

    log "Compiling"
    clang "$@"

    # adds .pex Section in objectfile and store IR in it 
    objcopy --add-section .pex=$TEMPFILE \
        --set-section-flags .pex=noload,readonly $OUTPUT_FILE
}

#function get_clang_flags {

#}

# Case 4
# -c -o
# so wie jetzt
# ein .c in ein NAME.o
# IR in .o injecten 
if [[ O_SET -eq 1 && C_SET -eq 1 ]]; then
        compile_and_inject_ir $@
fi