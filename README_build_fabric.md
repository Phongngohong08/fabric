# Hyperledger Fabric Build Guide

Hướng dẫn chi tiết để build lại Hyperledger Fabric binaries và quản lý development environment.

## 📊 Thông tin phiên bản

- **Fabric Version**: v2.5.12
- **Go Version**: 1.23.5 (yêu cầu 1.19+)
- **Docker Version**: 20.10+ (có Docker Compose v2.24+)
- **OS**: Linux (Ubuntu/Debian được khuyến nghị)
- **Architecture**: x86_64

## 🎯 Tổng quan Scripts

Workspace này cung cấp 3 scripts chính để quản lý toàn bộ development environment:

### 1. 🔧 `build-fabric.sh` - Build Fabric Binaries
Script để build Fabric binaries từ source code và tự động copy sang fabric-samples:

```bash
# Build binaries mới từ source code
./build-fabric.sh
```

**Chức năng:**
- Build tất cả Fabric binaries từ source (peer, orderer, configtxgen, etc.)
- Backup binaries cũ trước khi thay thế
- Tự động copy binaries mới sang `fabric-samples/bin/`
- Verify phiên bản của binaries sau khi build

### 2. 🚀 `start-network.sh` - Start Test Network
Script để khởi động test network và deploy chaincode:

```bash
# Start test network với basic chaincode
./start-network.sh
```

**Chức năng:**
- Kiểm tra Docker và Docker Compose
- Clean up mạng cũ (nếu có)
- Start test network (2 peers + 1 orderer)
- Tạo channel và join peers
- Deploy basic chaincode (asset-transfer)
- Test chaincode với sample data

### 3. 📦 `deploy-chaincode.sh` - Deploy Chaincode
Script để deploy và quản lý chaincode đa ngôn ngữ:

```bash
# Deploy Go chaincode (mặc định)
./deploy-chaincode.sh

# Deploy JavaScript chaincode
./deploy-chaincode.sh javascript

# Deploy TypeScript chaincode  
./deploy-chaincode.sh typescript

# Deploy Java chaincode
./deploy-chaincode.sh java
```

## 🛠️ Cài đặt môi trường

### 📋 Yêu cầu hệ thống
```bash
# Kiểm tra requirements
go version          # Go 1.19+
docker --version    # Docker 20.10+
docker-compose --version  # v2.24+
git --version       # Git để clone code
```

### 1. Cài đặt Go 1.23.5
```bash
# Download và cài đặt Go
wget https://go.dev/dl/go1.23.5.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.23.5.linux-amd64.tar.gz

# Thêm vào PATH
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
echo 'export GOPATH=$HOME/go' >> ~/.bashrc
echo 'export PATH=$PATH:$GOPATH/bin' >> ~/.bashrc
source ~/.bashrc

# Verify
go version
```

### 2. Cài đặt Docker và Docker Compose
```bash
# Cài đặt Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Cài đặt Docker Compose v2
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.6/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# Thêm user vào docker group
sudo usermod -aG docker $USER
newgrp docker

# Verify
docker --version
docker-compose --version
```

### 3. Clone Fabric Source Code (nếu chưa có)
```bash
# Tạo GOPATH structure
mkdir -p $HOME/go/src/github.com/hyperledger

# Clone Fabric
cd $HOME/go/src/github.com/hyperledger
git clone https://github.com/hyperledger/fabric.git
cd fabric
git checkout v2.5.12

# Clone Fabric Samples
cd $HOME/go/src/github.com/hyperledger
git clone https://github.com/hyperledger/fabric-samples.git
cd fabric-samples
git checkout v2.5.12
```

## 🚀 Quy trình Build và Test

### Bước 1: Build Fabric Binaries
```bash
# Đảm bảo scripts có quyền execute
chmod +x *.sh

# Build binaries từ source
./build-fabric.sh
```

**Kết quả mong đợi:**
```
✅ Build completed successfully!
📦 Built binaries:
-rwxrwxr-x 1 user user 63569112 Jun 16 20:54 peer
-rwxrwxr-x 1 user user 40131768 Jun 16 20:54 orderer
-rwxrwxr-x 1 user user 27660640 Jun 16 20:54 configtxgen
...
🎉 Fabric binaries build and copy completed successfully!
```

### Bước 2: Start Test Network
```bash
# Start test network với chaincode
./start-network.sh
```

**Kết quả mong đợi:**
```
🧪 Testing chaincode...
Initializing ledger with sample data...
✅ Chaincode test successful!
📋 Asset1 data: {"AppraisedValue":300,"Color":"blue","ID":"asset1","Owner":"Tomoko","Size":5}
🎉 Test network is ready!
```

### Bước 3: Test Chaincode Operations
```bash
# Deploy chaincode khác (nếu muốn)
./deploy-chaincode.sh javascript

# Test basic operations
docker exec -it cli peer chaincode query -C mychannel -n basic -c '{"Args":["GetAllAssets"]}'
```

## 🔄 Development Workflow

### Modify và Rebuild Fabric Core
```bash
# 1. Sửa code trong fabric-2.5.12/
# 2. Rebuild binaries
./build-fabric.sh

# 3. Restart network với binaries mới
./cleanup-build-fabric.sh
./start-network.sh
```

### Modify Chaincode
```bash
# 1. Sửa chaincode trong fabric-samples/asset-transfer-basic/
# 2. Redeploy chaincode
./deploy-chaincode.sh go
```

## 📁 Cấu trúc thư mục chi tiết

```
fabric/
├── build-fabric.sh              # 🔧 Build Fabric binaries
├── start-network.sh             # 🚀 Start test network + chaincode
├── cleanup-build-fabric.sh      # 🧹 Cleanup script
├── deploy-chaincode.sh          # 📦 Deploy chaincode
├── dev-manager.sh              # 🎛️ Development manager
├── QUICKSTART_build_fabric.md   # 📖 Quick start guide
├── README_build_fabric.md       # 📚 Chi tiết guide (file này)
├── fabric-2.5.12/              # Fabric source code
│   ├── cmd/                    # Command sources (peer, orderer, etc.)
│   ├── build/bin/              # Built binaries (source)
│   │   ├── peer
│   │   ├── orderer
│   │   ├── configtxgen
│   │   └── ...
│   ├── common/                 # Common libraries
│   ├── core/                   # Core peer functionality
│   ├── orderer/                # Orderer implementation
│   └── Makefile               # Build configuration
├── fabric-samples/             # Test network & samples
│   ├── bin/                   # Runtime binaries (copied from build/)
│   │   ├── peer
│   │   ├── orderer
│   │   └── ...
│   ├── test-network/          # Test network configs
│   │   ├── docker/            # Docker compose files
│   │   ├── scripts/           # Network scripts
│   │   └── organizations/     # Crypto materials
│   ├── asset-transfer-basic/  # Sample Go chaincode
│   ├── asset-transfer-javascript/ # Sample JS chaincode
│   └── ...
└── logs/                      # Development logs
    └── fabric_logs_*.log
```

## 🛠️ Troubleshooting

### 1. Lỗi Docker Compose
```bash
# Nếu gặp lỗi "distutils" với docker-compose cũ
sudo apt remove -y docker-compose

# Cài đặt phiên bản mới
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.6/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
```

### 2. Lỗi Go Module
```bash
# Trong thư mục fabric-2.5.12/
go mod download
go mod tidy
go mod vendor
```

### 3. Lỗi Permission
```bash
# Set permissions cho tất cả scripts
chmod +x *.sh

# Kiểm tra Docker permissions
docker ps
# Nếu bị permission denied:
sudo usermod -aG docker $USER
newgrp docker
```

### 4. Lỗi Build "command not found"
```bash
# Kiểm tra GOPATH và PATH
echo $GOPATH
echo $PATH

# Set lại nếu cần
export GOPATH=$HOME/go
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
```

### 5. Lỗi Network "port already in use"
```bash
# Clean up containers và networks
./cleanup-build-fabric.sh

# Hoặc manual cleanup
docker stop $(docker ps -aq)
docker rm $(docker ps -aq)
docker network prune -f
```

### 6. Lỗi Chaincode Deploy
```bash
# Kiểm tra logs
docker logs peer0.org1.example.com
docker logs peer0.org2.example.com
docker logs orderer.example.com

# Restart network
./cleanup-build-fabric.sh
./start-network.sh
```

## 📊 Monitoring và Logs

### Xem logs containers
```bash
# Peer logs
docker logs -f peer0.org1.example.com

# Orderer logs  
docker logs -f orderer.example.com

# Chaincode logs
docker logs -f $(docker ps -qf "name=dev-peer")
```

### Xem trạng thái network
```bash
# Containers đang chạy
docker ps

# Networks
docker network ls

# Volumes
docker volume ls
```

## 🎯 Best Practices

### 1. Development Workflow
- Luôn backup binaries trước khi build mới
- Test với sample chaincode trước khi deploy chaincode tùy chỉnh
- Sử dụng `./cleanup-build-fabric.sh` khi gặp vấn đề

### 2. Code Organization
- Giữ source code Fabric riêng biệt với custom chaincode
- Sử dụng version control cho custom chaincode
- Document các thay đổi trong Fabric core

### 3. Performance
- Build binaries với `-tags netgo` cho production
- Monitor Docker resources usage
- Clean up unused containers và images thường xuyên

---

## 🎉 Kết luận

Sau khi hoàn thành setup, bạn sẽ có:

1. ✅ **Fabric binaries** được build từ source (v2.5.12)
2. ✅ **Test network** chạy với 2 orgs, 2 peers, 1 orderer
3. ✅ **Sample chaincode** đã deploy và test thành công
4. ✅ **Development environment** sẵn sàng cho custom development

**Next Steps:**
- Thử modify chaincode trong `fabric-samples/asset-transfer-basic/`
- Explore các sample chaincodes khác
- Develop custom chaincode cho use case của bạn
- Tìm hiểu về Fabric CA để setup production network
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

### Bước 3: Copy binaries mới thay thế binaries cũ

```bash
# Backup binaries cũ (tùy chọn)
cd /home/phongnh/go/src/github.com/Phongngohong08/fabric/fabric-samples
cp -r bin bin.backup.$(date +%Y%m%d_%H%M%S)

# Copy binaries mới build được sang fabric-samples/bin/
cp /home/phongnh/go/src/github.com/Phongngohong08/fabric/fabric-2.5.12/build/bin/* \
   /home/phongnh/go/src/github.com/Phongngohong08/fabric/fabric-samples/bin/

# Kiểm tra binaries đã được copy
cd /home/phongnh/go/src/github.com/Phongngohong08/fabric/fabric-samples
ls -la bin/
./bin/peer version
./bin/orderer version

# Hoặc copy từng binary cụ thể nếu cần
# cp ../fabric-2.5.12/build/bin/peer bin/
# cp ../fabric-2.5.12/build/bin/orderer bin/
# cp ../fabric-2.5.12/build/bin/configtxgen bin/
```

**Lưu ý quan trọng:**
- Test network sẽ sử dụng binaries từ `fabric-samples/bin/` 
- Phải copy binaries mới build được để sử dụng code mới nhất
- Backup binaries cũ để có thể rollback nếu cần

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

## 🛠️ Chi Tiết Scripts

### `dev-manager.sh` - Development Environment Manager

Đây là script quan trọng nhất, tích hợp tất cả chức năng quản lý:

**Các lệnh chính:**
```bash
./dev-manager.sh status     # Hiển thị trạng thái tổng quan
./dev-manager.sh start      # Khởi động full environment
./dev-manager.sh stop       # Dừng environment
./dev-manager.sh restart    # Khởi động lại
./dev-manager.sh logs       # Thu thập logs
./dev-manager.sh clean      # Làm sạch hoàn toàn
./dev-manager.sh backup     # Backup environment
./dev-manager.sh restore    # Restore từ backup
```

**Chi tiết chức năng:**
- **Status**: Kiểm tra Docker containers, network, binaries
- **Start**: Khởi động network + deploy basic chaincode
- **Stop**: Dừng network một cách an toàn
- **Restart**: Stop + Start với clean state
- **Logs**: Thu thập logs từ containers và lưu vào `logs/`
- **Clean**: Xóa containers, images, volumes, networks
- **Backup**: Backup binaries và configuration
- **Restore**: Restore từ backup gần nhất

### `build-fabric.sh` - Build Fabric Binaries

Build Fabric binaries từ source code:

```bash
./build-fabric.sh
```

**Quá trình build:**
1. Navigate tới `fabric-2.5.12/`
2. Check Go version
3. Run `make clean && make native`
4. Backup binaries cũ trong `fabric-samples/bin/`
5. Copy binaries mới sang `fabric-samples/bin/`
6. Set permissions cho binaries
7. Verify build thành công

**Khi nào cần build:**
- Sau khi modify source code trong `fabric-2.5.12/`
- Khi cần binaries mới nhất
- Sau khi pull updates từ Fabric repository

### `deploy-chaincode.sh` - Multi-Language Chaincode Deployment

Deploy và quản lý chaincode hỗ trợ nhiều ngôn ngữ:

**Cú pháp:**
```bash
./deploy-chaincode.sh [LANGUAGE] [ACTION]
```

**Ngôn ngữ hỗ trợ:**
- `go` - Go chaincode (mặc định)
- `javascript` - JavaScript chaincode
- `typescript` - TypeScript chaincode  
- `java` - Java chaincode

**Actions hỗ trợ:**
- `deploy` - Deploy chaincode mới (mặc định)
- `upgrade` - Upgrade chaincode hiện có
- `query` - Query chaincode (test read operations)
- `invoke` - Invoke chaincode transaction (test write operations)

**Ví dụ sử dụng:**
```bash
# Deploy Go chaincode mới
./deploy-chaincode.sh go deploy

# Upgrade JavaScript chaincode
./deploy-chaincode.sh javascript upgrade

# Test query operations
./deploy-chaincode.sh go query

# Test transaction operations
./deploy-chaincode.sh go invoke
```

## 🔍 Troubleshooting

### Vấn đề thường gặp:

**1. Network không khởi động được:**
```bash
# Clean toàn bộ và restart
./dev-manager.sh clean
./dev-manager.sh start
```

**2. Chaincode deploy failed:**
```bash
# Check logs để xem lỗi
./dev-manager.sh logs

# Redeploy chaincode
./deploy-chaincode.sh go deploy
```

**3. Binaries không hoạt động:**
```bash
# Rebuild binaries
./build-fabric.sh

# Hoặc restore từ backup
./dev-manager.sh restore
```

**4. Docker issues:**
```bash
# Check Docker status
docker ps
docker images

# Clean Docker
./dev-manager.sh clean
```

**5. Port conflicts:**
```bash
# Check ports đang sử dụng
netstat -tulpn | grep :7050
netstat -tulpn | grep :9443

# Stop conflicting services
./dev-manager.sh stop
```

### Debug logs:

**Xem logs chi tiết:**
```bash
# Logs tổng hợp
./dev-manager.sh logs

# Logs specific container
docker logs peer0.org1.example.com
docker logs orderer.example.com

# Follow logs real-time
docker logs -f peer0.org1.example.com
```

**Log files location:**
- Development logs: `logs/fabric_logs_YYYYMMDD_HHMMSS.log`
- Container logs: `docker logs [container_name]`

## 🎯 Best Practices

### Development Workflow:
1. **Luôn bắt đầu với status check**: `./dev-manager.sh status`
2. **Sử dụng backup trước khi thay đổi lớn**: `./dev-manager.sh backup`
3. **Clean environment khi có vấn đề**: `./dev-manager.sh clean`
4. **Rebuild binaries sau khi sửa core code**: `./build-fabric.sh`
5. **Test chaincode sau mỗi deployment**: `./deploy-chaincode.sh go query`

### Performance Tips:
- Sử dụng `restart` thay vì `clean + start` khi chỉ cần reset nhẹ
- Backup environment trước khi experiment
- Monitor logs để phát hiện issues sớm
- Sử dụng specific language deployment cho performance tốt hơn

### Security Notes:
- Đây là development environment, không dùng cho production
- Regularly clean up containers và images
- Backup important chaincode trước khi experiment

## 📚 Tài Liệu Tham Khảo

- [Hyperledger Fabric Documentation](https://hyperledger-fabric.readthedocs.io/)
- [Fabric Samples](https://github.com/hyperledger/fabric-samples)
- [Go Chaincode Tutorial](https://hyperledger-fabric.readthedocs.io/en/latest/chaincode4ade.html)
- [Network Deployment Guide](https://hyperledger-fabric.readthedocs.io/en/latest/deployment_guide_overview.html)

---

## 📋 Tóm Tắt Scripts

### ✅ Scripts Được Giữ Lại (3 scripts chính):

1. **`dev-manager.sh`** (7.0KB) - Script chính quản lý development environment
   - Chức năng: status, start, stop, restart, logs, clean, backup, restore, rebuild
   - Thay thế: start-network.sh, cleanup-build-fabric.sh, monitor-network.sh, restore-binaries.sh

2. **`build-fabric.sh`** (2.6KB) - Build Fabric binaries từ source
   - Chức năng: Build và copy binaries từ `fabric-2.5.12/build/bin/` sang `fabric-samples/bin/`
   - Critical cho development khi modify source code

3. **`deploy-chaincode.sh`** (6.6KB) - Deploy chaincode đa ngôn ngữ
   - Chức năng: Deploy/upgrade/query/invoke chaincode cho Go/JavaScript/TypeScript/Java
   - Thay thế: test-chaincode.sh

### ❌ Scripts Đã Loại Bỏ (5 scripts):

- **`start-network.sh`** - Functionality moved to `dev-manager.sh start`
- **`cleanup-build-fabric.sh`** - Functionality moved to `dev-manager.sh clean`
- **`test-chaincode.sh`** - Functionality moved to `deploy-chaincode.sh query/invoke`
- **`restore-binaries.sh`** - Functionality moved to `dev-manager.sh restore`
- **`monitor-network.sh`** - Functionality moved to `dev-manager.sh status`

## 🎯 Lợi Ích Của Việc Tối Ưu Scripts

### Trước (8 scripts):
- Phức tạp, dễ nhầm lẫn
- Chức năng overlap
- Khó maintain
- Cần nhớ nhiều lệnh

### Sau (3 scripts):
- ✅ **Đơn giản hóa**: Chỉ 3 scripts chính
- ✅ **Tích hợp**: Tất cả chức năng trong dev-manager.sh
- ✅ **Dễ nhớ**: start/stop/status/clean/backup/restore
- ✅ **Consistent**: Workflow chuẩn
- ✅ **Comprehensive**: Bao gồm logging, monitoring, backup

## ✅ Hoàn Thành Tối Ưu Scripts

### Kết Quả:
- **Giảm từ 8 scripts xuống 3 scripts chính**
- **Tất cả chức năng được tích hợp vào `dev-manager.sh`**
- **Workflow đơn giản và nhất quán**
- **Documentation đầy đủ và chi tiết**

### Script cuối cùng:
1. **`dev-manager.sh`** - All-in-one development environment manager
2. **`build-fabric.sh`** - Build binaries từ source
3. **`deploy-chaincode.sh`** - Multi-language chaincode deployment

### Test Scripts:
```bash
# Test dev-manager
./dev-manager.sh status

# Test build-fabric (nếu cần build mới)
./build-fabric.sh

# Test deploy-chaincode
./deploy-chaincode.sh go --help
```

---

*Tài liệu này được cập nhật sau khi tối ưu scripts vào ngày 16/06/2025*

