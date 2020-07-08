CC = ./pex.sh
LD = ./pex.sh

all: helloworld.pex

helloworld.pex: src/write.o src/writer/write.o
	$(LD) $(LDFLAGS) -o $@ $^

%.o: src/%.c src/writer/%.c
	$(CC) $(CFLAGS) -c -o $@ $<

to-arm:
	scp helloworld.pex linus.hagemann@odroid-n2-01.fsoc.hpi.uni-potsdam.de:

to-x86:
	scp helloworld.pex linus.hagemann@cm1-c4n1.fsoc.hpi.uni-potsdam.de:

.PHONY: clean
clean:
	rm -f ./**/*.o ./**/*.ll helloworld.pex a.out ./src/writer/write.o
	rm -rf tar
	
