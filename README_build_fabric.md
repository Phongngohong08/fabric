# Hyperledger Fabric Build Guide

Hướng dẫn build lại Hyperledger Fabric binaries và chạy test network.

## Thông tin phiên bản

- **Fabric Version**: v2.5.12
- **Go Version**: 1.23.5
- **Docker Version**: Yêu cầu Docker và Docker Compose
- **OS**: Linux (Ubuntu/Debian recommended)

## Cấu trúc thư mục

```
fabric/
├── fabric-2.5.12/          # Mã nguồn Hyperledger Fabric
│   ├── build/bin/           # Binaries được build
│   └── Makefile             # Build configuration
└── fabric-samples/         # Samples và test network
    ├── bin/                 # Pre-built binaries
    ├── test-network/        # Test network scripts
    └── asset-transfer-basic/ # Sample chaincode
```

## Yêu cầu hệ thống

### 1. Cài đặt Go

```bash
# Kiểm tra phiên bản Go hiện tại
go version

# Nếu chưa có Go 1.23.5, cần cài đặt:
wget https://go.dev/dl/go1.23.5.linux-amd64.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.23.5.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
```

### 2. Cài đặt Docker

```bash
# Cài đặt Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Cài đặt Docker Compose
sudo apt-get update
sudo apt-get install docker-compose-plugin

# Thêm user vào docker group
sudo usermod -aG docker $USER
newgrp docker
```

### 3. Cài đặt các dependencies khác

```bash
sudo apt-get update
sudo apt-get install -y \
    git \
    curl \
    wget \
    make \
    build-essential \
    jq
```

## Hướng dẫn Build

### Bước 1: Clean và Build Fabric Binaries

```bash
# Chuyển đến thư mục fabric source
cd /home/phongnh/go/src/github.com/Phongngohong08/fabric/fabric-2.5.12

# Clean artifacts cũ
make clean

# Build tất cả native binaries
make native

# Hoặc build từng binary cụ thể
make peer orderer configtxgen configtxlator cryptogen

# Kiểm tra binaries đã được build
ls -la build/bin/
./build/bin/peer version
./build/bin/orderer version
```

### Bước 2: Kiểm tra binaries

```bash
# Kiểm tra peer binary
./build/bin/peer version
# Output: peer: Version: 2.5.12, Commit SHA: ..., Go version: go1.23.5

# Kiểm tra orderer binary  
./build/bin/orderer version
# Output: orderer: Version: 2.5.12, Commit SHA: ..., Go version: go1.23.5

# Kiểm tra configtxgen
./build/bin/configtxgen --help
```

## Hướng dẫn chạy Test Network

### Bước 1: Chuẩn bị môi trường

```bash
# Chuyển đến thư mục test-network
cd /home/phongnh/go/src/github.com/Phongngohong08/fabric/fabric-samples/test-network

# Kiểm tra Docker
docker --version
docker-compose --version
```

### Bước 2: Start Test Network

```bash
# Dọn dẹp network cũ (nếu có)
./network.sh down

# Khởi động network và tạo channel
./network.sh up createChannel

# Kiểm tra containers đang chạy
docker ps
```

**Expected Output:**
```
CONTAINER ID   IMAGE                               COMMAND             STATUS          PORTS
xxxxx          hyperledger/fabric-peer:latest      "peer node start"   Up X minutes    0.0.0.0:7051->7051/tcp...
xxxxx          hyperledger/fabric-orderer:latest   "orderer"           Up X minutes    0.0.0.0:7050->7050/tcp...
xxxxx          hyperledger/fabric-peer:latest      "peer node start"   Up X minutes    0.0.0.0:9051->9051/tcp...
```

### Bước 3: Deploy Chaincode

```bash
# Deploy chaincode asset-transfer-basic (Go)
./network.sh deployCC -ccn basic -ccp ../asset-transfer-basic/chaincode-go -ccl go

# Hoặc deploy chaincode JavaScript
./network.sh deployCC -ccn basic -ccp ../asset-transfer-basic/chaincode-javascript -ccl javascript

# Hoặc deploy chaincode Java
./network.sh deployCC -ccn basic -ccp ../asset-transfer-basic/chaincode-java -ccl java
```

### Bước 4: Test Chaincode

```bash
# Setup environment cho peer commands
export PATH=${PWD}/../bin:$PATH
export FABRIC_CFG_PATH=$PWD/../config
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
export CORE_PEER_ADDRESS=localhost:7051

# Initialize ledger với sample data
peer chaincode invoke -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.example.com \
    --tls \
    --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" \
    -C mychannel \
    -n basic \
    --peerAddresses localhost:7051 \
    --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" \
    --peerAddresses localhost:9051 \
    --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt" \
    -c '{"function":"InitLedger","Args":[]}'

# Query asset
peer chaincode query -C mychannel -n basic -c '{"function":"ReadAsset","Args":["asset1"]}'
# Expected output: {"AppraisedValue":300,"Color":"blue","ID":"asset1","Owner":"Tomoko","Size":5}

# Query tất cả assets
peer chaincode query -C mychannel -n basic -c '{"function":"GetAllAssets","Args":[]}'

# Tạo asset mới
peer chaincode invoke -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.example.com \
    --tls \
    --cafile "${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem" \
    -C mychannel \
    -n basic \
    --peerAddresses localhost:7051 \
    --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt" \
    --peerAddresses localhost:9051 \
    --tlsRootCertFiles "${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt" \
    -c '{"function":"CreateAsset","Args":["asset100","red","50","John","1000"]}'
```

## Monitor và Debug

### 1. Monitor containers

```bash
# Xem logs của tất cả containers
./monitordocker.sh

# Xem logs của container cụ thể
docker logs orderer.example.com
docker logs peer0.org1.example.com
docker logs peer0.org2.example.com
```

### 2. Kiểm tra channel và chaincode

```bash
# List channels
peer channel list

# Kiểm tra chaincode đã install
peer lifecycle chaincode queryinstalled

# Kiểm tra chaincode đã commit
peer lifecycle chaincode querycommitted --channelID mychannel
```

## Dọn dẹp

### Stop và clean network

```bash
# Stop network
./network.sh down

# Clean Docker volumes và images
docker system prune -a
docker volume prune
```

### Clean build artifacts

```bash
cd /home/phongnh/go/src/github.com/Phongngohong08/fabric/fabric-2.5.12
make clean
```

## Troubleshooting

### 1. Lỗi Go version
```bash
# Kiểm tra Go version
go version
# Cần Go 1.23.5 hoặc tương thích
```

### 2. Lỗi Docker permission
```bash
sudo usermod -aG docker $USER
newgrp docker
```

### 3. Lỗi port conflict
```bash
# Kiểm tra ports đang sử dụng
netstat -tulpn | grep :7050
netstat -tulpn | grep :7051
netstat -tulpn | grep :9051

# Kill process sử dụng port
sudo kill -9 <PID>
```

### 4. Lỗi chaincode
```bash
# Xem logs chaincode containers
docker logs <chaincode_container_id>

# Rebuild và redeploy chaincode
./network.sh deployCC -ccn basic -ccp ../asset-transfer-basic/chaincode-go -ccl go
```

## Cấu hình Network

### Default Configuration
- **Channel**: mychannel
- **Organizations**: Org1MSP, Org2MSP
- **Orderer**: orderer.example.com:7050
- **Peer Org1**: peer0.org1.example.com:7051
- **Peer Org2**: peer0.org2.example.com:9051

### Ports
- Orderer: 7050, 7053, 9443
- Peer0 Org1: 7051, 9444
- Peer0 Org2: 9051, 9445

## Scripts hữu ích

### Build script
```bash
#!/bin/bash
# build-fabric.sh
cd /home/phongnh/go/src/github.com/Phongngohong08/fabric/fabric-2.5.12
make clean
make native
echo "Build completed. Binaries available at: build/bin/"
ls -la build/bin/
```

### Start network script
```bash
#!/bin/bash
# start-network.sh
cd /home/phongnh/go/src/github.com/Phongngohong08/fabric/fabric-samples/test-network
./network.sh down
./network.sh up createChannel
./network.sh deployCC -ccn basic -ccp ../asset-transfer-basic/chaincode-go -ccl go
echo "Network started successfully!"
docker ps
```

## Tài liệu tham khảo

- [Hyperledger Fabric Documentation](https://hyperledger-fabric.readthedocs.io/)
- [Test Network Tutorial](https://hyperledger-fabric.readthedocs.io/en/latest/test_network.html)
- [Chaincode Lifecycle](https://hyperledger-fabric.readthedocs.io/en/latest/chaincode_lifecycle.html)
- [Building Fabric](https://hyperledger-fabric.readthedocs.io/en/latest/dev-setup/build.html)

