import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:typed_data';

import '../fipers_interface.dart';
import 'storage_web.dart';
import 'wasm_loader.dart';

/// {@template fipers_web_wasm}
/// Web implementation of Fipers using WebAssembly (WASM) for encryption.
///
/// This implementation uses:
/// - WebAssembly module for AES-256-GCM encryption (same C code as native)
/// - IndexedDB for persistent storage
/// - Better performance than WebCrypto API for large data
/// {@endtemplate}
class FipersWebWasm implements Fipers {
  /// {@macro fipers_web_wasm}
  FipersWebWasm();

  final _storage = StorageWeb();
  int? _handle; // WASM handle pointer
  bool _initialized = false;

  @override
  Future<void> init(String path, String passphrase) async {
    if (_initialized) {
      throw StateError('Fipers is already initialized. Call close() first.');
    }

    try {
      // Initialize WASM module
      await WasmLoader.init();

      // Initialize IndexedDB storage
      await _storage.init(path);

      // Allocate strings in WASM memory
      final pathPtr = WasmLoader.allocateString(path);
      final passphrasePtr = WasmLoader.allocateString(passphrase);

      try {
        // Allocate error code
        final errorCodePtr = WasmLoader.allocateBytes(Uint8List(4));

        // Call WASM init function
        final handle = WasmLoader.callFunction('wasm_fipers_init', [
          pathPtr,
          passphrasePtr,
          errorCodePtr,
        ]);

        // Check error code
        final errorCode = WasmLoader.readBytes(errorCodePtr, 4);
        final error = _bytesToInt32(errorCode);

        WasmLoader.freeBytes(errorCodePtr);

        if (handle == 0 || error != 0) {
          throw Exception('Failed to initialize WASM storage: error code $error');
        }

        _handle = handle as int;
        _initialized = true;
      } finally {
        WasmLoader.freeString(pathPtr);
        WasmLoader.freeString(passphrasePtr);
      }
    } catch (e) {
      _initialized = false;
      rethrow;
    }
  }

  @override
  Future<void> put(String key, Uint8List data) async {
    _ensureInitialized();

    if (key.isEmpty || data.isEmpty) {
      throw ArgumentError('Key and data must not be empty');
    }

    // Allocate strings and data in WASM memory
    final keyPtr = WasmLoader.allocateString(key);
    final dataPtr = WasmLoader.allocateBytes(data);

    try {
      // Allocate error code
      final errorCodePtr = WasmLoader.allocateBytes(Uint8List(4));

      // Call WASM put function
      final success = WasmLoader.callFunction('wasm_fipers_put', [
        _handle,
        keyPtr,
        dataPtr,
        data.length,
        errorCodePtr,
      ]);

      // Check error code
      final errorCode = WasmLoader.readBytes(errorCodePtr, 4);
      final error = _bytesToInt32(errorCode);

      WasmLoader.freeBytes(errorCodePtr);

      if (success == 0 || error != 0) {
        throw Exception('Failed to store data: error code $error');
      }

      // Read encrypted data from WASM (this would need to be implemented)
      // For now, we'll use a different approach - store directly
      // TODO: Implement encrypted data retrieval from WASM
    } finally {
      WasmLoader.freeString(keyPtr);
      WasmLoader.freeBytes(dataPtr);
    }
  }

  @override
  Future<Uint8List?> get(String key) async {
    _ensureInitialized();

    if (key.isEmpty) {
      throw ArgumentError('Key must not be empty');
    }

    // Allocate strings in WASM memory
    final keyPtr = WasmLoader.allocateString(key);

    try {
      // Allocate output pointers
      final outDataPtrPtr = WasmLoader.allocateBytes(Uint8List(4)); // pointer to pointer
      final outLenPtr = WasmLoader.allocateBytes(Uint8List(4));
      final errorCodePtr = WasmLoader.allocateBytes(Uint8List(4));

      // Call WASM get function
      final success = WasmLoader.callFunction('wasm_fipers_get', [
        _handle,
        keyPtr,
        outDataPtrPtr,
        outLenPtr,
        errorCodePtr,
      ]);

      // Check error code
      final errorCode = WasmLoader.readBytes(errorCodePtr, 4);
      final error = _bytesToInt32(errorCode);

      WasmLoader.freeBytes(errorCodePtr);

      if (success == 0) {
        if (error == -3) {
          // Key not found
          return null;
        }
        throw Exception('Failed to retrieve data: error code $error');
      }

      // Read output data pointer and length
      final outDataPtr = _bytesToInt32(WasmLoader.readBytes(outDataPtrPtr, 4));
      final outLen = _bytesToInt32(WasmLoader.readBytes(outLenPtr, 4));

      WasmLoader.freeBytes(outDataPtrPtr);
      WasmLoader.freeBytes(outLenPtr);

      if (outDataPtr == 0 || outLen == 0) {
        return null;
      }

      // Read data from WASM memory
      final data = WasmLoader.readBytes(outDataPtr, outLen);

      // Free WASM memory
      WasmLoader.callFunction('wasm_fipers_free_data', [outDataPtr]);

      return data;
    } finally {
      WasmLoader.freeString(keyPtr);
    }
  }

  @override
  Future<void> delete(String key) async {
    _ensureInitialized();

    if (key.isEmpty) {
      throw ArgumentError('Key must not be empty');
    }

    // Allocate string in WASM memory
    final keyPtr = WasmLoader.allocateString(key);

    try {
      // Allocate error code
      final errorCodePtr = WasmLoader.allocateBytes(Uint8List(4));

      // Call WASM delete function
      final success = WasmLoader.callFunction('wasm_fipers_delete', [
        _handle,
        keyPtr,
        errorCodePtr,
      ]);

      // Check error code
      final errorCode = WasmLoader.readBytes(errorCodePtr, 4);
      final error = _bytesToInt32(errorCode);

      WasmLoader.freeBytes(errorCodePtr);

      if (success == 0 || error != 0) {
        throw Exception('Failed to delete data: error code $error');
      }
    } finally {
      WasmLoader.freeString(keyPtr);
    }
  }

  @override
  Future<void> close() async {
    if (_handle != null) {
      WasmLoader.callFunction('wasm_fipers_close', [_handle]);
      _handle = null;
    }
    _storage.close();
    _initialized = false;
  }

  void _ensureInitialized() {
    if (!_initialized || _handle == null) {
      throw StateError('Fipers is not initialized. Call init() first.');
    }
  }

  int _bytesToInt32(Uint8List bytes) {
    return (bytes[0] |
            (bytes[1] << 8) |
            (bytes[2] << 16) |
            (bytes[3] << 24)) &
        0xFFFFFFFF;
  }

  Uint8List _int32ToBytes(int value) {
    return Uint8List.fromList([
      value & 0xFF,
      (value >> 8) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 24) & 0xFF,
    ]);
  }
}

