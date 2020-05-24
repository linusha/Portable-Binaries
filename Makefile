compile:
	clang hello/hello.c hello/write.c

clean: 
	rm -f a.out hello/write.c.*
