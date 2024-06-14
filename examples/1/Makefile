# Define the compiler based on the OS
ifeq ($(shell uname), Linux)
    CC = gcc
    CFLAGS = -O0 -march=x86-64 -masm=intel
    TARGET_EXT = .elf
		OBJ_EXT = .o
else ifeq ($(shell uname), Darwin)
    CC = gcc
    CFLAGS = -O0 -arch x86_64 -masm=intel 
    TARGET_EXT = .macho
    OBJ_EXT = .macho.o
endif

# Define the source and object files
SRC = base.c
OBJ = $(SRC:.c=$(OBJ_EXT))
TARGET = base$(TARGET_EXT)

# Default target
all: $(TARGET)

# Rule to link the object files
$(TARGET): $(OBJ)
	$(CC) $(CFLAGS) -o $@ $^

# Rule to compile the source files
%$(OBJ_EXT): %.c
	$(CC) $(CFLAGS) -c -o $@ $<

# Clean up the build files
clean:
	rm -f $(OBJ) base.elf base.macho

.PHONY: all clean

