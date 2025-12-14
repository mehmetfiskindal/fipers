#!/bin/bash
# Build script for WebAssembly module
# Requires Emscripten SDK

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
NATIVE_DIR="$PROJECT_ROOT/native"
OUTPUT_DIR="$PROJECT_ROOT/lib/src/web/assets"

echo "Building WebAssembly module for Fipers..."

# Check if Emscripten is available
if ! command -v emcc &> /dev/null; then
  echo "Error: Emscripten not found. Please install Emscripten SDK."
  echo "Visit: https://emscripten.org/docs/getting_started/downloads.html"
  exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Build WASM module
cd "$NATIVE_DIR"

emcc \
  -O2 \
  -s WASM=1 \
  -s EXPORTED_RUNTIME_METHODS='["ccall","cwrap","UTF8ToString","stringToUTF8","_malloc","_free"]' \
  -s EXPORTED_FUNCTIONS='["_wasm_fipers_init","_wasm_fipers_put","_wasm_fipers_get","_wasm_fipers_delete","_wasm_fipers_close","_wasm_fipers_free_data","_wasm_malloc_string","_wasm_free_string","_wasm_malloc_bytes","_wasm_free_bytes"]' \
  -s ALLOW_MEMORY_GROWTH=1 \
  -s INITIAL_MEMORY=16777216 \
  -s MODULARIZE=1 \
  -s EXPORT_NAME='createFipersModule' \
  -s USE_OPENSSL=1 \
  -I./include \
  src/storage.c \
  src/crypto.c \
  src/storage_wasm.c \
  -o "$OUTPUT_DIR/fipers.js"

echo "WebAssembly build complete!"
echo "Output files:"
echo "  - $OUTPUT_DIR/fipers.js"
echo "  - $OUTPUT_DIR/fipers.wasm"

