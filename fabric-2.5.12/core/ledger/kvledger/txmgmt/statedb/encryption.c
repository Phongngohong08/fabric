#include <openssl/evp.h>
#include <openssl/rand.h>
#include <string.h>
#include <stdlib.h>

// Khóa mã hóa cố định cho demo (trong thực tế nên lưu an toàn)
static const unsigned char ENCRYPTION_KEY[32] = "my32digitkey12345678901234567890";

// Hàm mã hóa AES-256-CBC
int encrypt_aes_cbc(const unsigned char *plaintext, int plaintext_len, 
                    unsigned char *ciphertext, int *ciphertext_len) {
    EVP_CIPHER_CTX *ctx;
    int len;
    int ciphertext_len_final;

    // Tạo context cho cipher
    if (!(ctx = EVP_CIPHER_CTX_new())) {
        return -1;
    }

    // Khởi tạo encryption operation
    if (1 != EVP_EncryptInit_ex(ctx, EVP_aes_256_cbc(), NULL, ENCRYPTION_KEY, NULL)) {
        EVP_CIPHER_CTX_free(ctx);
        return -1;
    }

    // Thực hiện encryption
    if (1 != EVP_EncryptUpdate(ctx, ciphertext, &len, plaintext, plaintext_len)) {
        EVP_CIPHER_CTX_free(ctx);
        return -1;
    }
    ciphertext_len_final = len;

    // Finalize encryption
    if (1 != EVP_EncryptFinal_ex(ctx, ciphertext + len, &len)) {
        EVP_CIPHER_CTX_free(ctx);
        return -1;
    }
    ciphertext_len_final += len;

    // Clean up
    EVP_CIPHER_CTX_free(ctx);
    *ciphertext_len = ciphertext_len_final;
    return 0;
}

// Hàm giải mã AES-256-CBC
int decrypt_aes_cbc(const unsigned char *ciphertext, int ciphertext_len,
                    unsigned char *plaintext, int *plaintext_len) {
    EVP_CIPHER_CTX *ctx;
    int len;
    int plaintext_len_final;

    // Tạo context cho cipher
    if (!(ctx = EVP_CIPHER_CTX_new())) {
        return -1;
    }

    // Khởi tạo decryption operation
    if (1 != EVP_DecryptInit_ex(ctx, EVP_aes_256_cbc(), NULL, ENCRYPTION_KEY, NULL)) {
        EVP_CIPHER_CTX_free(ctx);
        return -1;
    }

    // Thực hiện decryption
    if (1 != EVP_DecryptUpdate(ctx, plaintext, &len, ciphertext, ciphertext_len)) {
        EVP_CIPHER_CTX_free(ctx);
        return -1;
    }
    plaintext_len_final = len;

    // Finalize decryption
    if (1 != EVP_DecryptFinal_ex(ctx, plaintext + len, &len)) {
        EVP_CIPHER_CTX_free(ctx);
        return -1;
    }
    plaintext_len_final += len;

    // Clean up
    EVP_CIPHER_CTX_free(ctx);
    *plaintext_len = plaintext_len_final;
    return 0;
}

// Hàm tạo IV ngẫu nhiên
int generate_random_iv(unsigned char *iv, int iv_len) {
    return RAND_bytes(iv, iv_len);
} 