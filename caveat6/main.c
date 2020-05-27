#include <stdio.h>
#include <stdint.h>

int
main (void)
{
  printf("hello, world\n");

  uint32_t x;
  printf("  sizeof uint_32t: %zu\n", sizeof(uint32_t));
  uint64_t y;
  printf("  sizeof uint_64t: %zu\n", sizeof(uint64_t));

  return 0;
}

