# Makefile for minimal example provided with PEX Code.
CC = pex
LD = pex

all: helloworld.pex

helloworld.pex: src/write.o src/writer/write.o
	$(LD) $(LDFLAGS) -o $@ $^

%.o: src/%.c src/writer/%.c
	$(CC) $(CFLAGS) -c -o $@ $<

# Only for testing purposes, remove in production.
FILE=helloworld.pex
to-arm:
	scp $(FILE) $(USER)@odroid-n2-01.fsoc.hpi.uni-potsdam.de:

to-x86:
	scp $(FILE) $(USER)@cm1-c4n1.fsoc.hpi.uni-potsdam.de:

.PHONY: clean
clean:
	rm -f ./**/*.o ./**/*.ll helloworld.pex a.out ./src/writer/write.o
	rm -rf tar