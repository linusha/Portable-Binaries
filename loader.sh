#!/bin/bash

TAR=prog.tar
OUT_DIR=.loader
mkdir -p $OUT_DIR

tar -xvf $TAR

clang -c .builder/*.ll
clang ./*.o
 
