# Setup Guide for our Proof of Concept

This assumes that you have installed `pex` with the according script, otherwise 
you have to adapt the paths accordingly.

1. Get the `GNU sed` source code: `git clone git://git.sv.gnu.org/sed`. This guide 
was written with version 4.8 in mind.
2. Go into the cloned folder and run `./bootstrap`
3. Run `./configure`
4. Open the `Makefile` in an editor and set `CC` to `pex` and `CPP` to `pex -E`
5. Run `make`
6. Run `mkdir sed`
7. Run `cp sed/*.o demo/ && cp lib/*.o demo/`
8. Run `pex *.o -o sed_poc` inside the `demo` folder
9. `sec_poc` is your portable exexcutable for `sed`

# Time Measurements
To measure the times referenced in our report about PEX we ran 
`time ( for i in {1..100}; do echo "1234" | sed 's/1/b/'; done )` and
`time ( for i in {1..100}; do echo "1234" | sed_poc 's/1/b/'; done )` inside the
`demo` folder.

