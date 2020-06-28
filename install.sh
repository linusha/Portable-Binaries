#!/bin/bash
# assumes that /usr/bin is in PATH
set -e
DIR=$( dirname $( realpath $0 ) )

cp -sf $DIR/pexcc.sh /usr/bin/pexcc
cp -sf $DIR/pexld.sh /usr/bin/pexld
cp -sf $DIR/pexmngr.sh /usr/bin/pexmngr
cp -sf $DIR/loader.sh /usr/bin/pexloader

echo "Successfully installed the PEX suite. Use it via pexcc, pexld, pexmngr."
echo "Have fun :)"