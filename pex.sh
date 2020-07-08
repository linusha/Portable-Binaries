#!/bin/bash
#
#

function main {
    FLAGS=()
    FILES=()

    for arg in $@; do
        if [[ $arg =~ .*\.c ]]; then
            FILES+=( "$arg" )
        else
            FLAGS+=( "$arg" )
        fi
    done

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
        log "tar archive gets built in $TEMPDIR"
        if [[ -z $PEX_STORE_AS ]]; then
            PEX_STORE_AS=$(clang -dumpmachine)
        fi


        if [[ $LASTFILE == c ]]; then
            touch $TEMPDIR/LINKER_FLAGS
            for file in ${FILES[@]}; do
                mkdir -p $( dirname $TEMPDIR/IR/$file )
                clang -emit-llvm -S ${FLAGS[@]} -o $TEMPDIR/IR/$file.ll $file 
            done
            for flag in ${FLAGS[@]}; do
                echo -n "$flag " >> $TEMPDIR/LINKER_FLAGS
            done

            mkdir -p $( dirname $TEMPDIR/$PEX_STORE_AS/a.out )
            clang ${FLAGS[@]} -o $TEMPDIR/$PEX_STORE_AS/a.out ${FILES[@]}

            create_pex_from_folders $TEMPDIR "${OUTPUT_FILE:-a.out}"

        # we compile from object files, just as the linker always did
        elif [[ $LASTFILE == o ]]; then
            for arg in "$@"; do
                # find all .o files in input command that contain a .pex section
                # we assume that these are the files that are not part of any flag
                if [[ $arg =~ ^.*\.o$ && $( contains_pex_section $arg ) -eq 1 ]]; then
                    mkdir -p $( dirname $TEMPDIR/$PEX_STORE_AS/$arg )
                    mkdir -p $( dirname $TEMPDIR/IR/$arg )
                    objcopy --dump-section .pex="$TEMPDIR"/IR/"$arg".ll $arg
                    cp "$arg" "$TEMPDIR"/"$PEX_STORE_AS"/"$arg"
                else
                    echo -n "$arg " >> $TEMPDIR/LINKER_FLAGS
                fi
            done
            clang $@ -o "$TEMPDIR"/"$PEX_STORE_AS"/a.out
            create_pex_from_folders $TEMPDIR "${OUTPUT_FILE:-a.out}"
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
}

function compile_and_inject_ir {
    # Compiles a single .c file to an object file with IR added to .pex section 
    # Parameters:
    # The argument array has to contain all clang flags and the single .c File
    # -o has to be set
    # Return Value:
    # none

    # determine output filename from compiler arguments
    argc=$#
    argv=("$@")
    for (( j=0; j<argc; j++ )); do
    	if [[ "${argv[j]}" == -o ]]; then
    		OUTPUT_FILE="${argv[j+1]}"
    	fi
    done

    log "Generating IR and storing it in $TEMPFILE"
    TEMPFILE=$(mktemp)
    # overwrite original -o flag
    # this compile step generates the IR
    clang -emit-llvm -S $@ -o $TEMPFILE
    make_compatible $TEMPFILE

    log "Compiling"
    # this compile step generates the object file
    clang "$@"

    # adds .pex Section in objectfile and store IR in it 
    objcopy --add-section .pex=$TEMPFILE \
        --set-section-flags .pex=noload,readonly $OUTPUT_FILE
}

function log {
    # Logging function for PEX.
    # Activate output by setting the environment
    # variable PEX_VERBOSE when calling pex 
    # Parameters:
    # 1 - string to log
    # Return Value:
    # none

	if [[ -n $PEX_VERBOSE ]]; then
		echo \[PEX-CC\] $1
	fi
}

function create_pex_from_folders {
    # Creates a PEX File for the given directory.
    # Parameters:
    # 1 - folder to pack into PEX
    # 2 - name of the PEX file
    # Return Value:
    # none

    log "creating tar archive"
    TARFILE=$( mktemp )
    tar -cf $TARFILE -C $1 .
    
    # The script that will later be bundled with the tar archive
    LOADER_SCRIPT=$(cat /usr/share/pex_loader.sh)
    
    log "merging loader script and tar archive to PEX File"
    echo "$LOADER_SCRIPT" > $2
    cat $TARFILE >> $2
    
    # make loader script executable
    chmod a+x $2
}

function contains_pex_section {
    # Determines whether an object file contains a .pex section.
    # Parameters:
    # 1 - name of the objectfile to check
    # Return Value:
    # 1 - if there is a .pex section
    # 0 - otherwise

    SECTION_HEADERS=$( readelf --section-headers $1 )
    PEX_SECTION=$( echo $SECTION_HEADERS | grep '\.pex' )
    if [[ -z PEX_SECTION ]]; then
        echo 0
    else
        echo 1
    fi
}

function make_compatible {
    # Remove line starting with "source_filename" in a file.
    # Needed for compatibility between different clang versions.
    # Parameters:
    # 1 - name of the file
    # Return Value: 
    # none

    sed -i 's/^source_filename.*$//g' $1
}

# call main logic
main $@