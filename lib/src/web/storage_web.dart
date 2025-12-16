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
    // Check if we're actually on web platform
    // On native platforms, html_stub.dart is used which returns null for indexedDB
    final idbFactory = html.window.indexedDB;
    if (idbFactory == null) {
      throw StateError(
        'IndexedDB is not available. This implementation is only for web platform. '
        'On native platforms, use FipersNative instead.',
      );
    }

    _idbFactory = idbFactory;
    // Use dart:html's IndexedDB API with js interop for event handling
    // Convert html.IdbFactory to js.JsObject to access low-level API
    final indexedDBJs = idbFactory as js.JsObject;
    // Call indexedDB.open(name, version) using callMethod
    final openRequestJs =
        indexedDBJs.callMethod('open', [dbName, dbVersion]) as js.JsObject;
    final openRequest = openRequestJs;

    // Handle upgrade needed using event handler
    // JavaScript IndexedDB uses event handlers, not streams
    // Event handler receives the event object directly (not html.Event)
    (openRequest as dynamic).onupgradeneeded = (dynamic event) {
      try {
        // In IndexedDB, event.target is the request itself
        final request = event?.target ?? event;
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
    (openRequest as dynamic).onerror = (dynamic event) {
      if (!completer.isCompleted) {
        // In IndexedDB, event.target is the request itself
        final request = event?.target ?? event;
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
    (openRequest as dynamic).onsuccess = (dynamic event) {
      if (!completer.isCompleted) {
        try {
          // In IndexedDB, event.target is the request itself
          final request = event?.target ?? event;
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
    (request as dynamic).onsuccess = (dynamic event) {
      completer.complete();
    };
    (request as dynamic).onerror = (dynamic event) {
      final error = (event?.target ?? event)?.error ?? event;
      completer.completeError(
        Exception('Failed to store data: $error'),
      );
    };
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
    (request as dynamic).onsuccess = (dynamic event) {
      try {
        // In IndexedDB, event.target is the request itself
        final req = event?.target ?? event;
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
    };
    (request as dynamic).onerror = (dynamic event) {
      final error = (event?.target ?? event)?.error ?? event;
      completer.completeError(
        Exception('Failed to retrieve data: $error'),
      );
    };

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
    (request as dynamic).onsuccess = (dynamic event) {
      completer.complete();
    };
    (request as dynamic).onerror = (dynamic event) {
      final error = (event?.target ?? event)?.error ?? event;
      completer.completeError(
        Exception('Failed to delete data: $error'),
      );
    };
    await completer.future;
  }

  /// Close storage
  void close() {
    _db?.close();
    _db = null;
  }
}
