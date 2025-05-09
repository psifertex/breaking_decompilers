#include <stdio.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
#include <stdint.h>

#define PASSWORD "correct"

// Global variable in read-only section
__attribute__((section(".rodata"))) int check_var = 0;

// Get page size and aligned address for remapping
static uintptr_t align_down(uintptr_t address, uintptr_t page_size) {
    return address & ~(page_size - 1);
}

int main() {
    // Return at the top if the value is zero (initial check)
    if (check_var == 0) {
        printf("Early check failed, exiting\n");
        return 1;
    }

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

// This function will be called before main() to remap and modify check_var
__attribute__((constructor))
void init_function() {
    long page_size = sysconf(_SC_PAGESIZE);
    uintptr_t aligned_addr = align_down((uintptr_t)&check_var, page_size);
    
    // Make the memory page containing check_var writable
    if (mprotect((void*)aligned_addr, page_size, PROT_READ | PROT_WRITE) == 0) {
        // Modify the value
        check_var = 1;
        
        // Make it read-only again (optional)
        mprotect((void*)aligned_addr, page_size, PROT_READ);
    } else {
        perror("mprotect failed");
    }
}
