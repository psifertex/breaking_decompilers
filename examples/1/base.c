#include <stdio.h>
#include <string.h>

#define PASSWORD "correct"


void check_password(const char *input) {
    if (strcmp(input, PASSWORD) == 0) {
        printf("Access granted!\n");
    } else {
        printf("Access denied!\n");
    }
}

int main() {
    char input[100];

    __asm__( \
        "push rax;" \
        "mov rax, 0x03eb000000000000;" \
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

    check_password(input);
    return 0;
}

