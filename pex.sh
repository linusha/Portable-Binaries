#!/bin/bash
# TODO: "complete" this list
# Not all clang flags are compatible with clang -emit-llvm -S
# These will break pex

set -e

function main {
    
    parse_flags_and_c_files "$@"
    parse_c_and_o_flag "$@"

    if [[ $E_SET -eq 1 ]]; then
    # If -E is set only the preprocessor is run.
        clang "$@"
        exit 0
    fi

    if [[ $C_SET -eq 0 ]]; then
        handle_case_c_not_set "$@"

    elif [[ $O_SET -eq 0 && $C_SET -eq 1 ]]; then
        handle_case_c_set_o_not_set "$@"

    elif [[ $O_SET -eq 1 && $C_SET -eq 1 ]]; then
        handle_case_c_set_o_set "$@"
    fi
}

function parse_flags_and_c_files {
    # Separates .c files and flags into respective variables.
    # FLAGS and C_FILES are then available in the global scope.
    # Parameters:
    # all parameters of a clang call
    # Return Value: 
    # none

    FLAGS=()
    C_FILES=()

    for arg in "$@"; do
        if [[ $arg =~ .*\.c ]]; then
            C_FILES+=( "$arg" )
        else
            FLAGS+=( "$arg" )
        fi
    done
}

function parse_c_and_o_flag {
    # Check whether -c, -E and -o are present in the arguments.
    # C_SET, O_SET, E_SET (and OUTPUT_FILE) are then available in the global scope.
    # Parameters:
    # all parameters of a clang call
    # Return Value: 
    # none

    O_SET=0
    C_SET=0
    E_SET=0

    local argc=$#
    local argv=("$@")
    for (( j=0; j<argc; j++ )); do
    	if [[ "${argv[j]}" == -o ]]; then
    		OUTPUT_FILE="${argv[j+1]}"
    		O_SET=1
    	fi
        if [[ "${argv[j]}" == -c ]]; then
    		C_SET=1
    	fi
        if [[ "${argv[j]}" == -E ]]; then
    		E_SET=1
    	fi
    done
}

function handle_case_c_not_set {
    # If the -c flag is not set then the input files
    # get compiled to one executable.
    # There are two distinct cases:
    # 1. input files are .c files
    # 2. input files are .o files
    # Parameters:
    # all parameters of a clang call
    # Return Value: 
    # none

    # Uses ending of the last file to determine
    # whether to compile from .o files or .c files.
    for arg in "$@"; do
        if [[ $arg =~ .*\.c ]]; then
            local LASTFILE=c
        elif [[ $arg =~ .*\.o ]]; then
            local LASTFILE=o
        fi
    done

    local TEMPDIR
    TEMPDIR=$( mktemp -d )
    log "tar archive gets built in $TEMPDIR"

    if [[ -z $PEX_STORE_AS ]]; then
        # Use target triple as default bundle name.
        PEX_STORE_AS=$(clang -dumpmachine)
    fi

    if [[ $LASTFILE == c ]]; then
        # Persist linker flags in .pex to reuse them in recompilations.
        touch "$TEMPDIR"/LINKER_FLAGS
        for flag in "${FLAGS[@]}"; do
            echo -n "$flag " >> "$TEMPDIR"/LINKER_FLAGS
        done
        

        # Compile IR for each .c File to persist in .pex.
        for file in "${C_FILES[@]}"; do
            mkdir -p "$( dirname "$TEMPDIR"/IR/"$file" )"
            clang -emit-llvm -S "${FLAGS[@]}" -o "$TEMPDIR"/IR/"$file".ll "$file" 
        done
        
        # Compile actual executable.
        mkdir -p "$( dirname "$TEMPDIR"/"$PEX_STORE_AS"/a.out )"
        clang "${FLAGS[@]}" -o "$TEMPDIR"/"$PEX_STORE_AS"/a.out "${C_FILES[@]}"

    elif [[ "$LASTFILE" == o ]]; then
        for arg in "$@"; do
            # Find all .o files in input command that contain a .pex section.
            # We assume that these are the files that are not part of any flag.
            # Persist extracted IR and .o files in .pex.
            if [[ "$arg" =~ ^.*\.o$ && $( contains_pex_section "$arg" ) -eq 1 ]]; then
                mkdir -p "$( dirname "$TEMPDIR"/"$PEX_STORE_AS"/"$arg" )"
                mkdir -p "$( dirname "$TEMPDIR"/IR/"$arg" )"
                objcopy --dump-section .pex="$TEMPDIR"/IR/"$arg".ll "$arg"
                cp "$arg" "$TEMPDIR"/"$PEX_STORE_AS"/"$arg"
            else
                # Everything that is not an input file is a flag.
                echo -n "$arg " >> "$TEMPDIR"/LINKER_FLAGS
            fi
        done
        # Compile actual executable.
        clang "$@" -o "$TEMPDIR"/"$PEX_STORE_AS"/a.out
    fi

    create_pex_from_folders "$TEMPDIR" "${OUTPUT_FILE:-a.out}"

    rm -r "$TEMPDIR"
}

function handle_case_c_set_o_not_set {
    # If the -c flag is set and -o is not set
    # then the input files are compiled into object files.
    # This allows to compile multiple .c files at once.
    # The naming scheme is name.c -> name.o.
    # Parameters:
    # all parameters of a clang call
    # Return Value: 
    # none

    for file in "${C_FILES[@]}"; do
    	    compile_and_inject_ir "${FLAGS[@]}" -o "${file//.c/.o}" "$file"
    done
}

function handle_case_c_set_o_set {
    # If the -c and -o flags are set, the input .c file
    # is compiled into an object file with the given name.
    # Parameters:
    # all parameters of a clang call
    # Return Value: 
    # none
    
    compile_and_inject_ir "$@"
}

function compile_and_inject_ir {
    # Compiles a single .c file to an object file with IR added to .pex section.
    # Parameters:
    # The argument array has to contain all clang flags and the single .c File.
    # -o has to be set.
    # Return Value:
    # none

    # Determine output filename from compiler arguments.
    local argc=$#
    local argv=("$@")
    for (( j=0; j<argc; j++ )); do
    	if [[ "${argv[j]}" == -o ]]; then
    		local OUTPUT_FILE="${argv[j+1]}"
    	fi
    done

    local TEMPFILE
    TEMPFILE=$( mktemp )
    log "Generating IR for "$OUTPUT_FILE" and storing it in "$TEMPFILE""

    # Overwrite original -o flag.
    # This compile step generates the IR.
    clang -emit-llvm -S "$@" -o "$TEMPFILE"
    make_compatible "$TEMPFILE"

    log "Compiling"
    # This compile step generates the object file.
    clang "$@"

    # Adds .pex Section in objectfile and store IR in it.
    objcopy --add-section .pex="$TEMPFILE" \
        --set-section-flags .pex=noload,readonly "$OUTPUT_FILE"

    rm "$TEMPFILE"
}

function contains_pex_section {
    # Determines whether an object file contains a .pex section.
    # Parameters:
    # 1 - name of the objectfile to check
    # Return Value:
    # 1 - if there is a .pex section
    # 0 - otherwise

    local SECTION_HEADERS
    SECTION_HEADERS=$( readelf --section-headers "$1" )
    local PEX_SECTION
    PEX_SECTION=$( echo "$SECTION_HEADERS" | grep '\.pex' )
    if [[ -z "$PEX_SECTION" ]]; then
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

    sed -i 's/^source_filename.*$//g' "$1"
}

function create_pex_from_folders {
    # Creates a PEX File for the given directory.
    # Parameters:
    # 1 - folder to pack into PEX
    # 2 - name of the PEX file
    # Return Value:
    # none

    log "creating tar archive"
    local TARFILE
    TARFILE=$( mktemp )
    log "Path to generated tar archive: "$TEMPFILE""
    tar -cf "$TARFILE" -C "$1" .
    
    # The script that will later be bundled with the tar archive.
    local LOADER_SCRIPT
    LOADER_SCRIPT=$( cat /usr/share/pex_loader.sh )
    
    log "merging loader script and tar archive to PEX File"
    echo "$LOADER_SCRIPT" > "$2"
    cat "$TARFILE" >> "$2"
    
    # Make loader script executable.
    chmod a+x "$2"

    rm "$TARFILE"
}

function log {
    # Logging function for PEX.
    # Activate output by setting the environment
    # variable PEX_VERBOSE when calling pex.
    # Parameters:
    # 1 - string to log
    # Return Value:
    # none

	if [[ -n "$PEX_VERBOSE" ]]; then
		echo \[PEX\] "$1"
	fi
}

# Call main logic.
main "$@"