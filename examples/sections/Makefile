# Linux only
CC = gcc
CFLAGS = -O0 -march=x86-64 -masm=intel
TARGET_EXT = .elf

# Define the source and object files
SRC = base.c
OBJ = $(SRC:.c=.o)
TARGET = base$(TARGET_EXT)
PRE = base.pre

# Default target
all: $(TARGET)

# Rule to create pre-processed file without .eh_frame
$(PRE): $(SRC)
	# Omit .eh_frame to fool Ghidra
	$(CC) $(CFLAGS) -fno-asynchronous-unwind-tables -o $@ $<

# Rule to create the final target with section manipulation
$(TARGET): $(PRE)
	chmod +x ./create_trampoline.sh
	./create_trampoline.sh $(PRE) $(TARGET)

# Rule to compile the source files
%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

# Clean up the build files
clean:
	rm -f $(OBJ) $(TARGET) $(PRE) i1.bin i2.bin init_redirect.asm

.PHONY: all clean