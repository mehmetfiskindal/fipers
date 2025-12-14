#ifndef STORAGE_H
#define STORAGE_H

#include <stdbool.h>
#include <stdint.h>
#include <stddef.h>

// Windows DLL export
#ifdef _WIN32
  #ifdef FIPERS_EXPORTS
    #define FIPERS_API __declspec(dllexport)
  #else
    #define FIPERS_API __declspec(dllimport)
  #endif
#else
  #define FIPERS_API
#endif

#ifdef __cplusplus
extern "C" {
#endif

// Error codes
#define FIPERS_SUCCESS 0
#define FIPERS_ERROR_INIT -1
#define FIPERS_ERROR_NOT_INITIALIZED -2
#define FIPERS_ERROR_INVALID_KEY -3
#define FIPERS_ERROR_INVALID_DATA -4
#define FIPERS_ERROR_ENCRYPTION -5
#define FIPERS_ERROR_DECRYPTION -6
#define FIPERS_ERROR_IO -7
#define FIPERS_ERROR_MEMORY -8

// Opaque handle for storage instance
typedef void* FipersHandle;

/// Initializes a new storage instance.
///
/// [path] - Directory path where encrypted storage will be created
/// [passphrase] - Passphrase used for key derivation
/// [error_code] - Output parameter for error code (can be NULL)
///
/// Returns: Handle to storage instance, or NULL on failure
FIPERS_API FipersHandle fipers_init(const char* path, const char* passphrase, int32_t* error_code);

/// Stores encrypted data with the given key.
///
/// [handle] - Storage handle from fipers_init
/// [key] - Key identifier (null-terminated string)
/// [data] - Data to encrypt and store
/// [data_len] - Length of data in bytes
/// [error_code] - Output parameter for error code (can be NULL)
///
/// Returns: true on success, false on failure
FIPERS_API bool fipers_put(
    FipersHandle handle,
    const char* key,
    const uint8_t* data,
    size_t data_len,
    int32_t* error_code
);

/// Retrieves and decrypts data for the given key.
///
/// [handle] - Storage handle from fipers_init
/// [key] - Key identifier (null-terminated string)
/// [out_data] - Output buffer (caller must free with fipers_free_data)
/// [out_len] - Output parameter for data length
/// [error_code] - Output parameter for error code (can be NULL)
///
/// Returns: true on success, false on failure (key not found or error)
FIPERS_API bool fipers_get(
    FipersHandle handle,
    const char* key,
    uint8_t** out_data,
    size_t* out_len,
    int32_t* error_code
);

/// Deletes data associated with the given key.
///
/// [handle] - Storage handle from fipers_init
/// [key] - Key identifier (null-terminated string)
/// [error_code] - Output parameter for error code (can be NULL)
///
/// Returns: true on success, false on failure
FIPERS_API bool fipers_delete(FipersHandle handle, const char* key, int32_t* error_code);

/// Closes the storage and releases all resources.
///
/// [handle] - Storage handle from fipers_init (will be invalid after this call)
FIPERS_API void fipers_close(FipersHandle handle);

/// Frees data buffer returned by fipers_get.
///
/// [data] - Data buffer to free
FIPERS_API void fipers_free_data(uint8_t* data);

#ifdef __cplusplus
}
#endif

#endif // STORAGE_H

