#include "stdio.h"
#include "stdbool.h"

#define CHUNK_SIZE 4096

int main() {
  FILE *file = fopen("/tmp/data.bin", "r");

  const char *chunk_buf[CHUNK_SIZE] = {0};

  while (true) {
    int n = fread(chunk_buf, 1, CHUNK_SIZE, file);
    if (n == 0) return 0;
    while (n > 0) {
      n -= fwrite(chunk_buf, 1, n, stdout);
    }
  }
}
