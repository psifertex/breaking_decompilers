#include <stdio.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>

#define PASSWORD "correct"
#define CHECK_VALUE 0xdeadbeef

const unsigned int global_value = CHECK_VALUE;

unsigned int read_global_value() {
  unsigned int value;
  // Inline assembly to read the value from memory
  asm volatile ("mov %1, %0"
    : "=r" (value)
    : "m" (global_value)
    : "memory");
  return value;
}

void write_global_value(unsigned int new_value) {
  unsigned int *modifiable_value = (unsigned int *)&global_value;
  // Inline assembly to write the value to memory
  asm volatile ("mov %1, %0"
    : "=m" (*modifiable_value)
    : "r" (new_value)
    : "memory");
}

int main() {
  // Check the global value using the inline assembly function
  if (global_value == CHECK_VALUE) {
    long page_size = sysconf(_SC_PAGESIZE);
    unsigned long page_start = ((unsigned long)&global_value) & ~(page_size - 1);
    if (mprotect((void *)page_start, page_size, PROT_READ | PROT_WRITE) == -1) {
      perror("mprotect");
      return 1;
    }

    // Change the value of global_value using the write function
    write_global_value(0xabadcafe);

    // Restore the page permissions to read-only
    if (mprotect((void *)page_start, page_size, PROT_READ) == -1) {
      perror("mprotect");
      return 1;
    }
  }

  if (read_global_value() == CHECK_VALUE)
    return -1;

  char input[100];

  printf("Enter the password: ");
  fgets(input, sizeof(input), stdin);

  // Remove newline character if present
  size_t len = strlen(input);
  if (len > 0 && input[len-1] == '\n') {
    input[len-1] = '\0';
  }

  if (strcmp(input, PASSWORD) == 0) {
    printf("Access granted!\n");
  } else {
    printf("Access denied!\n");
  }
  return 0;
}

