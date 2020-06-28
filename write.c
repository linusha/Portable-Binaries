#include "writer/write.h"
#include <stdio.h>
#include <unistd.h>
int main(int argc, char** argv ) {
   char buff[FILENAME_MAX];
   getcwd( buff, FILENAME_MAX );
   printf("Current working dir: %s\n", buff);
   printf("%i\n", argc);
   printf("---\n");
   for (int i=0; i < argc; i++){
      printf("%s\n", argv[i]);
   }
   gib_output("Hello World\n");
   return 0;
}

