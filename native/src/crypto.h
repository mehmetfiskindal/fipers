#ifndef CRYPTO_H
#define CRYPTO_H

#include <stdbool.h>
#include <stdint.h>
#include <stddef.h>

#define KEY_SIZE 32      // AES-256 key size
#define IV_SIZE 12       // GCM IV size (96 bits)
#define TAG_SIZE 16      // GCM tag size (128 bits)
#define PBKDF2_ITERATIONS 100000  // PBKDF2 iteration count
#define SALT_SIZE 32     // Salt size for PBKDF2

/// Derives encryption key from passphrase using PBKDF2-HMAC-SHA256
///
/// [passphrase] - Passphrase string
/// [salt] - Salt bytes (SALT_SIZE bytes)
/// [key] - Output key buffer (KEY_SIZE bytes)
///
/// Returns: true on success, false on failure
bool crypto_derive_key(
    const char* passphrase,
    const uint8_t* salt,
    uint8_t* key
);

/// Encrypts data using AES-256-GCM
///
/// [plaintext] - Input plaintext data
/// [plaintext_len] - Length of plaintext
/// [key] - Encryption key (KEY_SIZE bytes)
/// [iv] - Output IV buffer (IV_SIZE bytes, will be generated)
/// [ciphertext] - Output ciphertext buffer (must be at least plaintext_len bytes)
/// [tag] - Output authentication tag (TAG_SIZE bytes)
/// [ciphertext_len] - Output parameter for ciphertext length
///
/// Returns: true on success, false on failure
bool crypto_encrypt(
    const uint8_t* plaintext,
    size_t plaintext_len,
    const uint8_t* key,
    uint8_t* iv,
    uint8_t* ciphertext,
    uint8_t* tag,
    size_t* ciphertext_len
);

/// Decrypts data using AES-256-GCM
///
/// [ciphertext] - Input ciphertext data
/// [ciphertext_len] - Length of ciphertext
/// [key] - Decryption key (KEY_SIZE bytes)
/// [iv] - IV used for encryption (IV_SIZE bytes)
/// [tag] - Authentication tag (TAG_SIZE bytes)
/// [plaintext] - Output plaintext buffer (must be at least ciphertext_len bytes)
/// [plaintext_len] - Output parameter for plaintext length
///
/// Returns: true on success, false on failure (authentication failure or other error)
bool crypto_decrypt(
    const uint8_t* ciphertext,
    size_t ciphertext_len,
    const uint8_t* key,
    const uint8_t* iv,
    const uint8_t* tag,
    uint8_t* plaintext,
    size_t* plaintext_len
);

/// Generates cryptographically secure random bytes
///
/// [buffer] - Output buffer
/// [len] - Number of bytes to generate
///
/// Returns: true on success, false on failure
bool crypto_random_bytes(uint8_t* buffer, size_t len);

#endif // CRYPTO_H

