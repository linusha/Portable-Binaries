CFLAGS ?= -g
CC = ./pexcc.sh
LD = ./pexld.sh

all: helloworld.pex

helloworld.pex: write.o hello.o
	$(LD) $(LDFLAGS) -o $@ $^

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

.PHONY: clean clean-dev
clean:
	rm -f *.o *.ll helloworld helloworld.pex a.out

clean-dev: clean
	rm -rf tar
