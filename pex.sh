#!/bin/bash
#
#

FLAGS=()
FILES=()

for arg in $@; do
    if [[ $arg =~ .*\.c ]]; then
        FILES+=( "$arg" )
    else
        FLAGS+=( "$arg" )
    fi
done

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

function log {
	if [[ -n $PEX_VERBOSE ]]; then
		echo \[PEX-CC\] $1
	fi
}

# parameters:
# 1 - folder to pex
# 2 - output filename
function create_pex_from_folders {
    # linking for current arch in future .pex
    BASEDIR=$( pwd )
    cd "$1"
    log "creating tar archive with the .ll files"
    tar -cf prog.tar *
    cd $BASEDIR
    
    # The script that will later be bundled with the tar archive
    LOADER_SCRIPT=$(cat /usr/share/pex_loader.sh)
    
    log "merging loader script and tar archive to portable executable"
    echo "$LOADER_SCRIPT" > $2
    cat "$1"/prog.tar >> $2
    
    # make loader script executable
    # TODO: Maybe make this only executable for the current user?
    ## currently not possible, since we need to use sudo in fsoc lab
    chmod a+x $2
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
# nicht alle flags mit emit llvm -S kompatibel
# .c in .o kompilieren oder .o linken
# a.out generieren (clang call)
# alles in pex packen
if [[ C_SET -eq 0 ]]; then

    # check whether we have to compile from scratch or from object files
    for arg in $@; do
	    if [[ $arg =~ .*\.c ]]; then
            LASTFILE=c
	    elif [[ $arg =~ .*\.o ]]; then
            LASTFILE=o
        fi
    done

    TEMPDIR=$(mktemp -d)
    if [[ -z $PEX_STORE_AS ]]; then
        PEX_STORE_AS=$(clang -dumpmachine)
    fi


    if [[ $LASTFILE == c ]]; then
        echo $TEMPDIR
        touch $TEMPDIR/LINKER_FILES $TEMPDIR/LINKER_FLAGS
        for file in ${FILES[@]}; do
            mkdir -p $( dirname $TEMPDIR/IR/$file )
            clang -emit-llvm -S ${FLAGS[@]} -o $TEMPDIR/IR/$file.ll $file 
            echo -n "$file " >> $TEMPDIR/LINKER_FILES
        done
        for flag in ${FLAGS[@]}; do
            echo -n "$flag " >> $TEMPDIR/LINKER_FLAGS
        done

        mkdir -p $( dirname $TEMPDIR/$PEX_STORE_AS/a.out )
        clang ${FLAGS[@]} -o $TEMPDIR/$PEX_STORE_AS/a.out ${FILES[@]}

        create_pex_from_folders $TEMPDIR "${OUTPUT_FILE:-a.out}"

    # we compile from object files, just as the linker always did
    elif [[ $LASTFILE == o ]]; then
        pexld $@
    fi
fi

# Case 3
# nur -c
# beliebig viele .c  
# generiere .o für jedes .c
# objcopy IR in jede .o
# namen bleiben gleich
if [[ O_SET -eq 0 && C_SET -eq 1 ]]; then

    for file in ${FILES[@]}; do
	    compile_and_inject_ir ${FLAGS[@]} -o $( echo "$file" | sed 's/\.c/\.o/' ) "$file"
    done 
fi

# Case 4
# -c -o
# so wie jetzt
# ein .c in ein NAME.o
# IR in .o injecten 
if [[ O_SET -eq 1 && C_SET -eq 1 ]]; then
        compile_and_inject_ir $@
fi