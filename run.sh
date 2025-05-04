#!/bin/bash

# Check for command line arguments
BUILD_ONLY=false
EXPORT_PDF=false

for arg in "$@"; do
    case $arg in
        build)
            BUILD_ONLY=true
            ;;
        export)
            EXPORT_PDF=true
            ;;
    esac
done

SCRIPT=$(realpath "$0")
SP=$(dirname "$SCRIPT")

# First clean any existing builds
echo "Cleaning previous builds..."
cd "$SP"/examples && make clean

# Build examples for macOS locally
echo "Building examples for macOS..."
cd "$SP"/examples && make

# Special handling for scc example (uses make.sh instead of Makefile)
echo "Building scc example for macOS..."
cd "$SP"/examples/scc && bash make.sh --format macho

# Special handling for upx on macOS
echo "Creating UPX compressed macOS binary..."
if command -v upx &> /dev/null; then
    cd "$SP"/examples/upx && upx -f -o base.macho.upx base.macho 2>/dev/null || echo "UPX compression failed for macOS binary"
else
    echo "UPX not found on macOS host, skipping macOS UPX compression"
fi

# Create a Dockerfile for Linux x86_64 builds with UPX
DOCKER_FILE="$SP/Dockerfile.build"
cat > "$DOCKER_FILE" << 'EOF'
FROM --platform=linux/amd64 ubuntu:24.04

RUN apt-get update && apt-get install -y \
    build-essential \
    gcc \
    make \
    upx \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
EOF

# Build examples for Linux using podman with x86_64 architecture
echo "Building examples for Linux x86_64..."
podman build --platform=linux/amd64 -t breaking-decompilers-build -f "$DOCKER_FILE" .
podman run --platform=linux/amd64 --rm -v "$SP":/src breaking-decompilers-build bash -c "cd /src/examples && make clean && make && cd scc && bash make.sh --format elf && cd ../upx && upx -f -o base.elf.upx base.elf && ls -la base.elf.upx"

# Remove temporary Dockerfile
rm -f "$DOCKER_FILE"

# Print build summary
echo "Build completed successfully!"
echo "- macOS binaries: .macho files in each example directory"
echo "- Linux binaries: .elf files in each example directory"
echo "- UPX compressed binaries: examples/upx/base.elf.upx and examples/upx/base.macho.upx (if UPX installed locally)"

# Export static site if requested
if [ "$EXPORT_PDF" = true ]; then
    echo "Exporting static site for printing..."
    
    # Create output directory if it doesn't exist
    mkdir -p "$SP/output"
    
    # Generate static site for printing
    podman run --rm \
        -v "$SP":/slides \
        -v "$SP"/images:/_assets/images \
        -v "$SP"/output:/output \
        webpronl/reveal-md:latest /slides/index.md \
        --static /output
        
    echo "Static site exported to ./output/"
    echo "To create PDF, open ./output/index.html in a browser and use the browser's print function."
    echo "For best results, use Chrome or Edge and set the print options to:"
    echo " - Background graphics: On"
    echo " - Paper size: Letter or A4"
    echo " - Margins: None"
    
    exit 0
fi

# Exit if build-only flag was provided
if [ "$BUILD_ONLY" = true ]; then
    echo "Build-only mode: Exiting without starting presentation server"
    exit 0
fi

# Run the reveal-md server
echo "Starting presentation server..."
podman run --rm -p 1948:1948 -p 35729:35729 \
    -v "$SP":/slides \
    -v "$SP"/images:/_assets/images \
    webpronl/reveal-md:latest /slides --watch \
    --glob './*.md';
