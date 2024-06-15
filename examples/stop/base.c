#include <stdio.h>
#include <string.h>

#define PASSWORD "correct"

void stop() {
  printf("This just makes tools stop when you rename it \"exit\"!\n");
}

int main() {
    stop();
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

