CC = pex
LD = pex

all: helloworld.pex

helloworld.pex: src/write.o src/writer/write.o
	$(LD) $(LDFLAGS) -o $@ $^

%.o: src/%.c src/writer/%.c
	$(CC) $(CFLAGS) -c -o $@ $<

# HELPERS

list-cases:
	echo c-yes-o-no c-no-o-no c-no-o-yes make

c-yes-o-no:
	$(CC) -c src/write.c src/writer/write.c
	tree src # test: .o files exist and contain .pex section
	readelf --section-headers src/write.o
	echo =====================
	readelf --section-headers src/writer/write.o

c-no-o-no:
	$(CC) src/write.c src/writer/write.c
	tree # test: executable a.out file exists and is in pex format
	pexmngr a.out --tree

c-no-o-yes:
	$(CC) -o expected.pex src/write.c src/writer/write.c 
	tree # test: executable expected.pex exists and is in pex format 
	pexmngr expected.pex --tree

FILE=helloworld.pex
to-arm:
	scp $(FILE) $(USER)@odroid-n2-01.fsoc.hpi.uni-potsdam.de:

to-x86:
	scp $(FILE) $(USER)@cm1-c4n1.fsoc.hpi.uni-potsdam.de:

.PHONY: clean
clean:
	rm -f ./**/*.o ./**/*.ll helloworld.pex a.out ./src/writer/write.o expected.pex
	rm -rf tar
	
