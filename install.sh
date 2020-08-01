#!/bin/bash
# The destination of the PEX-Suite programs can be controlled via
# the PREFIX environment variable. 
# The loader script is always installed in /usr/share/
# unless changed directly in this script.

set -e

# Set this to the directory you want the pex suite in.
# This script assumes that the location is part of your PATH.
PREFIX=${PREFIX:-/usr/bin}

install ./pex.sh $PREFIX/pex
install ./pexmngr.sh $PREFIX/pexmngr

install ./loader.sh /usr/share/pex_loader.sh

echo "Successfully installed the PEX suite. Use it via pex and pexmngr."
echo "Have fun :)"
