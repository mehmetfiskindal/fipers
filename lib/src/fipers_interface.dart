import 'dart:typed_data';

/// {@template fipers_interface}
/// Abstract interface for Fipers encrypted persistent storage.
///
/// This interface defines the contract that all platform implementations
/// must follow. It provides methods for initializing, storing, retrieving,
/// and deleting encrypted data.
/// {@endtemplate}
abstract class Fipers {
  /// Initializes the storage with a path and passphrase.
  ///
  /// The [path] specifies where the encrypted storage should be located.
  /// The [passphrase] is used to derive encryption keys.
  ///
  /// Throws an exception if initialization fails.
  Future<void> init(String path, String passphrase);

  /// Stores encrypted data with the given [key].
  ///
  /// The [data] will be encrypted before being stored.
  ///
  /// Throws an exception if the storage is not initialized or if the operation fails.
  Future<void> put(String key, Uint8List data);

  /// Retrieves and decrypts data for the given [key].
  ///
  /// Returns `null` if the key does not exist.
  ///
  /// Throws an exception if the storage is not initialized or if decryption fails.
  Future<Uint8List?> get(String key);

  /// Deletes the data associated with the given [key].
  ///
  /// Throws an exception if the storage is not initialized or if the operation fails.
  Future<void> delete(String key);

  /// Closes the storage and releases all resources.
  ///
  /// After calling this method, the storage instance should not be used.
  Future<void> close();
}

