#include "writer/write.h"
#include <stdio.h>
int main(int argc, char** argv ) {
   for (int i=0; i < argc; i++){
      printf("%s\n", argv[i]);
   }
   write("Hello World\n");
   return 0;
}

