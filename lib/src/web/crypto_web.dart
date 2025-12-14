import 'dart:html' as html;
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
    // Convert passphrase to Uint8List
    final passphraseBytes = Uint8List.fromList(passphrase.codeUnits);

    // Import passphrase as key material
    final keyMaterial = await html.window.crypto.subtle.importKey(
      'raw',
      passphraseBytes.buffer,
      'PBKDF2',
      false,
      ['deriveBits', 'deriveKey'],
    );

    // Derive key using PBKDF2
    final derivedKey = await html.window.crypto.subtle.deriveKey(
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
    );

    return derivedKey;
  }

  /// Encrypts data using AES-256-GCM
  static Future<EncryptedData> encrypt(
    Uint8List plaintext,
    html.CryptoKey key,
  ) async {
    // Generate random IV
    final iv = html.window.crypto.getRandomValues(Uint8List(ivSize));

    // Encrypt
    final ciphertextWithTag = await html.window.crypto.subtle.encrypt(
      {
        'name': 'AES-GCM',
        'iv': iv.buffer,
      },
      key,
      plaintext.buffer,
    ) as Uint8List;

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
    // Combine ciphertext and tag
    // WebCrypto API expects ciphertext + tag together
    final ciphertextWithTag = Uint8List(encrypted.ciphertext.length + tagSize);
    ciphertextWithTag.setRange(0, encrypted.ciphertext.length, encrypted.ciphertext);
    ciphertextWithTag.setRange(
      encrypted.ciphertext.length,
      ciphertextWithTag.length,
      encrypted.tag,
    );

    // Decrypt
    try {
      final plaintext = await html.window.crypto.subtle.decrypt(
        {
          'name': 'AES-GCM',
          'iv': encrypted.iv.buffer,
        },
        key,
        ciphertextWithTag.buffer,
      ) as Uint8List;

      return plaintext;
    } catch (e) {
      throw Exception('Decryption failed: Authentication tag verification failed');
    }
  }

  /// Generates cryptographically secure random bytes
  static Uint8List randomBytes(int length) {
    return html.window.crypto.getRandomValues(Uint8List(length));
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
