# Fipers

FFI-based encrypted persistent storage for Flutter (multi-platform).

## Overview

Fipers provides encrypted persistent storage using native FFI (Foreign Function Interface) for maximum performance and security. It supports Android, iOS, macOS, Linux, and Windows platforms. Web platform is not supported as FFI is not available.

## Features

- ✅ **Multi-platform support**: Android, iOS, macOS, Linux, Windows, Web
- ✅ **FFI-based (Native)**: Direct native code execution for performance on native platforms
- ✅ **WebCrypto (Web)**: Native browser API for encryption on web platform
- ✅ **Encrypted storage**: AES-256-GCM encryption (OpenSSL on native, WebCrypto on web)
- ✅ **PBKDF2 key derivation**: Secure passphrase-based key derivation (100,000 iterations)
- ✅ **Type-safe**: Full TypeScript-style type safety
- ✅ **Platform-aware**: Automatic platform detection and implementation selection
- ✅ **Persistent storage**: File-based on native platforms, IndexedDB on web

## Architecture

### Platform Support Matrix

| Platform | Native FFI | Encryption | Storage | WASM | Status |
|----------|------------|------------|---------|------|--------|
| Android  | ✅          | ✅          | ✅       | ❌    | Supported |
| iOS      | ✅          | ✅          | ✅       | ❌    | Supported |
| macOS    | ✅          | ✅          | ✅       | ❌    | Supported |
| Linux    | ✅          | ✅          | ✅       | ❌    | Supported |
| Windows  | ✅          | ✅          | ✅       | ❌    | Supported |
| Web      | ❌          | ✅ (WebCrypto/WASM) | ✅ (IndexedDB) | ✅ (Optional) | Supported |

### Implementation Strategy

- **Native platforms**: Uses FFI to call native C functions (OpenSSL) for encryption and file-based storage
- **Web platform**: Uses WebCrypto API for encryption and IndexedDB for persistent storage

## Usage

### Basic Example

```dart
import 'package:fipers/fipers.dart';
import 'dart:typed_data';

void main() async {
  // Create platform-specific instance
  final fipers = createFipers();
  
  // Initialize with storage path and passphrase
  await fipers.init('/path/to/storage', 'my-secret-passphrase');
  
  // Store encrypted data
  final data = Uint8List.fromList([1, 2, 3, 4, 5]);
  await fipers.put('my-key', data);
  
  // Retrieve and decrypt data
  final retrieved = await fipers.get('my-key');
  print('Retrieved: $retrieved');
  
  // Delete data
  await fipers.delete('my-key');
  
  // Close and release resources
  await fipers.close();
}
```

## API Reference

### `Fipers` Interface

```dart
abstract class Fipers {
  /// Initializes the storage with a path and passphrase
  Future<void> init(String path, String passphrase);
  
  /// Stores encrypted data with the given key
  Future<void> put(String key, Uint8List data);
  
  /// Retrieves and decrypts data for the given key
  /// Returns null if key does not exist
  Future<Uint8List?> get(String key);
  
  /// Deletes the data associated with the given key
  Future<void> delete(String key);
  
  /// Closes the storage and releases all resources
  Future<void> close();
}
```

### Factory Function

```dart
/// Creates a platform-specific instance of Fipers
Fipers createFipers();
```

## Native Implementation

### C API

The native C API is defined in `native/include/storage.h`:

- `fipers_init()` - Initialize storage
- `fipers_put()` - Store encrypted data
- `fipers_get()` - Retrieve and decrypt data
- `fipers_delete()` - Delete data
- `fipers_close()` - Close storage
- `fipers_free_data()` - Free data buffer

### Build Configuration

#### Android

CMakeLists.txt is configured in `android/CMakeLists.txt`. For Android, the native library needs to be integrated into your Android project's build system.

#### Linux/Windows

CMakeLists.txt files are in `linux/CMakeLists.txt` and `windows/CMakeLists.txt`.

#### iOS/macOS

Native code is compiled via Xcode project configuration (to be implemented).

## Development

### Project Structure

```
fipers/
├── lib/
│   ├── fipers.dart              # Public API with conditional exports
│   └── src/
│       ├── fipers_interface.dart    # Abstract interface
│       ├── fipers_native.dart       # FFI implementation
│       ├── fipers_web.dart          # Web stub
│       └── bindings/
│           └── storage_bindings.dart # FFI bindings
├── native/
│   ├── include/
│   │   └── storage.h           # C API header
│   └── src/
│       ├── storage.c           # Storage implementation
│       ├── crypto.c            # Encryption implementation
│       └── crypto.h            # Crypto header
├── android/
│   └── CMakeLists.txt          # Android build config
├── linux/
│   └── CMakeLists.txt          # Linux build config
├── windows/
│   └── CMakeLists.txt          # Windows build config
└── ffigen.yaml                 # FFI bindings generation config
```

### Building Native Code

#### Using Build Scripts (Recommended)

**Linux/macOS:**
```bash
cd fipers/scripts
./build.sh android Release
./build.sh linux Release
```

**Windows (PowerShell):**
```powershell
cd fipers\scripts
.\build.ps1 -Platform windows -BuildType Release
```

#### Manual Build

**Android:**
```bash
cd fipers/android
mkdir build && cd build
cmake .. -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK/build/cmake/android.toolchain.cmake
cmake --build .
```

**Linux:**
```bash
cd fipers/linux
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build .
```

**Windows:**
```bash
cd fipers/windows
mkdir build && cd build
cmake .. -G "Visual Studio 17 2022" -A x64
cmake --build . --config Release
```

**iOS/macOS:**
```bash
cd example/ios  # or example/macos
pod install
# Build via Xcode or Flutter
flutter build ios  # or flutter build macos
```

### Performance Testing

Fipers includes comprehensive performance tests to measure the efficiency of storage operations:

```bash
# Run all performance tests
flutter test test/performance_test.dart

# Run with detailed output
flutter test test/performance_test.dart --reporter expanded
```

The performance test suite includes:
- Initialization performance
- Put/Get operations with different data sizes (1KB, 100KB, 1MB)
- Delete operations
- Batch operations (100+ items)
- Mixed operations (Put/Get/Delete combinations)
- Concurrent operations
- Memory efficiency with large datasets

See `test/PERFORMANCE.md` for detailed performance metrics and expected values.

### Prerequisites

- **OpenSSL**: Required for all platforms
  - Linux: `sudo apt-get install libssl-dev` (Ubuntu/Debian) or `sudo yum install openssl-devel` (RHEL/CentOS)
  - macOS: `brew install openssl` or use CocoaPods dependency
  - Windows: Install OpenSSL or use vcpkg
  - Android: Included via NDK or CMake find_package

- **CMake**: Version 3.18.1 or higher
- **C Compiler**: GCC, Clang, or MSVC

### Generating FFI Bindings

```bash
dart run ffigen --config ffigen.yaml
```

### Building WebAssembly Module

**Prerequisites:**
- Emscripten SDK installed (https://emscripten.org/docs/getting_started/downloads.html)

**Build:**
```bash
cd fipers/scripts
./build_wasm.sh
```

This will generate:
- `lib/src/web/assets/fipers.js` - JavaScript loader
- `lib/src/web/assets/fipers.wasm` - WebAssembly binary

**Usage:**
```dart
import 'package:fipers/fipers.dart';
import 'package:fipers/src/web/fipers_web_wasm.dart';

// Use WASM implementation for better performance
final fipers = FipersWebWasm();
await fipers.init('/storage', 'passphrase');
```

## Roadmap

### Phase 1 ✅
- [x] Interface definition
- [x] Native FFI implementation
- [x] Web stub implementation
- [x] Platform detection and conditional exports
- [x] Basic C API implementation

### Phase 2 ✅
- [x] OpenSSL integration for AES-256-GCM
- [x] File-based persistent storage
- [x] PBKDF2 key derivation
- [x] Secure random IV generation
- [x] Android CMake build integration
- [x] Linux/Windows build automation

### Phase 3 ✅
- [x] iOS/macOS CocoaPods configuration
- [x] Build script automation
- [x] Integration tests
- [x] Documentation updates

### Phase 4 ✅
- [x] WebCrypto API implementation for Web platform
- [x] IndexedDB storage for Web platform
- [x] Full web platform support

### Phase 5 ✅
- [x] WebAssembly (WASM) support for better performance
- [x] WASM build scripts and tooling
- [x] WASM loader implementation

### Phase 6 (Future)
- [ ] Passphrase rotation
- [ ] Key derivation optimization
- [ ] Performance benchmarks
- [ ] CI/CD pipeline (GitHub Actions)

## Security Notes

✅ **Production Ready**: The implementation uses:
- **AES-256-GCM** encryption (OpenSSL on native, WebCrypto on web)
- **PBKDF2-HMAC-SHA256** key derivation (100,000 iterations)
- **Secure random IV** generation for each encryption
- **Authentication tags** for integrity verification
- **Salt-based key derivation** for passphrase security

### Security Best Practices

- Use strong, unique passphrases
- Store the `.salt` file securely (it's required for decryption)
- Regularly backup encrypted storage directory
- Consider implementing passphrase rotation for long-term storage

## Contributing

This project follows Very Good Analysis standards and TypeScript/Flutter best practices.

## License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.
