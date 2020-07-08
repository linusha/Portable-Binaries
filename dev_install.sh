#!/bin/bash

# set to directorz you want the pex suite in
# this script assumes that the location is part of your PATH
INSTDIR=/usr/bin
set -e
DIR=$( dirname $( realpath $0 ) )

cp -sf $DIR/pex.sh $INSTDIR/pex
cp -sf $DIR/pexcc.sh $INSTDIR/pexcc
cp -sf $DIR/pexld.sh $INSTDIR/pexld
cp -sf $DIR/pexmngr.sh $INSTDIR/pexmngr

cp -sf $DIR/loader.sh /usr/share/pex_loader.sh

echo "Successfully installed the PEX suite. Use it via pexcc, pexld, pexmngr."
echo "Have fun :)"
