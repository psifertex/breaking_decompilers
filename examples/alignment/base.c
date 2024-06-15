#include <stdio.h>
#include <string.h>

#define PASSWORD "correct"

int main() {
    char input[100];

  /* This is it, just misalign! */
    __asm__( \
        "push rax;" \
        "mov rax, 0x03eb353535353535;" \
        ".byte 0xeb;" \
        ".byte 0xfc;" \
        "ret;" \
        "pop rax;" \
    );

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

