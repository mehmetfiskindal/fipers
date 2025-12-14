// WASM-specific wrapper functions
// These functions are exported for WebAssembly and handle memory management

#include "../include/storage.h"
#include <emscripten.h>
#include <stdlib.h>
#include <string.h>

// Export functions for WASM
EMSCRIPTEN_KEEPALIVE
void* wasm_fipers_init(const char* path, const char* passphrase, int32_t* error_code) {
  return fipers_init(path, passphrase, error_code);
}

EMSCRIPTEN_KEEPALIVE
int32_t wasm_fipers_put(
    void* handle,
    const char* key,
    const uint8_t* data,
    int32_t data_len,
    int32_t* error_code
) {
  return fipers_put(handle, key, data, (size_t)data_len, error_code) ? 1 : 0;
}

EMSCRIPTEN_KEEPALIVE
int32_t wasm_fipers_get(
    void* handle,
    const char* key,
    uint8_t** out_data,
    int32_t* out_len,
    int32_t* error_code
) {
  size_t len = 0;
  bool success = fipers_get(handle, key, out_data, &len, error_code);
  if (success && out_len) {
    *out_len = (int32_t)len;
  }
  return success ? 1 : 0;
}

EMSCRIPTEN_KEEPALIVE
int32_t wasm_fipers_delete(void* handle, const char* key, int32_t* error_code) {
  return fipers_delete(handle, key, error_code) ? 1 : 0;
}

EMSCRIPTEN_KEEPALIVE
void wasm_fipers_close(void* handle) {
  fipers_close(handle);
}

EMSCRIPTEN_KEEPALIVE
void wasm_fipers_free_data(uint8_t* data) {
  fipers_free_data(data);
}

// Memory management helpers for WASM
EMSCRIPTEN_KEEPALIVE
char* wasm_malloc_string(int32_t len) {
  return (char*)malloc((size_t)len + 1);
}

EMSCRIPTEN_KEEPALIVE
void wasm_free_string(char* str) {
  free(str);
}

EMSCRIPTEN_KEEPALIVE
uint8_t* wasm_malloc_bytes(int32_t len) {
  return (uint8_t*)malloc((size_t)len);
}

EMSCRIPTEN_KEEPALIVE
void wasm_free_bytes(uint8_t* bytes) {
  free(bytes);
}

