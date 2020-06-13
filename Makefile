CFLAGS ?= -g
CC = ./pexcc.sh
LD = ./pexld.sh

all: helloworld.pex

helloworld.pex: write.o hello.o
	$(LD) $(LDFLAGS) -o $@ $^

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

.PHONY: clean
clean:
	rm -f *.o
	rm -f *.ll
	rm -f helloworld
	rm -f helloworld.pex
	rm -rf tar