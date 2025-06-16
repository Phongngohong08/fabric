# Hyperledger Fabric Build & Test - Quick Start

## 🎯 Mục đích
Hướng dẫn nhanh để build Fabric binaries và chạy test network thành công.

## 📋 Yêu cầu hệ thống
- **OS**: Linux (Ubuntu/Debian)
- **Go**: 1.19+ (đã test với Go 1.23.5)
- **Docker**: 20.10+
- **Docker Compose**: v2.24+
- **Git**: Để clone source code

## 🚀 Các bước thực hiện (3 bước chính)

### Bước 1: Cài đặt môi trường
```bash
# Cài đặt Go (nếu chưa có)
wget https://go.dev/dl/go1.23.5.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.23.5.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc

# Cài đặt Docker Compose v2
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.6/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# Kiểm tra versions
go version
docker --version
docker-compose --version
```

### Bước 2: Build Fabric binaries
```bash
# Build binaries từ source
chmod +x build-fabric.sh
./build-fabric.sh
```

### Bước 3: Chạy test network
```bash
# Start test network với chaincode
chmod +x start-network.sh
./start-network.sh
```

## ✅ Kết quả mong đợi

Sau khi chạy thành công, bạn sẽ thấy:
```
🧪 Testing chaincode...
Initializing ledger with sample data...
2025-06-16 21:03:33.555 +07 0001 INFO [chaincodeCmd] chaincodeInvokeOrQuery -> Chaincode invoke successful. result: status:200 

Querying asset1...
✅ Chaincode test successful!
📋 Asset1 data: {"AppraisedValue":300,"Color":"blue","ID":"asset1","Owner":"Tomoko","Size":5}

🎉 Test network is ready!
```

## 🔧 Scripts có sẵn

### Build Scripts
- `build-fabric.sh` - Build Fabric binaries từ source
- `cleanup-build-fabric.sh` - Clean up build artifacts

### Network Scripts  
- `start-network.sh` - Start test network + deploy chaincode
- `deploy-chaincode.sh` - Deploy chaincode (Go/JS/TS/Java)
- `dev-manager.sh` - Quản lý development environment

## 🛠️ Troubleshooting nhanh

### Lỗi Docker Compose
```bash
# Nếu gặp lỗi distutils
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.6/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### Lỗi Go Module
```bash
# Trong thư mục fabric-2.5.12
go mod tidy
go mod vendor
```

### Lỗi Permission
```bash
# Set permissions cho scripts
chmod +x *.sh
```

## 📁 Cấu trúc thư mục

```
fabric/
├── build-fabric.sh           # Build Fabric binaries
├── start-network.sh          # Start test network  
├── cleanup-build-fabric.sh   # Cleanup script
├── deploy-chaincode.sh       # Deploy chaincode
├── dev-manager.sh           # Development manager
├── fabric-2.5.12/           # Fabric source code
│   └── build/bin/           # Built binaries
└── fabric-samples/          # Test network & samples
    ├── bin/                 # Runtime binaries
    └── test-network/        # Test network configs
```

---
🎉 **Tất cả đã sẵn sàng để phát triển Hyperledger Fabric!**
