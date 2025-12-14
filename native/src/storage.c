#include "../include/storage.h"
#include "crypto.h"
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>
#include <stdio.h>
#include <errno.h>
#include <sys/stat.h>
#include <sys/types.h>

#ifdef _WIN32
  #include <direct.h>
  #include <io.h>
  #define mkdir(path, mode) _mkdir(path)
  #define stat _stat
  #define S_ISDIR(mode) (((mode) & _S_IFMT) == _S_IFDIR)
#else
  #include <unistd.h>
  #include <dirent.h>
#endif

  // File format:
// Each encrypted file: {storage_path}/{key_hash}.enc
// File structure:
// - IV (12 bytes)
// - Tag (16 bytes)
// - Ciphertext (variable length)
// Note: Salt is stored separately in {storage_path}/.salt

#define MAX_KEY_LEN 256
#define MAX_PATH_LEN 4096

typedef struct {
  bool initialized;
  uint8_t salt[SALT_SIZE];
  uint8_t key[KEY_SIZE];
  char* storage_path;
} StorageContext;

// Helper: Create directory if it doesn't exist
static bool ensure_directory_exists(const char* path) {
  struct stat st = {0};
  if (stat(path, &st) == -1) {
    // Directory doesn't exist, create it
    #ifdef _WIN32
      if (mkdir(path) != 0) {
        return false;
      }
    #else
      if (mkdir(path, 0700) != 0) {
        return false;
      }
    #endif
  } else if (!S_ISDIR(st.st_mode)) {
    // Path exists but is not a directory
    return false;
  }
  return true;
}

// Helper: Hash key to safe filename
static void hash_key_to_filename(const char* key, char* filename, size_t filename_size) {
  // Simple hash-based filename (in production, use proper hash like SHA256)
  // For now, use a simple approach: base64-like encoding
  size_t key_len = strlen(key);
  size_t i;
  for (i = 0; i < key_len && i < filename_size - 5; i++) {
    char c = key[i];
    // Replace unsafe characters
    if (c == '/' || c == '\\' || c == ':' || c == '*' || c == '?' || 
        c == '"' || c == '<' || c == '>' || c == '|') {
      filename[i] = '_';
    } else {
      filename[i] = c;
    }
  }
  filename[i] = '\0';
  strcat(filename, ".enc");
}

// Helper: Build full file path
static bool build_file_path(const char* storage_path, const char* key, char* file_path, size_t file_path_size) {
  char filename[MAX_KEY_LEN + 10];
  hash_key_to_filename(key, filename, sizeof(filename));
  
  #ifdef _WIN32
    snprintf(file_path, file_path_size, "%s\\%s", storage_path, filename);
  #else
    snprintf(file_path, file_path_size, "%s/%s", storage_path, filename);
  #endif
  
  return true;
}

FipersHandle fipers_init(const char* path, const char* passphrase, int32_t* error_code) {
  if (!path || !passphrase) {
    if (error_code) *error_code = FIPERS_ERROR_INVALID_DATA;
    return NULL;
  }
  
  StorageContext* ctx = (StorageContext*)calloc(1, sizeof(StorageContext));
  if (!ctx) {
    if (error_code) *error_code = FIPERS_ERROR_MEMORY;
    return NULL;
  }
  
  // Ensure storage directory exists
  if (!ensure_directory_exists(path)) {
    free(ctx);
    if (error_code) *error_code = FIPERS_ERROR_IO;
    return NULL;
  }
  
  // Load or generate salt
  // Salt is stored in {storage_path}/.salt file
  char salt_file_path[MAX_PATH_LEN];
  #ifdef _WIN32
    snprintf(salt_file_path, sizeof(salt_file_path), "%s\\.salt", path);
  #else
    snprintf(salt_file_path, sizeof(salt_file_path), "%s/.salt", path);
  #endif
  
  FILE* salt_file = fopen(salt_file_path, "rb");
  if (salt_file) {
    // Load existing salt
    if (fread(ctx->salt, 1, SALT_SIZE, salt_file) != SALT_SIZE) {
      fclose(salt_file);
      free(ctx);
      if (error_code) *error_code = FIPERS_ERROR_INIT;
      return NULL;
    }
    fclose(salt_file);
  } else {
    // Generate new salt
    if (!crypto_random_bytes(ctx->salt, SALT_SIZE)) {
      free(ctx);
      if (error_code) *error_code = FIPERS_ERROR_INIT;
      return NULL;
    }
    
    // Save salt to file
    salt_file = fopen(salt_file_path, "wb");
    if (salt_file) {
      fwrite(ctx->salt, 1, SALT_SIZE, salt_file);
      fclose(salt_file);
      // Set restrictive permissions (Unix only)
      #ifndef _WIN32
        chmod(salt_file_path, 0600);
      #endif
    }
  }
  
  // Derive encryption key from passphrase using PBKDF2
  if (!crypto_derive_key(passphrase, ctx->salt, ctx->key)) {
    free(ctx);
    if (error_code) *error_code = FIPERS_ERROR_INIT;
    return NULL;
  }
  
  // Store path
  size_t path_len = strlen(path);
  ctx->storage_path = (char*)malloc(path_len + 1);
  if (!ctx->storage_path) {
    free(ctx);
    if (error_code) *error_code = FIPERS_ERROR_MEMORY;
    return NULL;
  }
  strcpy(ctx->storage_path, path);
  
  ctx->initialized = true;
  
  if (error_code) *error_code = FIPERS_SUCCESS;
  return (FipersHandle)ctx;
}

bool fipers_put(
    FipersHandle handle,
    const char* key,
    const uint8_t* data,
    size_t data_len,
    int32_t* error_code
) {
  if (!handle) {
    if (error_code) *error_code = FIPERS_ERROR_NOT_INITIALIZED;
    return false;
  }
  
  StorageContext* ctx = (StorageContext*)handle;
  if (!ctx->initialized) {
    if (error_code) *error_code = FIPERS_ERROR_NOT_INITIALIZED;
    return false;
  }
  
  if (!key || !data || data_len == 0) {
    if (error_code) *error_code = FIPERS_ERROR_INVALID_DATA;
    return false;
  }
  
  // Build file path
  char file_path[MAX_PATH_LEN];
  if (!build_file_path(ctx->storage_path, key, file_path, sizeof(file_path))) {
    if (error_code) *error_code = FIPERS_ERROR_INVALID_KEY;
    return false;
  }
  
  // Encrypt data
  uint8_t iv[IV_SIZE];
  uint8_t tag[TAG_SIZE];
  size_t ciphertext_len = data_len; // GCM ciphertext length equals plaintext length
  uint8_t* ciphertext = (uint8_t*)malloc(ciphertext_len);
  if (!ciphertext) {
    if (error_code) *error_code = FIPERS_ERROR_MEMORY;
    return false;
  }
  
  if (!crypto_encrypt(data, data_len, ctx->key, iv, ciphertext, tag, &ciphertext_len)) {
    free(ciphertext);
    if (error_code) *error_code = FIPERS_ERROR_ENCRYPTION;
    return false;
  }
  
  // Write to file: IV + tag + ciphertext
  // Note: Salt is stored separately in {storage_path}/.salt
  FILE* file = fopen(file_path, "wb");
  if (!file) {
    free(ciphertext);
    if (error_code) *error_code = FIPERS_ERROR_IO;
    return false;
  }
  
  bool success = true;
  
  // Write IV
  if (fwrite(iv, 1, IV_SIZE, file) != IV_SIZE) {
    success = false;
  }
  
  // Write tag
  if (success && fwrite(tag, 1, TAG_SIZE, file) != TAG_SIZE) {
    success = false;
  }
  
  // Write ciphertext
  if (success && fwrite(ciphertext, 1, ciphertext_len, file) != ciphertext_len) {
    success = false;
  }
  
  fclose(file);
  free(ciphertext);
  
  if (!success) {
    // Remove partial file
    remove(file_path);
    if (error_code) *error_code = FIPERS_ERROR_IO;
    return false;
  }
  
  if (error_code) *error_code = FIPERS_SUCCESS;
  return true;
}

bool fipers_get(
    FipersHandle handle,
    const char* key,
    uint8_t** out_data,
    size_t* out_len,
    int32_t* error_code
) {
  if (!handle) {
    if (error_code) *error_code = FIPERS_ERROR_NOT_INITIALIZED;
    return false;
  }
  
  StorageContext* ctx = (StorageContext*)handle;
  if (!ctx->initialized) {
    if (error_code) *error_code = FIPERS_ERROR_NOT_INITIALIZED;
    return false;
  }
  
  if (!key || !out_data || !out_len) {
    if (error_code) *error_code = FIPERS_ERROR_INVALID_DATA;
    return false;
  }
  
  // Build file path
  char file_path[MAX_PATH_LEN];
  if (!build_file_path(ctx->storage_path, key, file_path, sizeof(file_path))) {
    if (error_code) *error_code = FIPERS_ERROR_INVALID_KEY;
    return false;
  }
  
  // Open file
  FILE* file = fopen(file_path, "rb");
  if (!file) {
    // File doesn't exist - key not found
    *out_data = NULL;
    *out_len = 0;
    if (error_code) *error_code = FIPERS_ERROR_INVALID_KEY;
    return false;
  }
  
  // Get file size
  fseek(file, 0, SEEK_END);
  long file_size = ftell(file);
  fseek(file, 0, SEEK_SET);
  
  if (file_size < (long)(IV_SIZE + TAG_SIZE)) {
    fclose(file);
    if (error_code) *error_code = FIPERS_ERROR_INVALID_DATA;
    return false;
  }
  
  size_t ciphertext_len = (size_t)(file_size - IV_SIZE - TAG_SIZE);
  
  // Read IV
  // Note: Salt is stored separately in {storage_path}/.salt and used from context
  uint8_t iv[IV_SIZE];
  if (fread(iv, 1, IV_SIZE, file) != IV_SIZE) {
    fclose(file);
    if (error_code) *error_code = FIPERS_ERROR_IO;
    return false;
  }
  
  // Read tag
  uint8_t tag[TAG_SIZE];
  if (fread(tag, 1, TAG_SIZE, file) != TAG_SIZE) {
    fclose(file);
    if (error_code) *error_code = FIPERS_ERROR_IO;
    return false;
  }
  
  // Read ciphertext
  uint8_t* ciphertext = (uint8_t*)malloc(ciphertext_len);
  if (!ciphertext) {
    fclose(file);
    if (error_code) *error_code = FIPERS_ERROR_MEMORY;
    return false;
  }
  
  if (fread(ciphertext, 1, ciphertext_len, file) != ciphertext_len) {
    free(ciphertext);
    fclose(file);
    if (error_code) *error_code = FIPERS_ERROR_IO;
    return false;
  }
  
  fclose(file);
  
  // Decrypt data
  size_t plaintext_len = ciphertext_len; // GCM plaintext length equals ciphertext length
  uint8_t* plaintext = (uint8_t*)malloc(plaintext_len);
  if (!plaintext) {
    free(ciphertext);
    if (error_code) *error_code = FIPERS_ERROR_MEMORY;
    return false;
  }
  
  if (!crypto_decrypt(ciphertext, ciphertext_len, ctx->key, iv, tag, plaintext, &plaintext_len)) {
    free(ciphertext);
    free(plaintext);
    if (error_code) *error_code = FIPERS_ERROR_DECRYPTION;
    return false;
  }
  
  free(ciphertext);
  
  *out_data = plaintext;
  *out_len = plaintext_len;
  
  if (error_code) *error_code = FIPERS_SUCCESS;
  return true;
}

bool fipers_delete(FipersHandle handle, const char* key, int32_t* error_code) {
  if (!handle) {
    if (error_code) *error_code = FIPERS_ERROR_NOT_INITIALIZED;
    return false;
  }
  
  StorageContext* ctx = (StorageContext*)handle;
  if (!ctx->initialized) {
    if (error_code) *error_code = FIPERS_ERROR_NOT_INITIALIZED;
    return false;
  }
  
  if (!key) {
    if (error_code) *error_code = FIPERS_ERROR_INVALID_KEY;
    return false;
  }
  
  // Build file path
  char file_path[MAX_PATH_LEN];
  if (!build_file_path(ctx->storage_path, key, file_path, sizeof(file_path))) {
    if (error_code) *error_code = FIPERS_ERROR_INVALID_KEY;
    return false;
  }
  
  // Delete file
  if (remove(file_path) != 0) {
    // File might not exist, but we'll consider it success
    // (idempotent operation)
  }
  
  if (error_code) *error_code = FIPERS_SUCCESS;
  return true;
}

void fipers_close(FipersHandle handle) {
  if (!handle) {
    return;
  }
  
  StorageContext* ctx = (StorageContext*)handle;
  if (ctx->storage_path) {
    free(ctx->storage_path);
  }
  
  // Clear sensitive data
  memset(ctx->key, 0, KEY_SIZE);
  free(ctx);
}

void fipers_free_data(uint8_t* data) {
  if (data) {
    free(data);
  }
}

