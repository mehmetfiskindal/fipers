import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'bindings/storage_bindings.dart';
import 'fipers_interface.dart';

/// {@template fipers_native}
/// Native FFI implementation of Fipers encrypted persistent storage.
///
/// This implementation uses FFI to call native C functions for
/// encryption and storage operations.
/// {@endtemplate}
class FipersNative implements Fipers {
  /// {@macro fipers_native}
  FipersNative();

  final _bindings = StorageBindings.instance;
  Pointer? _handle;
  bool _initialized = false;

  @override
  Future<void> init(String path, String passphrase) async {
    if (_initialized) {
      throw StateError('Fipers is already initialized. Call close() first.');
    }

    try {
      final pathPtr = path.toNativeUtf8();
      final passphrasePtr = passphrase.toNativeUtf8();
      final errorCodePtr = malloc<Int32>();

      try {
        _handle = _bindings.fipersInit(
          pathPtr,
          passphrasePtr,
          errorCodePtr,
        );

        final errorCode = errorCodePtr.value;
        if (_handle == nullptr || errorCode != 0) {
          throw _createException(errorCode, 'Failed to initialize storage');
        }

        _initialized = true;
      } finally {
        malloc.free(pathPtr);
        malloc.free(passphrasePtr);
        malloc.free(errorCodePtr);
      }
    } catch (e) {
      _initialized = false;
      _handle = null;
      rethrow;
    }
  }

  @override
  Future<void> put(String key, Uint8List data) async {
    _ensureInitialized();

    final keyPtr = key.toNativeUtf8();
    final dataPtr = malloc<Uint8>(data.length);
    final errorCodePtr = malloc<Int32>();

    try {
      // Copy data to native memory
      dataPtr.asTypedList(data.length).setAll(0, data);

      final success =
          _bindings.fipersPut(
            _handle!,
            keyPtr,
            dataPtr,
            data.length,
            errorCodePtr,
          ) !=
          0;

      if (!success) {
        final errorCode = errorCodePtr.value;
        throw _createException(errorCode, 'Failed to store data for key: $key');
      }
    } finally {
      malloc.free(keyPtr);
      malloc.free(dataPtr);
      malloc.free(errorCodePtr);
    }
  }

  @override
  Future<Uint8List?> get(String key) async {
    _ensureInitialized();

    final keyPtr = key.toNativeUtf8();
    final outDataPtr = malloc<Pointer<Uint8>>();
    final outLenPtr = malloc<UintPtr>();
    final errorCodePtr = malloc<Int32>();

    try {
      final success =
          _bindings.fipersGet(
            _handle!,
            keyPtr,
            outDataPtr,
            outLenPtr,
            errorCodePtr,
          ) !=
          0;

      if (!success) {
        final errorCode = errorCodePtr.value;
        // Key not found is not an error, return null
        if (errorCode == -3) {
          // FIPERS_ERROR_INVALID_KEY
          return null;
        }
        throw _createException(
          errorCode,
          'Failed to retrieve data for key: $key',
        );
      }

      final dataPtr = outDataPtr.value;
      final dataLen = outLenPtr.value;

      if (dataPtr == nullptr || dataLen == 0) {
        return null;
      }

      // Copy data from native memory
      final data = Uint8List(dataLen);
      data.setAll(0, dataPtr.asTypedList(dataLen));

      // Free native memory
      _bindings.fipersFreeData(dataPtr);

      return data;
    } finally {
      malloc.free(keyPtr);
      malloc.free(outDataPtr);
      malloc.free(outLenPtr);
      malloc.free(errorCodePtr);
    }
  }

  @override
  Future<void> delete(String key) async {
    _ensureInitialized();

    final keyPtr = key.toNativeUtf8();
    final errorCodePtr = malloc<Int32>();

    try {
      final success =
          _bindings.fipersDelete(
            _handle!,
            keyPtr,
            errorCodePtr,
          ) !=
          0;

      if (!success) {
        final errorCode = errorCodePtr.value;
        throw _createException(
          errorCode,
          'Failed to delete data for key: $key',
        );
      }
    } finally {
      malloc.free(keyPtr);
      malloc.free(errorCodePtr);
    }
  }

  @override
  Future<void> close() async {
    if (_handle != null) {
      _bindings.fipersClose(_handle!);
      _handle = null;
    }
    _initialized = false;
  }

  void _ensureInitialized() {
    if (!_initialized || _handle == null) {
      throw StateError('Fipers is not initialized. Call init() first.');
    }
  }

  Exception _createException(int errorCode, String message) {
    switch (errorCode) {
      case -1: // FIPERS_ERROR_INIT
        return Exception('$message: Initialization error');
      case -2: // FIPERS_ERROR_NOT_INITIALIZED
        return Exception('$message: Not initialized');
      case -3: // FIPERS_ERROR_INVALID_KEY
        return Exception('$message: Invalid key');
      case -4: // FIPERS_ERROR_INVALID_DATA
        return Exception('$message: Invalid data');
      case -5: // FIPERS_ERROR_ENCRYPTION
        return Exception('$message: Encryption error');
      case -6: // FIPERS_ERROR_DECRYPTION
        return Exception('$message: Decryption error');
      case -7: // FIPERS_ERROR_IO
        return Exception('$message: I/O error');
      case -8: // FIPERS_ERROR_MEMORY
        return Exception('$message: Memory error');
      default:
        return Exception('$message: Unknown error (code: $errorCode)');
    }
  }
}

/// Factory function for creating a Fipers instance on native platforms.
Fipers createFipersInstance() => FipersNative();
