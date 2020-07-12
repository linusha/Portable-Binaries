#!/bin/bash

# set to directorz you want the pex suite in
# this script assumes that the location is part of your PATH
PREFIX=${PREFIX:-/usr/bin}
set -e
DIR=$( dirname $( realpath $0 ) )

cp -sf $DIR/pex.sh $PREFIX/pex
cp -sf $DIR/pexmngr.sh $PREFIX/pexmngr

cp -sf $DIR/loader.sh /usr/share/pex_loader.sh

echo "Successfully set up the Dev-Env for PEX suite. Use it via pex and pexmngr."
echo "Have fun :)"
