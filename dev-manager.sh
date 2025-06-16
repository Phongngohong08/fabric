#!/bin/bash

# Development Environment Manager
# Author: Phong Ngo
# Date: June 16, 2025

set -e

echo "=== Fabric Development Environment Manager ==="

FABRIC_ROOT="/home/phongnh/go/src/github.com/Phongngohong08/fabric"
FABRIC_SAMPLES_DIR="$FABRIC_ROOT/fabric-samples"
NETWORK_DIR="$FABRIC_SAMPLES_DIR/test-network"
LOG_DIR="$FABRIC_ROOT/logs"

# Create logs directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Function to display usage
usage() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  status       - Show comprehensive environment status"
    echo "  start        - Start the development environment"
    echo "  stop         - Stop the development environment"
    echo "  restart      - Restart the development environment"
    echo "  logs         - Collect and display logs"
    echo "  clean        - Clean all artifacts and containers"
    echo "  backup       - Backup current environment"
    echo "  restore      - Restore from backup"
    echo "  rebuild      - Rebuild binaries and restart"
    echo ""
    echo "Examples:"
    echo "  $0 start"
    echo "  $0 status"
    echo "  $0 logs"
    echo ""
    exit 1
}

# Function to show status
show_status() {
    echo "🔍 Development Environment Status"
    echo "================================="
    echo "Timestamp: $(date)"
    echo ""
    
    # Binary versions
    echo "📦 Binary Information:"
    cd "$FABRIC_SAMPLES_DIR"
    ./bin/peer version | head -3
    echo ""
    
    # Network status
    echo "🌐 Network Status:"
    if [ "$(docker ps -q)" ]; then
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"
    else
        echo "❌ No containers running"
    fi
    echo ""
    
    # Channel and chaincode status
    if [ "$(docker ps -q -f name=peer0.org1.example.com)" ]; then
        echo "📋 Channel Status:"
        docker exec peer0.org1.example.com peer channel list 2>/dev/null || echo "Cannot query channels"
        echo ""
        
        echo "⚡ Chaincode Status:"
        docker ps --format "{{.Names}}" | grep dev-peer || echo "No chaincode containers"
    fi
    echo ""
}

# Function to start environment
start_environment() {
    echo "🚀 Starting development environment..."
    
    echo "Using the tested start-network.sh script..."
    cd "$FABRIC_ROOT"
    ./start-network.sh
    
    echo "✅ Development environment started successfully!"
}

# Function to stop environment
stop_environment() {
    echo "🛑 Stopping development environment..."
    cd "$FABRIC_ROOT"
    ./cleanup-build-fabric.sh
    echo "✅ Environment stopped successfully!"
}

# Function to restart environment
restart_environment() {
    echo "🔄 Restarting development environment..."
    stop_environment
    sleep 2
    start_environment
}

# Function to collect logs
collect_logs() {
    echo "📝 Collecting logs..."
    
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    LOG_FILE="$LOG_DIR/fabric_logs_$TIMESTAMP.log"
    
    echo "=== Fabric Development Environment Logs ===" > "$LOG_FILE"
    echo "Collected at: $(date)" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    
    # System information
    echo "=== System Information ===" >> "$LOG_FILE"
    echo "Go version: $(go version)" >> "$LOG_FILE"
    echo "Docker version: $(docker --version)" >> "$LOG_FILE"
    echo "Docker Compose version: $(docker-compose --version 2>/dev/null || echo 'Not installed')" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    
    # Container status
    echo "=== Container Status ===" >> "$LOG_FILE"
    docker ps -a >> "$LOG_FILE" 2>&1
    echo "" >> "$LOG_FILE"
    
    # Network information
    echo "=== Docker Networks ===" >> "$LOG_FILE"
    docker network ls >> "$LOG_FILE" 2>&1
    echo "" >> "$LOG_FILE"
    
    # Volume information
    echo "=== Docker Volumes ===" >> "$LOG_FILE"
    docker volume ls >> "$LOG_FILE" 2>&1
    echo "" >> "$LOG_FILE"
    
    # Container logs
    for container in $(docker ps --format "{{.Names}}" | grep -E "(peer|orderer|ca)"); do
        echo "=== Logs for $container ===" >> "$LOG_FILE"
        docker logs "$container" >> "$LOG_FILE" 2>&1
        echo "" >> "$LOG_FILE"
    done
    
    echo "📄 Logs collected: $LOG_FILE"
    echo ""
    echo "📊 Recent errors (if any):"
    grep -i error "$LOG_FILE" | tail -5 || echo "No errors found"
}

# Function to clean environment
clean_environment() {
    echo "🧹 Cleaning development environment..."
    
    echo "Stopping network..."
    cd "$NETWORK_DIR"
    ./network.sh down
    
    echo "Removing unused Docker resources..."
    docker system prune -f
    
    echo "Removing chaincode containers..."
    docker rm $(docker ps -aq -f name=dev-peer) 2>/dev/null || true
    
    echo "Removing chaincode images..."
    docker rmi $(docker images -q dev-peer*) 2>/dev/null || true
    
    echo "✅ Environment cleaned successfully!"
}

# Function to backup environment
backup_environment() {
    echo "💾 Backing up environment..."
    
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_DIR="$FABRIC_ROOT/backup_$TIMESTAMP"
    mkdir -p "$BACKUP_DIR"
    
    # Backup binaries
    cp -r "$FABRIC_SAMPLES_DIR/bin" "$BACKUP_DIR/"
    
    # Backup network artifacts if they exist
    if [ -d "$NETWORK_DIR/organizations" ]; then
        cp -r "$NETWORK_DIR/organizations" "$BACKUP_DIR/"
    fi
    
    # Backup configuration
    if [ -d "$NETWORK_DIR/channel-artifacts" ]; then
        cp -r "$NETWORK_DIR/channel-artifacts" "$BACKUP_DIR/"
    fi
    
    echo "📁 Backup created: $BACKUP_DIR"
    echo "✅ Backup completed successfully!"
}

# Function to restore environment
restore_environment() {
    echo "🔄 Restoring environment from backup..."
    
    # Find latest backup
    LATEST_BACKUP=$(ls -d "$FABRIC_SAMPLES_DIR"/bin.backup.* 2>/dev/null | sort -r | head -1)
    
    if [ -z "$LATEST_BACKUP" ]; then
        echo "❌ No backup found!"
        echo "Available backups:"
        ls -la "$FABRIC_SAMPLES_DIR"/ | grep "bin.backup" || echo "No backups available"
        return 1
    fi
    
    echo "📁 Latest backup found: $LATEST_BACKUP"
    echo "🔄 Restoring binaries from backup..."
    
    # Backup current binaries before restore
    CURRENT_BACKUP="$FABRIC_SAMPLES_DIR/bin.backup.before_restore.$(date +%Y%m%d_%H%M%S)"
    mv "$FABRIC_SAMPLES_DIR/bin" "$CURRENT_BACKUP"
    echo "📁 Current binaries backed up to: $CURRENT_BACKUP"
    
    # Restore from backup
    cp -r "$LATEST_BACKUP" "$FABRIC_SAMPLES_DIR/bin"
    chmod +x "$FABRIC_SAMPLES_DIR"/bin/*
    
    echo "✅ Environment restored successfully!"
}

# Function to rebuild environment
rebuild_environment() {
    echo "🔨 Rebuilding development environment..."
    
    echo "Step 1: Stopping current environment..."
    stop_environment
    
    echo "Step 2: Rebuilding binaries..."
    "$FABRIC_ROOT/build-fabric.sh"
    
    echo "Step 3: Starting with new binaries..."
    start_environment
    
    echo "✅ Rebuild completed successfully!"
}

# Main execution
COMMAND=${1:-status}

case $COMMAND in
    status)
        show_status
        ;;
    start)
        start_environment
        ;;
    stop)
        stop_environment
        ;;
    restart)
        restart_environment
        ;;
    logs)
        collect_logs
        ;;
    clean)
        clean_environment
        ;;
    backup)
        backup_environment
        ;;
    restore)
        restore_environment
        ;;
    rebuild)
        rebuild_environment
        ;;
    *)
        echo "❌ Invalid command: $COMMAND"
        usage
        ;;
esac

echo ""
echo "💡 Available commands:"
echo "  ./dev-manager.sh status   - Check environment status"
echo "  ./dev-manager.sh logs     - Collect detailed logs"
echo "  ./dev-manager.sh start    - Start development environment"
echo "  ./deploy-chaincode.sh     - Deploy different chaincodes"
