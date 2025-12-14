#include "crypto.h"
#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>

// OpenSSL includes
#include <openssl/evp.h>
#include <openssl/aes.h>
#include <openssl/rand.h>
#include <openssl/err.h>
#include <openssl/sha.h>

/// Derives encryption key from passphrase using PBKDF2-HMAC-SHA256
bool crypto_derive_key(
    const char* passphrase,
    const uint8_t* salt,
    uint8_t* key
) {
  if (!passphrase || !salt || !key) {
    return false;
  }

  // Use OpenSSL's EVP_PBE_scrypt or PKCS5_PBKDF2_HMAC
  // For compatibility, we'll use PKCS5_PBKDF2_HMAC_SHA256
  int result = PKCS5_PBKDF2_HMAC(
      passphrase,
      (int)strlen(passphrase),
      salt,
      SALT_SIZE,
      PBKDF2_ITERATIONS,
      EVP_sha256(),
      KEY_SIZE,
      key
  );

  return result == 1;
}

/// Encrypts data using AES-256-GCM
bool crypto_encrypt(
    const uint8_t* plaintext,
    size_t plaintext_len,
    const uint8_t* key,
    uint8_t* iv,
    uint8_t* ciphertext,
    uint8_t* tag,
    size_t* ciphertext_len
) {
  if (!plaintext || !key || !iv || !ciphertext || !tag || !ciphertext_len) {
    return false;
  }

  // Generate random IV
  if (!crypto_random_bytes(iv, IV_SIZE)) {
    return false;
  }

  // Create EVP context
  EVP_CIPHER_CTX* ctx = EVP_CIPHER_CTX_new();
  if (!ctx) {
    return false;
  }

  bool success = false;

  // Initialize encryption
  if (EVP_EncryptInit_ex(ctx, EVP_aes_256_gcm(), NULL, key, iv) != 1) {
    goto cleanup;
  }

  int outlen = 0;
  int total_outlen = 0;

  // Encrypt plaintext
  if (EVP_EncryptUpdate(ctx, ciphertext, &outlen, plaintext, (int)plaintext_len) != 1) {
    goto cleanup;
  }
  total_outlen = outlen;

  // Finalize encryption
  if (EVP_EncryptFinal_ex(ctx, ciphertext + outlen, &outlen) != 1) {
    goto cleanup;
  }
  total_outlen += outlen;

  // Get authentication tag
  if (EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_GET_TAG, TAG_SIZE, tag) != 1) {
    goto cleanup;
  }

  *ciphertext_len = (size_t)total_outlen;
  success = true;

cleanup:
  EVP_CIPHER_CTX_free(ctx);
  return success;
}

/// Decrypts data using AES-256-GCM
bool crypto_decrypt(
    const uint8_t* ciphertext,
    size_t ciphertext_len,
    const uint8_t* key,
    const uint8_t* iv,
    const uint8_t* tag,
    uint8_t* plaintext,
    size_t* plaintext_len
) {
  if (!ciphertext || !key || !iv || !tag || !plaintext || !plaintext_len) {
    return false;
  }

  // Create EVP context
  EVP_CIPHER_CTX* ctx = EVP_CIPHER_CTX_new();
  if (!ctx) {
    return false;
  }

  bool success = false;

  // Initialize decryption
  if (EVP_DecryptInit_ex(ctx, EVP_aes_256_gcm(), NULL, key, iv) != 1) {
    goto cleanup;
  }

  int outlen = 0;
  int total_outlen = 0;

  // Decrypt ciphertext
  if (EVP_DecryptUpdate(ctx, plaintext, &outlen, ciphertext, (int)ciphertext_len) != 1) {
    goto cleanup;
  }
  total_outlen = outlen;

  // Set expected tag for verification
  if (EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_TAG, TAG_SIZE, (void*)tag) != 1) {
    goto cleanup;
  }

  // Finalize decryption (this verifies the tag)
  if (EVP_DecryptFinal_ex(ctx, plaintext + outlen, &outlen) != 1) {
    // Tag verification failed
    goto cleanup;
  }
  total_outlen += outlen;

  *plaintext_len = (size_t)total_outlen;
  success = true;

cleanup:
  EVP_CIPHER_CTX_free(ctx);
  return success;
}

/// Generates cryptographically secure random bytes
bool crypto_random_bytes(uint8_t* buffer, size_t len) {
  if (!buffer || len == 0) {
    return false;
  }

  // Use OpenSSL's RAND_bytes
  return RAND_bytes(buffer, (int)len) == 1;
}
