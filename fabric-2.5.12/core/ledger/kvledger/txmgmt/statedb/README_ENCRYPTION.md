# Encryption Integration with OpenSSL for Hyperledger Fabric

## Tổng quan

Tính năng này tích hợp mã hóa/giải mã sử dụng OpenSSL thông qua CGO trong Hyperledger Fabric, thay thế các thư viện mã hóa Go để:
- Tận dụng hiệu suất cao của OpenSSL
- Sử dụng các thuật toán mã hóa đã được kiểm chứng
- Dễ dàng thay đổi thuật toán mã hóa trong tương lai

## Cấu trúc file

```
statedb/
├── statedb.go          # File Go chính với CGO integration
├── encryption.c        # Các hàm mã hóa/giải mã C
├── encryption.h        # Header file cho các hàm C
├── Makefile            # Build script cho thư viện C
└── README_ENCRYPTION.md # Tài liệu này
```

## Cài đặt dependencies

### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install build-essential libssl-dev
```

### CentOS/RHEL
```bash
sudo yum groupinstall "Development Tools"
sudo yum install openssl-devel
```

### macOS
```bash
brew install openssl
```

## Biên dịch

1. Biên dịch thư viện C:
```bash
cd fabric-2.5.12/core/ledger/kvledger/txmgmt/statedb
make
```

2. Hoặc biên dịch thủ công:
```bash
gcc -Wall -Wextra -O2 -fPIC -c encryption.c -o encryption.o
gcc -shared -o libencryption.so encryption.o -lssl -lcrypto
```

## Sử dụng trong Go code

### Mã hóa/giải mã thủ công
```go
encryptedValue := statedb.EncryptValue([]byte("Hello World"))
decryptedValue := statedb.DecryptValue(encryptedValue)
```

### Tự động mã hóa/giải mã khi lưu/đọc state
```go
// Lưu dữ liệu (tự động mã hóa)
batch.Put("namespace", "key", []byte("sensitive data"), version)

// Đọc dữ liệu (tự động giải mã)
value := batch.Get("namespace", "key")
```

## Kiểm thử

### 1. Kiểm tra thư viện C
```bash
ls -la libencryption.so
ldd libencryption.so
make clean && make
```

### 2. Test Go với CGO
```bash
export CGO_ENABLED=1
go build ./...
```

### 3. Test chức năng mã hóa
Tạo file `test_encryption.go`:
```go
package main

import (
    "fmt"
    "log"
    "github.com/hyperledger/fabric/core/ledger/kvledger/txmgmt/statedb"
)

func main() {
    fmt.Println("=== Testing Encryption Integration ===")
    testData := []byte("Hello, this is a test message!")
    fmt.Printf("Original: %s\n", string(testData))
    encrypted := statedb.EncryptValue(testData)
    if encrypted == nil { log.Fatal("Encryption failed") }
    fmt.Printf("Encrypted length: %d\n", len(encrypted))
    decrypted := statedb.DecryptValue(encrypted)
    if decrypted == nil { log.Fatal("Decryption failed") }
    fmt.Printf("Decrypted: %s\n", string(decrypted))
    if string(decrypted) == string(testData) {
        fmt.Println("✅ Test PASSED!")
    } else {
        fmt.Println("❌ Test FAILED!")
    }
}
```
Chạy test:
```bash
go run test_encryption.go
```

### 4. Test UpdateBatch
Tạo file `test_batch.go`:
```go
package main

import (
    "fmt"
    "log"
    "github.com/hyperledger/fabric/core/ledger/internal/version"
    "github.com/hyperledger/fabric/core/ledger/kvledger/txmgmt/statedb"
)

func main() {
    fmt.Println("=== Testing UpdateBatch Encryption ===")
    batch := statedb.NewUpdateBatch()
    testValue := []byte("Sensitive data in batch")
    batch.Put("testns", "testkey", testValue, &version.Height{})
    fmt.Println("Data put into batch")
    retrieved := batch.Get("testns", "testkey")
    if retrieved == nil { log.Fatal("Failed to retrieve data") }
    fmt.Printf("Retrieved: %s\n", string(retrieved.Value))
    if string(retrieved.Value) == string(testValue) {
        fmt.Println("✅ UpdateBatch test PASSED!")
    } else {
        fmt.Println("❌ UpdateBatch test FAILED!")
    }
}
```
Chạy test:
```bash
go run test_batch.go
```

### 5. Test Unit/Integration/Performance
```bash
go test ./...
go test -v ./...
go test -cover ./...
go test -run TestEncryption ./...
go test -bench=. ./...
go test -bench=. -benchmem ./...
```

### 6. Test toàn bộ Fabric build
```bash
cd fabric-2.5.12
make build
go test ./core/ledger/kvledger/txmgmt/statedb/...
```

## Kiểm tra log peer để xác thực mã hóa/giải mã

Sau khi build lại peer và khởi động network, kiểm tra log để xác thực các hàm mã hóa/giải mã đã được gọi:
```bash
# Xem log peer (ví dụ với docker compose)
docker logs -f peer0.org1.example.com | grep ENCRYPT
docker logs -f peer0.org1.example.com | grep DECRYPT

# Hoặc kiểm tra toàn bộ log
docker logs -f peer0.org1.example.com

# Nếu peer ghi log ra file riêng (ví dụ /root/state_encryption.log)
docker exec peer0.org1.example.com cat /root/state_encryption.log
```
> Các hàm mã hóa/giải mã đã được thêm log, ví dụ:  
> `[ENCRYPT] EncryptValue called, input len=...`  
> `[DECRYPT] DecryptValue called, input len=...`

## Thuật toán mã hóa

- **Thuật toán**: AES-256-CBC
- **Padding**: PKCS7
- **Khóa**: 32 bytes cố định (chỉ dùng demo, KHÔNG dùng production)
- **IV**: Tự động tạo ngẫu nhiên

## Xử lý lỗi

- Nếu mã hóa/giải mã thất bại, hệ thống sẽ fallback về giá trị gốc
- Các lỗi được log để debug
- Không làm crash ứng dụng

## Bảo mật

⚠️ **Lưu ý quan trọng**:
- Khóa mã hóa hiện tại được hardcode (chỉ cho demo)
- Trong production, cần:
  - Lưu khóa trong HSM hoặc key management system
  - Sử dụng khóa động thay vì khóa cố định
  - Thêm IV ngẫu nhiên cho mỗi lần mã hóa

## Troubleshooting

### Lỗi biên dịch
```bash
pkg-config --modversion openssl
ldconfig -p | grep ssl
echo $CGO_ENABLED
which gcc
```

### Lỗi runtime
```bash
ldd libencryption.so
ls -la libencryption.so
go env CGO_ENABLED
```

### Lỗi test
```bash
go mod tidy
go list ./...
go test -v -x ./...
go env CGO_ENABLED
go env CC
go env CXX
```

### Lỗi CGO
- Đảm bảo CGO được enable: `export CGO_ENABLED=1`
- Kiểm tra compiler: `which gcc`

## Mở rộng

Để thêm thuật toán mã hóa mới:
1. Thêm hàm vào `encryption.c`
2. Cập nhật `encryption.h`
3. Thêm wrapper trong `statedb.go`
4. Cập nhật logic gọi hàm

## Performance

- OpenSSL được tối ưu hóa cho hiệu suất cao
- CGO có overhead nhỏ nhưng không đáng kể
- Có thể benchmark để so sánh với Go crypto

---

**Chỉ giữ lại file README này, có thể xóa các file hướng dẫn cũ khác để tránh trùng lặp.** 