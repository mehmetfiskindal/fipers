import 'dart:async';
// Conditional import: dart:html is only available on web
import 'dart:html'
    if (dart.library.io) 'html_stub.dart'
    as html; // ignore: avoid_web_libraries_in_flutter
// Conditional import: dart:js is only available on web
import 'dart:js'
    if (dart.library.io) 'html_stub.dart'
    as js; // ignore: avoid_web_libraries_in_flutter
import 'dart:typed_data';

/// IndexedDB storage wrapper for web platform
class StorageWeb {
  static const String dbName = 'fipers_storage';
  static const int dbVersion = 1;
  static const String storeName = 'encrypted_data';

  dynamic _idbFactory;
  dynamic _db;

  /// Initialize IndexedDB
  Future<void> init(String path) async {
    final idbFactory = html.window.indexedDB;
    if (idbFactory == null) {
      throw StateError('IndexedDB is not available');
    }

    _idbFactory = idbFactory;
    // Use dart:js to access JavaScript IndexedDB API directly
    // html.window.indexedDB.open() returns Future<Database>, not IdbOpenDbRequest
    // We need to use JavaScript API directly to get version support
    // Access indexedDB through js.context using Function.apply
    final indexedDBFunc = js.context.callMethod('eval', ['window.indexedDB']);
    if (indexedDBFunc == null) {
      throw StateError('IndexedDB is not available in JavaScript context');
    }
    final indexedDBJs = indexedDBFunc as js.JsObject;
    // Call indexedDB.open(name, version) using callMethod
    final openRequestJs = indexedDBJs.callMethod('open', [dbName, dbVersion]) as js.JsObject;
    final openRequest = openRequestJs;

    // Handle upgrade needed using event handler
    // JavaScript IndexedDB uses event handlers, not streams
    // Access onupgradeneeded property using bracket notation
    openRequest['onupgradeneeded'] = (html.Event event) {
      try {
        final request = event.target;
        if (request != null) {
          // Use dynamic access since IdbOpenDbRequest types may not be available
          final db = (request as dynamic).result;
          if (db != null) {
            // Check if object store already exists and create if needed
            try {
              final objectStoreNames = (db as dynamic).objectStoreNames;
              if (objectStoreNames != null) {
                final containsResult = objectStoreNames.contains(storeName);
                if (containsResult != true) {
                  // Create object store without keyPath (use key directly)
                  (db as dynamic).createObjectStore(storeName);
                }
              }
            } catch (e) {
              // If check fails, try to create the store anyway
              // This might fail if store already exists, which is fine
              try {
                (db as dynamic).createObjectStore(storeName);
              } catch (e2) {
                // Store might already exist, ignore error
              }
            }
          }
        }
      } catch (e) {
        // Log error but don't fail initialization
        print('Warning: Failed to upgrade IndexedDB: $e');
      }
    };

    // Wait for success or error event
    final completer = Completer<dynamic>();
    String? errorMessage;

    // Listen for error event
    openRequest['onerror'] = (html.Event event) {
      if (!completer.isCompleted) {
        final request = event.target;
        if (request != null) {
          final error = (request as dynamic).error;
          if (error != null) {
            errorMessage = 'Failed to open IndexedDB: $error';
          } else {
            errorMessage = 'Failed to open IndexedDB: unknown error';
          }
        } else {
          errorMessage = 'Failed to open IndexedDB: error event target is null';
        }
        completer.completeError(StateError(errorMessage!));
      }
    };

    // Listen for success event
    openRequest['onsuccess'] = (html.Event event) {
      if (!completer.isCompleted) {
        try {
          final request = event.target;
          if (request != null) {
            final db = (request as dynamic).result;
            if (db != null) {
              completer.complete(db);
            } else {
              completer.completeError(
                StateError('Failed to open IndexedDB: result is null'),
              );
            }
          } else {
            completer.completeError(
              StateError('Failed to open IndexedDB: target is null'),
            );
          }
        } catch (e) {
          completer.completeError(
            Exception('Error handling IndexedDB success: $e'),
          );
        }
      }
    };

    // Wait for completion with timeout
    _db = await completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw StateError(
          'IndexedDB initialization timed out after 10 seconds',
        );
      },
    );
  }

  /// Store encrypted data
  Future<void> put(String key, Uint8List encryptedData) async {
    if (_db == null) {
      throw StateError('Storage not initialized. Call init() first.');
    }

    final transaction = (_db as dynamic).transaction(storeName, 'readwrite');
    final store = transaction.objectStore(storeName);

    // Store data with key (IndexedDB will use key as the primary key)
    final request = store.put(encryptedData, key);

    final completer = Completer<void>();
    request.onSuccess.listen((_) => completer.complete());
    request.onError.listen((html.Event event) {
      completer.completeError(
        Exception('Failed to store data: ${event.target}'),
      );
    });
    await completer.future;
  }

  /// Retrieve encrypted data
  Future<Uint8List?> get(String key) async {
    if (_db == null) {
      throw StateError('Storage not initialized. Call init() first.');
    }

    final transaction = (_db as dynamic).transaction(storeName, 'readonly');
    final store = transaction.objectStore(storeName);
    final request = store.get(key);

    final completer = Completer<Uint8List?>();
    request.onSuccess.listen((html.Event event) {
      try {
        final req = event.target;
        if (req != null) {
          final result = (req as dynamic).result;

          if (result == null) {
            completer.complete(null);
            return;
          }

          // Result should be Uint8List or Blob
          if (result is Uint8List) {
            completer.complete(result);
          } else if (result is html.Blob) {
            // Convert Blob to Uint8List
            final reader = html.FileReader();
            reader.onLoadEnd.listen((_) {
              final arrayBuffer = reader.result;
              if (arrayBuffer != null && arrayBuffer is TypedData) {
                completer.complete(
                  Uint8List.view(
                    arrayBuffer.buffer,
                    arrayBuffer.offsetInBytes,
                    arrayBuffer.lengthInBytes,
                  ),
                );
              } else {
                completer.complete(null);
              }
            });
            reader.readAsArrayBuffer(result);
          } else {
            completer.complete(null);
          }
        } else {
          completer.complete(null);
        }
      } catch (e) {
        completer.completeError(
          Exception('Failed to retrieve data: $e'),
        );
      }
    });
    request.onError.listen((html.Event event) {
      completer.completeError(
        Exception('Failed to retrieve data: ${event.target}'),
      );
    });

    return await completer.future;
  }

  /// Delete encrypted data
  Future<void> delete(String key) async {
    if (_db == null) {
      throw StateError('Storage not initialized. Call init() first.');
    }

    final transaction = (_db as dynamic).transaction(storeName, 'readwrite');
    final store = transaction.objectStore(storeName);
    final request = store.delete(key);

    final completer = Completer<void>();
    request.onSuccess.listen((_) => completer.complete());
    request.onError.listen((html.Event event) {
      completer.completeError(
        Exception('Failed to delete data: ${event.target}'),
      );
    });
    await completer.future;
  }

  /// Close storage
  void close() {
    _db?.close();
    _db = null;
  }
}
