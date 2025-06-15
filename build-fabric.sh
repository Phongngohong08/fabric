#!/bin/bash

# Build Hyperledger Fabric Binaries Script
# Author: Phong Ngo
# Date: June 15, 2025

set -e

echo "=== Hyperledger Fabric Build Script ==="
echo "Starting build process..."

# Navigate to fabric source directory
FABRIC_DIR="/home/phongnh/go/src/github.com/Phongngohong08/fabric/fabric-2.5.12"
cd "$FABRIC_DIR"

echo "📁 Current directory: $(pwd)"

# Check Go version
echo "🔍 Checking Go version..."
go version

# Clean previous build artifacts
echo "🧹 Cleaning previous build artifacts..."
make clean

# Build native binaries
echo "🔨 Building native binaries..."
make native

# Check if build was successful
if [ -d "build/bin" ] && [ "$(ls -A build/bin)" ]; then
    echo "✅ Build completed successfully!"
    echo "📦 Built binaries:"
    ls -la build/bin/
    
    echo ""
    echo "🔍 Binary versions:"
    echo "Peer version:"
    ./build/bin/peer version
    echo ""
    echo "Orderer version:"
    ./build/bin/orderer version
    echo ""
    echo "ConfigTxGen help:"
    ./build/bin/configtxgen --help | head -5
    
else
    echo "❌ Build failed! No binaries found in build/bin/"
    exit 1
fi

echo ""
echo "🎉 Fabric binaries build completed successfully!"
echo "📍 Binaries location: $FABRIC_DIR/build/bin/"
echo ""
echo "Next steps:"
echo "1. Run './start-network.sh' to start the test network"
echo "2. Or manually navigate to fabric-samples/test-network/"
