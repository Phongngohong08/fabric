#ifndef ENCRYPTION_H
#define ENCRYPTION_H

#ifdef __cplusplus
extern "C" {
#endif

// Hàm mã hóa AES-256-CBC
int encrypt_aes_cbc(const unsigned char *plaintext, int plaintext_len, 
                    unsigned char *ciphertext, int *ciphertext_len);

// Hàm giải mã AES-256-CBC
int decrypt_aes_cbc(const unsigned char *ciphertext, int ciphertext_len,
                    unsigned char *plaintext, int *plaintext_len);

// Hàm tạo IV ngẫu nhiên
int generate_random_iv(unsigned char *iv, int iv_len);

#ifdef __cplusplus
}
#endif

#endif // ENCRYPTION_H 