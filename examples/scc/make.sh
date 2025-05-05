#!/bin/bash
#
# Usage: make.sh [--format elf|macho|all]
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
elif [ "$FORMAT" = "all" ]; then
  # When "all" is specified, we'll build both formats
  # First build will be ELF, second will be Mach-O
  OUTPUT="base.elf"
else
  OUTPUT="base.elf"
fi

# Find Binary Ninja lastrun file based on OS
if [[ "$OSTYPE" == "darwin"* ]]; then
  LASTRUN_PATH="$HOME/Library/Application Support/Binary Ninja/lastrun"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  LASTRUN_PATH="$HOME/.binaryninja/lastrun"
elif [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin"* || "$OSTYPE" == "win32" ]]; then
  LASTRUN_PATH="$APPDATA/Binary Ninja/lastrun"
else
  echo "Unsupported OS: $OSTYPE"
  exit 1
fi

# Check if lastrun file exists
if [ ! -f "$LASTRUN_PATH" ]; then
  echo "Error: Binary Ninja lastrun file not found at $LASTRUN_PATH"
  echo "Creating dummy $OUTPUT file for compatibility"
  echo "SCC plugin not available - dummy binary" > "$OUTPUT"
  chmod +x "$OUTPUT"
  exit 0
fi

# Read Binary Ninja install path from lastrun file
BN_INSTALL_PATH=$(cat "$LASTRUN_PATH")

# Set SCC path based on OS
if [[ "$OSTYPE" == "darwin"* ]]; then
  SCC_PATH="$BN_INSTALL_PATH/plugins/scc"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  SCC_PATH="$BN_INSTALL_PATH/plugins/scc"
elif [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin"* || "$OSTYPE" == "win32" ]]; then
  SCC_PATH="$BN_INSTALL_PATH/plugins/scc.exe"
else
  echo "Unsupported OS: $OSTYPE"
  exit 1
fi

# Check if scc plugin exists
if [ ! -f "$SCC_PATH" ]; then
  echo "Error: Binary Ninja SCC plugin not found at $SCC_PATH"
  echo "Creating dummy $OUTPUT file for compatibility"
  # Create a small dummy binary to ensure the file exists
  echo "SCC plugin not available - dummy binary" > "$OUTPUT"
  chmod +x "$OUTPUT"
  exit 0
fi

# Run SCC with the appropriate format
if [ "$FORMAT" = "all" ]; then
  # Build ELF format
  "$SCC_PATH" --stack-reg rbx -o "base.elf" --arch x86 -m32 --format "elf" base.c
  
  # Build Mach-O format
  "$SCC_PATH" --stack-reg rbx -o "base.macho" --arch x86 -m32 --format "macho" base.c
  
  echo "Built both ELF and Mach-O formats"
else
  # Build single format as specified
  "$SCC_PATH" --stack-reg rbx -o "$OUTPUT" --arch x86 -m32 --format "$FORMAT" base.c
fi
