#define PASSWORD "correct"

int main() {
    char input[100];

    puts("Enter the password: ");
    fgets(input, sizeof(input), stdin);

    // Remove newline character if present
    size_t len = strlen(input);
    if (len > 0 && input[len-1] == '\n') {
        input[len-1] = '\0';
    }

    if (strcmp(input, PASSWORD) == 0) {
        puts("Access granted!\n");
    } else {
        puts("Access denied!\n");
    }
    return 0;
}

