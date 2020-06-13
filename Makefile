CFLAGS ?= -g
CC = ./pexcc.sh

all: helloworld

helloworld: write.o hello.o
	clang $(LDFLAGS) -o $@ $^

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

.PHONY: clean
clean:
	rm -f *.o
	rm -f *.ll
	rm helloworld