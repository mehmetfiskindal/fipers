// Conditional import: dart:html is only available on web
import 'dart:html'
    if (dart.library.io) 'html_stub.dart'
    as html; // ignore: avoid_web_libraries_in_flutter
// Conditional import: dart:js is only available on web
import 'dart:js'
    if (dart.library.io) 'html_stub.dart'
    as js; // ignore: avoid_web_libraries_in_flutter
import 'dart:typed_data';

/// WebCrypto API wrapper for encryption operations
class CryptoWeb {
  static const int keySize = 32; // AES-256
  static const int ivSize = 12; // GCM IV size (96 bits)
  static const int tagSize = 16; // GCM tag size (128 bits)
  static const int saltSize = 32;
  static const int pbkdf2Iterations = 100000;

  /// Derives encryption key from passphrase using PBKDF2
  static Future<html.CryptoKey> deriveKey(
    String passphrase,
    Uint8List salt,
  ) async {
    final crypto = html.window.crypto;
    if (crypto == null) {
      throw StateError('WebCrypto API is not available');
    }

    // Convert passphrase to Uint8List
    final passphraseBytes = Uint8List.fromList(passphrase.codeUnits);

    // Import passphrase as key material
    // Access via js.JsObject since _SubtleCrypto methods aren't directly accessible
    final subtle = crypto.subtle;
    if (subtle == null) {
      throw StateError('WebCrypto Subtle API is not available');
    }

    final subtleObj = subtle as js.JsObject;
    final keyMaterial =
        await subtleObj.callMethod('importKey', [
              'raw',
              passphraseBytes.buffer,
              'PBKDF2',
              false,
              ['deriveBits', 'deriveKey'],
            ])
            as html.CryptoKey;

    // Derive key using PBKDF2
    final derivedKey =
        await subtleObj.callMethod('deriveKey', [
              {
                'name': 'PBKDF2',
                'salt': salt.buffer,
                'iterations': pbkdf2Iterations,
                'hash': 'SHA-256',
              },
              keyMaterial,
              {
                'name': 'AES-GCM',
                'length': keySize * 8, // bits
              },
              false,
              ['encrypt', 'decrypt'],
            ])
            as html.CryptoKey;

    return derivedKey;
  }

  /// Encrypts data using AES-256-GCM
  static Future<EncryptedData> encrypt(
    Uint8List plaintext,
    html.CryptoKey key,
  ) async {
    final crypto = html.window.crypto;
    if (crypto == null) {
      throw StateError('WebCrypto API is not available');
    }

    // Generate random IV
    final ivBuffer = Uint8List(ivSize);
    final ivTypedData = crypto.getRandomValues(ivBuffer);
    final iv = Uint8List.view(
      ivTypedData.buffer,
      ivTypedData.offsetInBytes,
      ivTypedData.lengthInBytes,
    );

    // Encrypt
    final subtle = crypto.subtle;
    if (subtle == null) {
      throw StateError('WebCrypto Subtle API is not available');
    }

    final subtleObj = subtle as js.JsObject;
    final ciphertextWithTagTypedData =
        await subtleObj.callMethod('encrypt', [
              {
                'name': 'AES-GCM',
                'iv': iv.buffer,
              },
              key,
              plaintext.buffer,
            ])
            as TypedData;

    final ciphertextWithTag = Uint8List.fromList(
      ciphertextWithTagTypedData.buffer.asUint8List(),
    );

    // Extract tag (last 16 bytes) and ciphertext
    // Note: WebCrypto API returns ciphertext + tag together
    // GCM mode automatically appends the tag
    final ciphertext = Uint8List(ciphertextWithTag.length - tagSize);
    final tag = Uint8List(tagSize);

    ciphertext.setRange(0, ciphertext.length, ciphertextWithTag);
    tag.setRange(0, tagSize, ciphertextWithTag, ciphertext.length);

    return EncryptedData(
      iv: iv,
      tag: tag,
      ciphertext: ciphertext,
    );
  }

  /// Decrypts data using AES-256-GCM
  static Future<Uint8List> decrypt(
    EncryptedData encrypted,
    html.CryptoKey key,
  ) async {
    final crypto = html.window.crypto;
    if (crypto == null) {
      throw StateError('WebCrypto API is not available');
    }

    // Combine ciphertext and tag
    // WebCrypto API expects ciphertext + tag together
    final ciphertextWithTag = Uint8List(encrypted.ciphertext.length + tagSize);
    ciphertextWithTag.setRange(
      0,
      encrypted.ciphertext.length,
      encrypted.ciphertext,
    );
    ciphertextWithTag.setRange(
      encrypted.ciphertext.length,
      ciphertextWithTag.length,
      encrypted.tag,
    );

    // Decrypt
    try {
      final subtle = crypto.subtle;
      if (subtle == null) {
        throw StateError('WebCrypto Subtle API is not available');
      }

      final subtleObj = subtle as js.JsObject;
      final plaintextTypedData =
          await subtleObj.callMethod('decrypt', [
                {
                  'name': 'AES-GCM',
                  'iv': encrypted.iv.buffer,
                },
                key,
                ciphertextWithTag.buffer,
              ])
              as TypedData;

      return Uint8List.fromList(plaintextTypedData.buffer.asUint8List());
    } catch (e) {
      throw Exception(
        'Decryption failed: Authentication tag verification failed',
      );
    }
  }

  /// Generates cryptographically secure random bytes
  static Uint8List randomBytes(int length) {
    final crypto = html.window.crypto;
    if (crypto == null) {
      throw StateError('WebCrypto API is not available');
    }

    final buffer = Uint8List(length);
    final typedData = crypto.getRandomValues(buffer);
    return Uint8List.view(
      typedData.buffer,
      typedData.offsetInBytes,
      typedData.lengthInBytes,
    );
  }
}

/// Encrypted data structure
class EncryptedData {
  final Uint8List iv;
  final Uint8List tag;
  final Uint8List ciphertext;

  EncryptedData({
    required this.iv,
    required this.tag,
    required this.ciphertext,
  });

  /// Serialize to Uint8List for storage
  Uint8List toBytes() {
    final result = Uint8List(iv.length + tag.length + ciphertext.length);
    var offset = 0;
    result.setRange(offset, offset + iv.length, iv);
    offset += iv.length;
    result.setRange(offset, offset + tag.length, tag);
    offset += tag.length;
    result.setRange(offset, offset + ciphertext.length, ciphertext);
    return result;
  }

  /// Deserialize from Uint8List
  factory EncryptedData.fromBytes(Uint8List data) {
    if (data.length < CryptoWeb.ivSize + CryptoWeb.tagSize) {
      throw Exception('Invalid encrypted data format');
    }

    final iv = Uint8List.sublistView(data, 0, CryptoWeb.ivSize);
    final tag = Uint8List.sublistView(
      data,
      CryptoWeb.ivSize,
      CryptoWeb.ivSize + CryptoWeb.tagSize,
    );
    final ciphertext = Uint8List.sublistView(
      data,
      CryptoWeb.ivSize + CryptoWeb.tagSize,
    );

    return EncryptedData(iv: iv, tag: tag, ciphertext: ciphertext);
  }
}
