#!/bin/bash
# This is helper program to interact with pex files in order to:
# - extract their tar archive,
# - list their contents (ls or tree style),
# - remove a bundle,
# - merge two .pex files for the same program 
#   (assumes disjunct bundle names).

set -e

function print_usage {
	echo
	echo "Possible arguments: "
    echo "    First argument must be the PEX file you want to work with!"
    echo "    You have to specify exactly one file and operation."
	echo "    --extract NAME Extract tar archive to directory NAME"
	echo "    defaults to ./tar"
	echo "    --merge NAME2 adds the content of pex file NAME2 to PEX"
	echo "    --ls list the content of PEX"
    echo "    --tree list the content of PEX using tree"
    echo "    --rm [TAG] delete the TAG bundle from the PEX"
    echo "    defaults to current architecture-triple"
    echo "    --help Display this help message"
	echo
}

function cleanup {
    # Delete Tempfiles.
    rm -rf "$TEMPDIR"
}

# Called without arguments or with --help.
if [[ -z $1 || $1 == "--help" ]]; then
    print_usage
    exit 0
fi

# Called with only one argument.
if [[ -z $2 ]]; then
    echo "You have to provide filename and operation."
    echo "See pexmngr --help."
    exit 1
fi

PEXFILE="$1"
OPERATION="$2"
ARGUMENT="$3"

TAR_START_POSITION=$(( $( grep -na '^#__ARCHIVE__BELOW__' "$PEXFILE" | grep -o '^[0-9]*' ) + 1 ))


if [[ "$OPERATION" == "--ls" ]]; then
    tail -n+"$TAR_START_POSITION" "$PEXFILE" | tar --list
    exit 0
fi

# Extract tar archive to TEMPDIR.
TEMPDIR=$(mktemp -d)
tail -n+"$TAR_START_POSITION" "$PEXFILE" | tar -x -C "$TEMPDIR"

if [[ "$OPERATION" == "--tree" ]]; then
    cd "$TEMPDIR"
    tree .
fi

if [[ "$OPERATION" == "--extract" ]]; then
    if [[ -z "$ARGUMENT" ]]; then
        ARGUMENT="tar"
    fi
    mkdir -p "$ARGUMENT"
    # Archive is already extracted, copy contents outside TEMPDIR.
    cp -r "$TEMPDIR"/* "$ARGUMENT"
    echo "Contents in: $ARGUMENT"
fi

if [[ "$OPERATION" == "--merge" ]]; then
    if [[ -z "$ARGUMENT" ]]; then
        echo "You have to provide a PEX to merge with."
        cleanup
        exit 1
    fi
    # Extract contents from second pex into TEMPDIR.
    "$0" "$ARGUMENT" --extract "$TEMPDIR"
    BASEDIR=$(pwd)
    cd "$TEMPDIR"
    # Create new tar archive with merged contents.
    tar -cf prog.tar -- *
    cd "$BASEDIR"
    # Build new .pex file.
    head -n $(( "$TAR_START_POSITION" - 1)) "$PEXFILE" | cat > "$TEMPDIR"/new_program.pex
    cat "$TEMPDIR"/prog.tar >> "$TEMPDIR"/new_program.pex
    # Replace original file with new pex.
    mv "$TEMPDIR"/new_program.pex "$PEXFILE"
    # TODO: Change permission as needed.
	# Good solution would be to save and reapply initial permissions.
    chmod a+x "$PEXFILE"
fi

if [[ "$OPERATION" == "--rm" ]]; then
    if [[ -z "$ARGUMENT" ]]; then
    # Use current architecture-triple as default.
        ARGUMENT=$( clang -dumpmachine )
    fi
    BASEDIR=$(pwd)
    cd "$TEMPDIR"
    # Remove specified bundle.
    rm -rf "$ARGUMENT"
    # Build new .pex file.
    tar -cf prog.tar -- *
    cd "$BASEDIR"
    head -n $(( "$TAR_START_POSITION" - 1)) "$PEXFILE" | cat > "$TEMPDIR"/new_program.pex
    cat "$TEMPDIR"/prog.tar >> "$TEMPDIR"/new_program.pex
    mv "$TEMPDIR"/new_program.pex "$PEXFILE"
    # TODO: Change permission as needed.
    chmod a+x "$PEXFILE"
fi

cleanup
exit 0