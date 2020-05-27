#include <stdio.h>

int
main (void)
{
  printf("hello, world\n");
  unsigned int a = sizeof(void*);
  printf("  sizeof void*: %u\n", a);

  return 0;
}
