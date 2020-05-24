#!/bin/bash

OUT_DIR=.builder
rm -rf $OUT_DIR
mkdir -p $OUT_DIR

clang -emit-llvm -S hello/hello.c hello/write.c
mv hello.ll write.ll $OUT_DIR

tar -cvf prog.tar "$OUT_DIR"/*
rm -r $OUT_DIR
