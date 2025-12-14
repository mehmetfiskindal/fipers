import 'dart:html' as html;
import 'dart:typed_data';

/// IndexedDB storage wrapper for web platform
class StorageWeb {
  static const String dbName = 'fipers_storage';
  static const int dbVersion = 1;
  static const String storeName = 'encrypted_data';

  html.IdbFactory? _idbFactory;
  html.Database? _db;

  /// Initialize IndexedDB
  Future<void> init(String path) async {
    _idbFactory = html.window.indexedDB;

    final request = _idbFactory!.open(dbName, version: dbVersion);

    request.onUpgradeNeeded.listen((event) {
      final db = (event.target as html.IdbOpenDbRequest).result as html.Database;
      if (!db.objectStoreNames.contains(storeName)) {
        db.createObjectStore(storeName);
      }
    });

    _db = await request.onSuccess.first.then((event) {
      return (event.target as html.IdbOpenDbRequest).result as html.Database;
    });
  }

  /// Store encrypted data
  Future<void> put(String key, Uint8List encryptedData) async {
    if (_db == null) {
      throw StateError('Storage not initialized. Call init() first.');
    }

    final transaction = _db!.transaction(storeName, 'readwrite');
    final store = transaction.objectStore(storeName);

    await store.put(encryptedData, key).future;
  }

  /// Retrieve encrypted data
  Future<Uint8List?> get(String key) async {
    if (_db == null) {
      throw StateError('Storage not initialized. Call init() first.');
    }

    final transaction = _db!.transaction(storeName, 'readonly');
    final store = transaction.objectStore(storeName);

    final request = store.getObject(key);
    final result = await request.future;

    if (result == null) {
      return null;
    }

    if (result is Uint8List) {
      return result;
    } else if (result is html.Blob) {
      // Convert Blob to Uint8List
      final reader = html.FileReader();
      reader.readAsArrayBuffer(result);
      await reader.onLoadEnd.first;
      return reader.result as Uint8List?;
    } else {
      throw Exception('Unexpected data type in storage');
    }
  }

  /// Delete encrypted data
  Future<void> delete(String key) async {
    if (_db == null) {
      throw StateError('Storage not initialized. Call init() first.');
    }

    final transaction = _db!.transaction(storeName, 'readwrite');
    final store = transaction.objectStore(storeName);

    await store.delete(key).future;
  }

  /// Close storage
  void close() {
    _db?.close();
    _db = null;
  }
}

