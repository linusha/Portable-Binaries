![License: MIT](https://img.shields.io/badge/license-MIT-green)

# Description

Portable executable files (PEX) are executables that can be moved between different ISA's and CPU feature sets. PEX files are built around the LLVM intermediate representation (IR). The PEX-Suite consists of the following programs:

- `pex` acts as a wrapper around the clang compiler and linker. It can be used to generate object files that contain their own IR and PEX's.
- `pexmngr` is a convenience program that allows to inspect and manipulate existing PEX files.

The PEX-Suite is only tested/developed for the C programming language. However, most of the code should be easy to port to other languages that are supported by LLVM.  

# Installation

1. Clone the repository.
2. Execute the install script: `./install.sh`.

# Basic Usage

## Executing a PEX file

Execute it just like any other executable (`./example.pex arg1 arg2`). The new part - move it between your favorite ARM and x86 machines and the program still works (hopefully)! 

**Environment Variables**

If you want to run the specific tag `NAME` from a PEX file use the environment variable `PEX_USE_TAG`: `PEX_USE_TAG=NAME ./example.pex arg1 arg2`.

For verbose logging from the PEX internals, set the environment variable `PEX_VERBOSE` like `PEX_VERBOSE=1 ../example.pex arg1 arg2`.

## Building a PEX file

`pex` wraps around the `clang` compiler and linker. It can be used as a drop-in replacement in your `Makefile`. Flags are passed to `clang`.

**Example Makefile**

```Makefile
CC = pex
LD = pex

all: example.pex

example.pex: example.o
	$(LD) $(LDFLAGS) -o $@ $^

example.o: example.c
	$(CC) $(CFLAGS) -c -o $@ $<
```
A small example program with a corresponding Makefile can be found in this repository under `src/`.

**Environment Variables**

- For logging from `pex` set the environment variable `PEX_VERBOSE` like `PEX_VERBOSE=1 make`.
- If you want to tag the .o file in the PEX as `NAME` you can do so using another environment variable like `PEX_STORE_AS=NAME make`.

## Managing PEX files

Call the PEX manager: `pexmngr PEX OPERATION`.
The following `OPERATIONS` are supported:

- `--help` shows a help message. 
- `--ls` lists the contents of the PEX file.
- `--tree` like ls, but depends on `tree` for the output for prettier formatting.
- `--extract [NAME]` extracts the contents of the PEX file into a folder `NAME`. `NAME` defaults to `tar`.
- `--rm [TAG]` removes a set of .o files stored under `TAG` from the PEX file. `TAG` defaults to the current architecture triple.
- `--merge PEX_2` merges the contents of `PEX_2` into `PEX`. *Careful: This assumes that the tags inside the two files are disjoint!* 

# Dependencies

- bash
- clang
- optional: tree

# Known Pitfalls

- When linking multiple object files into one PEX your final build step has to be a single call to `pex` that gets ALL object files as arguments. `.a`-Libraries and multi-step linking are not supported.
- You cannot move a PEX between systems that do not have the same number of bits (e.g. 32bit and 64bit).
- Mismatching clang versions on origin and target can cause issues. For example clang version 3.8 cannot handle the ll files that are created by clang 6.0. The reason is that clang 6.0 adds a line with the `source_filename` to the ll file. 

# License

MIT.

No animals were harmed in the making of this program.