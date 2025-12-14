import 'dart:typed_data';

import 'fipers_interface.dart';

/// Stub implementation for unsupported platforms
class FipersStub implements Fipers {
  FipersStub() {
    throw UnsupportedError(
      'Fipers is not supported on this platform. '
      'FFI or HTML library is required.',
    );
  }

  @override
  Future<void> init(String path, String passphrase) async {
    throw UnsupportedError('Not supported');
  }

  @override
  Future<void> put(String key, Uint8List data) async {
    throw UnsupportedError('Not supported');
  }

  @override
  Future<Uint8List?> get(String key) async {
    throw UnsupportedError('Not supported');
  }

  @override
  Future<void> delete(String key) async {
    throw UnsupportedError('Not supported');
  }

  @override
  Future<void> close() async {
    throw UnsupportedError('Not supported');
  }
}

