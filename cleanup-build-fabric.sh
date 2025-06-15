#!/bin/bash

# Clean Hyperledger Fabric Environment Script
# Author: Phong Ngo
# Date: June 15, 2025

set -e

echo "=== Hyperledger Fabric Cleanup Script ==="

# Navigate to test network directory
TEST_NETWORK_DIR="/home/phongnh/go/src/github.com/Phongngohong08/fabric/fabric-samples/test-network"
FABRIC_DIR="/home/phongnh/go/src/github.com/Phongngohong08/fabric/fabric-2.5.12"

echo "🧹 Starting cleanup process..."

# Stop test network
if [ -d "$TEST_NETWORK_DIR" ]; then
    echo "🛑 Stopping test network..."
    cd "$TEST_NETWORK_DIR"
    ./network.sh down
    echo "✅ Test network stopped"
else
    echo "⚠️  Test network directory not found"
fi

# Clean Docker containers and images
echo "🐳 Cleaning Docker containers and images..."

# Stop all chaincode containers
echo "Stopping chaincode containers..."
docker stop $(docker ps -aq --filter "name=dev-peer") 2>/dev/null || true
docker rm $(docker ps -aq --filter "name=dev-peer") 2>/dev/null || true

# Remove unused containers
echo "Removing unused containers..."
docker container prune -f

# Remove unused images  
echo "Removing unused images..."
docker image prune -f

# Remove unused volumes
echo "Removing unused volumes..."
docker volume prune -f

# Remove unused networks
echo "Removing unused networks..."
docker network prune -f

echo "✅ Docker cleanup completed"

# Clean build artifacts
if [ -d "$FABRIC_DIR" ]; then
    echo "🔨 Cleaning build artifacts..."
    cd "$FABRIC_DIR"
    make clean 2>/dev/null || true
    echo "✅ Build artifacts cleaned"
else
    echo "⚠️  Fabric source directory not found"
fi

# Clean specific directories
echo "📁 Cleaning specific directories..."

# Clean test network artifacts
if [ -d "$TEST_NETWORK_DIR" ]; then
    cd "$TEST_NETWORK_DIR"
    rm -rf organizations/ 2>/dev/null || true
    rm -rf channel-artifacts/ 2>/dev/null || true
    rm -rf system-genesis-block/ 2>/dev/null || true
    rm -f *.tar.gz 2>/dev/null || true
    rm -f log.txt 2>/dev/null || true
    echo "✅ Test network artifacts cleaned"
fi

# Clean logs
echo "📄 Cleaning logs..."
find /home/phongnh/go/src/github.com/Phongngohong08/fabric/ -name "*.log" -type f -delete 2>/dev/null || true
find /home/phongnh/go/src/github.com/Phongngohong08/fabric/ -name "log.txt" -type f -delete 2>/dev/null || true

echo "✅ Logs cleaned"

# Show Docker status
echo ""
echo "📊 Current Docker status:"
echo "Containers:"
docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"

echo ""
echo "Images:"
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | grep -E "(hyperledger|dev-)" || echo "No Fabric images found"

echo ""
echo "Volumes:"
docker volume ls | grep -E "(compose|docker)" || echo "No Fabric volumes found"

echo ""
echo "🎉 Cleanup completed successfully!"
echo ""
echo "📝 What was cleaned:"
echo "   • Stopped test network"
echo "   • Removed chaincode containers"
echo "   • Cleaned Docker containers, images, volumes, networks"
echo "   • Removed build artifacts"
echo "   • Cleaned test network certificates and channel artifacts"
echo "   • Removed log files"
echo ""
echo "🚀 You can now run './build-fabric.sh' and './start-network.sh' for a fresh start!"
