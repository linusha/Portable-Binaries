CC = ./pexcc.sh
LD = ./pexld.sh
LDFLAGS ?= -v

all: helloworld.pex

helloworld.pex: write.o hello.o
	$(LD) $(LDFLAGS) -o $@ $^

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

to-arm:
	scp helloworld.pex linus.hagemann@odroid-n2-01.fsoc.hpi.uni-potsdam.de:

to-x86:
	scp helloworld.pex linus.hagemann@cm1-c4n1.fsoc.hpi.uni-potsdam.de:

.PHONY: clean clean-dev
clean:
	rm -f *.o *.ll helloworld helloworld.pex a.out

clean-dev: clean
	rm -rf tar
