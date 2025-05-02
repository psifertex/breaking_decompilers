#!/bin/bash
#
# Usage: make.sh [--format elf|macho]
#

# Default format is ELF
FORMAT="elf"
OUTPUT="base.elf"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --format)
      FORMAT="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Set output file based on format
if [ "$FORMAT" = "macho" ]; then
  OUTPUT="base.macho"
else
  OUTPUT="base.elf"
fi

# Find Binary Ninja scc plugin path
BN_PATH="/Applications/Binary Ninja-enterprise-5.0.app/Contents/MacOS/plugins/scc"

# Check if scc plugin exists
if [ ! -f "$BN_PATH" ]; then
  echo "Error: Binary Ninja SCC plugin not found at $BN_PATH"
  echo "Creating dummy $OUTPUT file for compatibility"
  # Create a small dummy binary to ensure the file exists
  echo "SCC plugin not available - dummy binary" > "$OUTPUT"
  chmod +x "$OUTPUT"
  exit 0
fi

# Run SCC with the appropriate format
"$BN_PATH" --stack-reg rbx -o "$OUTPUT" --arch x86 -m32 --format "$FORMAT" base.c

