import 'dart:html' as html;
import 'dart:typed_data';

import 'fipers_interface.dart';
import 'web/crypto_web.dart';
import 'web/storage_web.dart';

/// {@template fipers_web}
/// Web implementation of Fipers using WebCrypto API and IndexedDB.
///
/// This implementation uses:
/// - WebCrypto API for AES-256-GCM encryption
/// - PBKDF2 for key derivation
/// - IndexedDB for persistent storage
///
/// For better performance with large data, consider using [FipersWebWasm]
/// which uses WebAssembly for encryption operations.
/// {@endtemplate}
class FipersWeb implements Fipers {
  /// {@macro fipers_web}
  FipersWeb();

  final _storage = StorageWeb();
  String? _passphrase;
  Uint8List? _salt;
  html.CryptoKey? _derivedKey;
  bool _initialized = false;

  @override
  Future<void> init(String path, String passphrase) async {
    if (_initialized) {
      throw StateError('Fipers is already initialized. Call close() first.');
    }

    try {
      // Initialize IndexedDB storage
      await _storage.init(path);

      // Load or generate salt
      _salt = await _loadOrGenerateSalt(path);

      // Derive encryption key from passphrase
      _derivedKey = await CryptoWeb.deriveKey(passphrase, _salt!);
      _passphrase = passphrase;

      _initialized = true;
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

    // Encrypt data
    final encrypted = await CryptoWeb.encrypt(data, _derivedKey!);

    // Store encrypted data (IV + Tag + Ciphertext)
    await _storage.put(key, encrypted.toBytes());
  }

  @override
  Future<Uint8List?> get(String key) async {
    _ensureInitialized();

    if (key.isEmpty) {
      throw ArgumentError('Key must not be empty');
    }

    // Retrieve encrypted data
    final encryptedBytes = await _storage.get(key);
    if (encryptedBytes == null) {
      return null;
    }

    // Deserialize encrypted data
    final encrypted = EncryptedData.fromBytes(encryptedBytes);

    // Decrypt data
    try {
      return await CryptoWeb.decrypt(encrypted, _derivedKey!);
    } catch (e) {
      throw Exception('Failed to decrypt data for key: $key. ${e.toString()}');
    }
  }

  @override
  Future<void> delete(String key) async {
    _ensureInitialized();

    if (key.isEmpty) {
      throw ArgumentError('Key must not be empty');
    }

    await _storage.delete(key);
  }

  @override
  Future<void> close() async {
    _storage.close();
    _derivedKey = null;
    _passphrase = null;
    _salt = null;
    _initialized = false;
  }

  void _ensureInitialized() {
    if (!_initialized || _derivedKey == null) {
      throw StateError('Fipers is not initialized. Call init() first.');
    }
  }

  /// Load salt from localStorage or generate new one
  Future<Uint8List> _loadOrGenerateSalt(String path) async {
    // Use path as part of localStorage key to support multiple storage instances
    final saltKey = 'fipers_salt_${_hashPath(path)}';

    // Try to load existing salt from localStorage
    final storedSalt = html.window.localStorage[saltKey];
    if (storedSalt != null) {
      // Decode from base64
      try {
        return Uint8List.fromList(
          Uri.decodeComponent(storedSalt).codeUnits,
        );
      } catch (e) {
        // If decoding fails, generate new salt
      }
    }

    // Generate new salt
    final salt = CryptoWeb.randomBytes(CryptoWeb.saltSize);

    // Store salt in localStorage
    html.window.localStorage[saltKey] = String.fromCharCodes(salt);

    return salt;
  }

  /// Simple hash function for path (for localStorage key)
  String _hashPath(String path) {
    // Simple hash - in production, use proper hash function
    var hash = 0;
    for (var i = 0; i < path.length; i++) {
      hash = ((hash << 5) - hash) + path.codeUnitAt(i);
      hash = hash & hash; // Convert to 32-bit integer
    }
    return hash.abs().toString();
  }
}
