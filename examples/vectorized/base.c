#include <stdio.h>
#include <string.h>
#include <immintrin.h>
#include <stdbool.h>

#define PASSWORD "correct"

// Vectorized string comparison function using AVX2 instructions
bool vectorized_strcmp(const char* str1, const char* str2) {
    size_t len1 = strlen(str1);
    size_t len2 = strlen(str2);
    
    if (len1 != len2) {
        return false;
    }
    
    // For short strings (like our password), we can use a single vector comparison
    if (len1 <= 32) {
        __m256i vec1 = _mm256_loadu_si256((const __m256i*)str1);
        __m256i vec2 = _mm256_loadu_si256((const __m256i*)str2);
        __m256i result = _mm256_cmpeq_epi8(vec1, vec2);
        
        // Check if all bytes matched
        int mask = _mm256_movemask_epi8(result);
        
        // Only the bytes up to length need to match
        int required_mask = (1 << len1) - 1;
        return (mask & required_mask) == required_mask;
    } else {
        // For longer strings, we'd iterate through chunks, but our password is short
        return strcmp(str1, str2) == 0;
    }
}

int main() {
    char input[100];

    printf("Enter the password: ");
    fgets(input, sizeof(input), stdin);

    // Remove newline character if present
    size_t len = strlen(input);
    if (len > 0 && input[len-1] == '\n') {
        input[len-1] = '\0';
    }

    if (vectorized_strcmp(input, PASSWORD)) {
        printf("Access granted!\n");
    } else {
        printf("Access denied!\n");
    }
    return 0;
}

