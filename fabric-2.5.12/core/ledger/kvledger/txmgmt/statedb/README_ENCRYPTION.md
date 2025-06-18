# Encryption Integration with OpenSSL

Tài liệu này mô tả cách tích hợp mã hóa/giải mã sử dụng thư viện OpenSSL thông qua CGO trong Hyperledger Fabric.

## Tổng quan

Thay vì sử dụng các thư viện mã hóa của Go, chúng ta đã tích hợp OpenSSL thông qua CGO để:
- Tận dụng hiệu suất cao của OpenSSL
- Sử dụng các thuật toán mã hóa đã được kiểm chứng
- Dễ dàng thay đổi thuật toán mã hóa trong tương lai

## Cấu trúc file

```
statedb/
├── statedb.go          # File Go chính với CGO integration
├── encryption.c        # Các hàm mã hóa/giải mã C
├── encryption.h        # Header file cho các hàm C
├── Makefile           # Build script cho thư viện C
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

2. Hoặc biên dịch trực tiếp:
```bash
gcc -Wall -Wextra -O2 -fPIC -c encryption.c -o encryption.o
gcc -shared -o libencryption.so encryption.o -lssl -lcrypto
```

## Chạy Test

### 1. Test biên dịch thư viện C
```bash
# Kiểm tra thư viện đã biên dịch thành công
ls -la libencryption.so

# Kiểm tra dependencies
ldd libencryption.so

# Test biên dịch lại
make clean && make
```

### 2. Test Go với CGO
```bash
# Đảm bảo CGO được enable
export CGO_ENABLED=1

# Test biên dịch Go package
go build -o test_statedb .

# Hoặc test chỉ package
go build ./...
```

### 3. Test chức năng mã hóa
Tạo file test đơn giản `test_encryption.go`:

```go
package main

import (
    "fmt"
    "log"
)

// Import package statedb
import "github.com/hyperledger/fabric/core/ledger/kvledger/txmgmt/statedb"

func main() {
    fmt.Println("=== Testing Encryption Integration ===")
    
    // Test data
    testData := []byte("Hello, this is a test message!")
    fmt.Printf("Original: %s\n", string(testData))
    
    // Test encryption
    encrypted := statedb.EncryptValue(testData)
    if encrypted == nil {
        log.Fatal("Encryption failed")
    }
    fmt.Printf("Encrypted length: %d\n", len(encrypted))
    
    // Test decryption
    decrypted := statedb.DecryptValue(encrypted)
    if decrypted == nil {
        log.Fatal("Decryption failed")
    }
    fmt.Printf("Decrypted: %s\n", string(decrypted))
    
    // Verify
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
Tạo file test `test_batch.go`:

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
    
    // Create batch
    batch := statedb.NewUpdateBatch()
    testValue := []byte("Sensitive data in batch")
    
    // Put data (should be encrypted)
    batch.Put("testns", "testkey", testValue, &version.Height{})
    fmt.Println("Data put into batch")
    
    // Get data (should be decrypted)
    retrieved := batch.Get("testns", "testkey")
    if retrieved == nil {
        log.Fatal("Failed to retrieve data")
    }
    
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

### 5. Test Unit Tests
```bash
# Chạy tất cả tests trong package
go test ./...

# Chạy test với verbose output
go test -v ./...

# Chạy test với coverage
go test -cover ./...

# Chạy test cụ thể
go test -run TestEncryption ./...
```

### 6. Test Performance
```bash
# Benchmark tests
go test -bench=. ./...

# Benchmark với memory allocation
go test -bench=. -benchmem ./...
```

## Sử dụng

### Trong Go code

```go
// Mã hóa dữ liệu
encryptedValue := encryptValue([]byte("Hello World"))

// Giải mã dữ liệu
decryptedValue := decryptValue(encryptedValue)
```

### Trong UpdateBatch

```go
// Khi lưu dữ liệu (tự động mã hóa)
batch.Put("namespace", "key", []byte("sensitive data"), version)

// Khi đọc dữ liệu (tự động giải mã)
value := batch.Get("namespace", "key")
```

## Thuật toán mã hóa

Hiện tại sử dụng:
- **Thuật toán**: AES-256-CBC
- **Padding**: PKCS7
- **Khóa**: 32 bytes cố định (trong thực tế nên lưu an toàn)

## Cấu hình CGO

Trong file `statedb.go`:

```go
/*
#cgo CFLAGS: -I.
#cgo LDFLAGS: -L. -lssl -lcrypto
#include "encryption.h"
#include <stdlib.h>
*/
import "C"
```

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
# Kiểm tra OpenSSL đã cài đặt
pkg-config --modversion openssl

# Kiểm tra thư viện
ldconfig -p | grep ssl

# Kiểm tra CGO
echo $CGO_ENABLED
which gcc
```

### Lỗi runtime
```bash
# Kiểm tra thư viện động
ldd libencryption.so

# Kiểm tra quyền truy cập
ls -la libencryption.so

# Kiểm tra Go build
go env CGO_ENABLED
```

### Lỗi test
```bash
# Kiểm tra dependencies
go mod tidy

# Kiểm tra import paths
go list ./...

# Chạy test với debug
go test -v -x ./...
```

## Mở rộng

Để thêm thuật toán mã hóa mới:

1. Thêm hàm vào `encryption.c`
2. Cập nhật `encryption.h`
3. Thêm wrapper trong `statedb.go`
4. Cập nhật logic gọi hàm

## Performance

- OpenSSL được tối ưu hóa cho hiệu suất cao
- CGO có overhead nhỏ nhưng không đáng kể so với lợi ích
- Có thể benchmark để so sánh với Go crypto 