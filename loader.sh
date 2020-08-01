#!/bin/bash
# Uses env var PEX_USE_TAG to determine the bundle that should be run.
# If the env var is not set, use architecture triple as default
# set PEX_VERBOSE for pex logging

if [[ -z $PEX_PROFILE ]]; then
	PS4='+ $(date "+%s.%N")\011 '
	exec 3>&2 2>/tmp/pexprofile.$$.log
	echo "Logging times in /tmp/pexprofile.$$.log"
	set -x
fi

set -e
shopt -s globstar

function log {
	# TODO: extract into separate file
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

BASEDIR="$PWD"
TEMPDIR=$( mktemp -d )
log "Path to temp-folder: "$TEMPDIR""

# Find the number of the line beginning with #__ARCHIVE__BELOW__ with grep.
# Add one to account for newline.
TAR_START_POSITION=$(( $( grep -na '^#__ARCHIVE__BELOW__' "$0" | grep -o '^[0-9]*' ) + 1 ))

# Extract the tar archive.
tail -n+"$TAR_START_POSITION" "$0" | tar -x -C "$TEMPDIR"

if [[ -n "$PEX_USE_TAG" ]]; then
	# if the env variable PEX_USE_TAG is set, use corresponding bundle
	BUNDLE_NAME="$PEX_USE_TAG"
else
	# determine current cpu architecture
	BUNDLE_NAME=$( clang -dumpmachine )
fi
log "pex tag is set to $BUNDLE_NAME"

BUNDLE_PATH="$TEMPDIR"/"$BUNDLE_NAME"

# program needs to be compiled from IR
if [[ ! -e "$BUNDLE_PATH"/a.out ]]; then
	# create sub directory for current architecture and change into it
	mkdir -p "$BUNDLE_PATH"
	cd "$BUNDLE_PATH"

	# object files are not provided already
	log "generating object files from IR"

	# TODO: switch to realpath --relative-to?
	for file in ../IR/**/*.ll; do
		# strip first 6 characters to remove "../IR/"
		mkdir -p "$( dirname "${file:6}" )" 
		clang -c "$file" -o "${file:6}".o 
	done

	log "generating executable from object files"
	clang $( cat ../LINKER_FLAGS ) -o a.out ./**/*.o  

	log "re-building tar archive"
	cd ..
	tar -cf prog.tar -- *

	log "generating new portable executable"
	cd "$BASEDIR"
	head -n $(( "$TAR_START_POSITION" - 1)) "$0" | cat > "$TEMPDIR"/new_program.pex
	cat "$TEMPDIR"/prog.tar >> "$TEMPDIR"/new_program.pex

	log "substituting existing portable executable"
	mv "$TEMPDIR"/new_program.pex "$0"
	chmod a+x "$0"

	log "Added binary for tag $BUNDLE_NAME to $0"
fi

# execute program in subshell, using directory and
# name of the original call to .pex
log "executing binary for tag $ARCH"
( cd "$BASEDIR" && exec -a "$0" "$TEMPDIR"/"$BUNDLE_NAME"/a.out "$@" )

log "deleting tmp files"
rm -rf "$TEMPDIR"

if [[ -z $PEX_PROFILE ]]; then
	set +x
	exec 2>&3 3>&-
fi

log "done"
exit 0	

# After this line the archive is injected.
#__ARCHIVE__BELOW__