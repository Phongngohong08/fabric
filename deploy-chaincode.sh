#!/bin/bash

# Multi-Language Chaincode Deployment Script
# Author: Phong Ngo
# Date: June 16, 2025

set -e

echo "=== Multi-Language Chaincode Deployment ==="

FABRIC_SAMPLES_DIR="/home/phongnh/go/src/github.com/Phongngohong08/fabric/fabric-samples"
NETWORK_DIR="$FABRIC_SAMPLES_DIR/test-network"

# Function to display usage
usage() {
    echo "Usage: $0 [LANGUAGE] [ACTION]"
    echo ""
    echo "LANGUAGE options:"
    echo "  go           - Deploy Go chaincode (default)"
    echo "  javascript   - Deploy JavaScript chaincode"
    echo "  typescript   - Deploy TypeScript chaincode"
    echo "  java         - Deploy Java chaincode"
    echo ""
    echo "ACTION options:"
    echo "  deploy       - Deploy new chaincode (default)"
    echo "  upgrade      - Upgrade existing chaincode"
    echo "  query        - Query chaincode"
    echo "  invoke       - Invoke chaincode transaction"
    echo ""
    echo "Examples:"
    echo "  $0 go deploy"
    echo "  $0 javascript"
    echo "  $0 typescript query"
    echo ""
    exit 1
}

# Function to check if network is running
check_network() {
    echo "🔍 Checking network status..."
    if [ ! "$(docker ps -q -f name=peer0.org1.example.com)" ]; then
        echo "❌ Network is not running!"
        echo "Please start the network first:"
        echo "  ./start-network.sh"
        exit 1
    fi
    echo "✅ Network is running"
}

# Function to deploy Go chaincode
deploy_go_chaincode() {
    echo "🔨 Deploying Go chaincode..."
    cd "$NETWORK_DIR"
    
    ./network.sh deployCC -ccn basic -ccp ../asset-transfer-basic/chaincode-go/ -ccl go
    
    echo "✅ Go chaincode deployed successfully!"
}

# Function to deploy JavaScript chaincode
deploy_javascript_chaincode() {
    echo "🔨 Deploying JavaScript chaincode..."
    cd "$NETWORK_DIR"
    
    # Check if Node.js is installed
    if ! command -v node &> /dev/null; then
        echo "❌ Node.js is not installed!"
        echo "Please install Node.js first: https://nodejs.org/"
        exit 1
    fi
    
    ./network.sh deployCC -ccn basic -ccp ../asset-transfer-basic/chaincode-javascript/ -ccl javascript
    
    echo "✅ JavaScript chaincode deployed successfully!"
}

# Function to deploy TypeScript chaincode
deploy_typescript_chaincode() {
    echo "🔨 Deploying TypeScript chaincode..."
    cd "$NETWORK_DIR"
    
    # Check if Node.js and TypeScript are installed
    if ! command -v node &> /dev/null; then
        echo "❌ Node.js is not installed!"
        echo "Please install Node.js first: https://nodejs.org/"
        exit 1
    fi
    
    if ! command -v tsc &> /dev/null; then
        echo "📦 Installing TypeScript globally..."
        npm install -g typescript
    fi
    
    ./network.sh deployCC -ccn basic -ccp ../asset-transfer-basic/chaincode-typescript/ -ccl typescript
    
    echo "✅ TypeScript chaincode deployed successfully!"
}

# Function to deploy Java chaincode
deploy_java_chaincode() {
    echo "🔨 Deploying Java chaincode..."
    cd "$NETWORK_DIR"
    
    # Check if Java and Gradle are installed
    if ! command -v java &> /dev/null; then
        echo "❌ Java is not installed!"
        echo "Please install Java JDK 8 or 11"
        exit 1
    fi
    
    if ! command -v gradle &> /dev/null; then
        echo "❌ Gradle is not installed!"
        echo "Please install Gradle: https://gradle.org/install/"
        exit 1
    fi
    
    ./network.sh deployCC -ccn basic -ccp ../asset-transfer-basic/chaincode-java/ -ccl java
    
    echo "✅ Java chaincode deployed successfully!"
}

# Function to query chaincode
query_chaincode() {
    echo "🔍 Querying chaincode..."
    cd "$NETWORK_DIR"
    
    echo "📋 Querying all assets..."
    ./network.sh query -C mychannel -n basic -c '{"function":"GetAllAssets","Args":[]}'
    
    echo ""
    echo "📋 Querying specific asset (asset6)..."
    ./network.sh query -C mychannel -n basic -c '{"function":"ReadAsset","Args":["asset6"]}'
}

# Function to invoke chaincode
invoke_chaincode() {
    echo "⚡ Invoking chaincode transaction..."
    cd "$NETWORK_DIR"
    
    echo "📝 Creating new asset..."
    TIMESTAMP=$(date +%s)
    ./network.sh invoke -C mychannel -n basic -c "{\"function\":\"CreateAsset\",\"Args\":[\"asset$TIMESTAMP\",\"blue\",\"50\",\"Tom\",\"1300\"]}"
    
    echo ""
    echo "📋 Querying the new asset..."
    sleep 2
    ./network.sh query -C mychannel -n basic -c "{\"function\":\"ReadAsset\",\"Args\":[\"asset$TIMESTAMP\"]}"
}

# Function to upgrade chaincode
upgrade_chaincode() {
    echo "🔄 Upgrading chaincode..."
    cd "$NETWORK_DIR"
    
    case $LANGUAGE in
        go)
            ./network.sh deployCC -ccn basic -ccp ../asset-transfer-basic/chaincode-go/ -ccl go -ccv 2.0
            ;;
        javascript)
            ./network.sh deployCC -ccn basic -ccp ../asset-transfer-basic/chaincode-javascript/ -ccl javascript -ccv 2.0
            ;;
        typescript)
            ./network.sh deployCC -ccn basic -ccp ../asset-transfer-basic/chaincode-typescript/ -ccl typescript -ccv 2.0
            ;;
        java)
            ./network.sh deployCC -ccn basic -ccp ../asset-transfer-basic/chaincode-java/ -ccl java -ccv 2.0
            ;;
    esac
    
    echo "✅ Chaincode upgraded successfully!"
}

# Main execution
LANGUAGE=${1:-go}
ACTION=${2:-deploy}

# Validate inputs
case $LANGUAGE in
    go|javascript|typescript|java)
        ;;
    *)
        echo "❌ Invalid language: $LANGUAGE"
        usage
        ;;
esac

case $ACTION in
    deploy|upgrade|query|invoke)
        ;;
    *)
        echo "❌ Invalid action: $ACTION"
        usage
        ;;
esac

echo "Language: $LANGUAGE"
echo "Action: $ACTION"
echo ""

# Check network status
check_network

# Execute action
case $ACTION in
    deploy)
        case $LANGUAGE in
            go)
                deploy_go_chaincode
                ;;
            javascript)
                deploy_javascript_chaincode
                ;;
            typescript)
                deploy_typescript_chaincode
                ;;
            java)
                deploy_java_chaincode
                ;;
        esac
        ;;
    upgrade)
        upgrade_chaincode
        ;;
    query)
        query_chaincode
        ;;
    invoke)
        invoke_chaincode
        ;;
esac

echo ""
echo "🎉 Operation completed successfully!"
echo ""
echo "💡 Next steps:"
echo "  - Query: ./deploy-chaincode.sh $LANGUAGE query"
echo "  - Invoke: ./deploy-chaincode.sh $LANGUAGE invoke"
echo "  - Monitor: ./monitor-network.sh"
