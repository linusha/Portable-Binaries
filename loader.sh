#!/bin/bash
# Uses environment variable PEX_USE_TAG to determine the bundle that should be run.
# If the variable is not set, use architecture triple as default.
# Set PEX_VERBOSE for pex logging.

set -e
shopt -s globstar

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

BASEDIR="$PWD"
TEMPDIR=$( mktemp -d )
log "Path to temp folder: $TEMPDIR"

# Find the number of the line beginning with #__ARCHIVE__BELOW__.
# Add one to account for newline.
TAR_START_POSITION=$(( $( grep -na '^#__ARCHIVE__BELOW__' "$0" | grep -o '^[0-9]*' ) + 1 ))

# Extract the tar archive.
tail -n+"$TAR_START_POSITION" "$0" | tar -x -C "$TEMPDIR"

if [[ -n "$PEX_USE_TAG" ]]; then
	# If the env variable PEX_USE_TAG is set, use corresponding bundle.
	BUNDLE_NAME="$PEX_USE_TAG"
else
	# Determine current CPU architecture.
	BUNDLE_NAME=$( clang -dumpmachine )
fi
log "Pex tag is set to $BUNDLE_NAME"

BUNDLE_PATH="$TEMPDIR"/"$BUNDLE_NAME"

# Program needs to be compiled from IR, because
# no bundle for current architecture is found.
if [[ ! -e "$BUNDLE_PATH"/a.out ]]; then
	# Create sub directory for current architecture and change into it.
	mkdir -p "$BUNDLE_PATH"
	cd "$BUNDLE_PATH"

	log "Generating object files from IR"

	# TODO: Switch to realpath --relative-to?
	for file in ../IR/**/*.ll; do
		# Strip first 6 characters to remove "../IR/".
		mkdir -p "$( dirname "${file:6}" )" 
		clang -c "$file" -o "${file:6}".o 
	done

	log "Generating executable from object files"
	# Use saved linker flags for rebuild.
	clang $( cat ../LINKER_FLAGS ) -o a.out ./**/*.o  

	log "Re-building tar archive"
	cd ..
	tar -cf prog.tar -- *

	log "Generating new PEX"
	cd "$BASEDIR"
	head -n $(( "$TAR_START_POSITION" - 1)) "$0" | cat > "$TEMPDIR"/new_program.pex
	cat "$TEMPDIR"/prog.tar >> "$TEMPDIR"/new_program.pex

	log "Substituting existing portable executable"
	mv "$TEMPDIR"/new_program.pex "$0"
	# TODO: Change permission as needed.
	# Good solution would be to save and reapply initial permissions.
	chmod a+x "$0"

	log "Added binary for tag $BUNDLE_NAME to $0"
fi

# Execute program in subshell.
# Set correct working directory and name of the called program (.pex).
log "Executing binary for tag $BUNDLE_NAME"
( cd "$BASEDIR" && exec -a "$0" "$TEMPDIR"/"$BUNDLE_NAME"/a.out "$@" )

log "Deleting tmp files"
rm -rf "$TEMPDIR"

log "Done"
exit 0	

# After this line the archive is injected.
#__ARCHIVE__BELOW__