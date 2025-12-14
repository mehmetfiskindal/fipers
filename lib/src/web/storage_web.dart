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
    _idbFactory = html.window.indexedDB;
    if (_idbFactory == null) {
      throw StateError('IndexedDB is not available');
    }

    final idbFactory = _idbFactory as js.JsObject;
    final openRequest =
        idbFactory.callMethod('open', [dbName, dbVersion]) as js.JsObject;

    // Handle upgrade needed using event stream
    // This event fires when the database version is upgraded or created
    (openRequest as dynamic).onUpgradeNeeded.listen((html.Event event) {
      try {
        final target = event.target;
        if (target != null) {
          final request = target as js.JsObject;
          final db = request['result'] as js.JsObject;

          // Check if object store already exists and create if needed
          try {
            final objectStoreNames = db['objectStoreNames'];
            if (objectStoreNames != null) {
              final objectStoreNamesObj = objectStoreNames as js.JsObject;
              final containsResult = objectStoreNamesObj.callMethod(
                'contains',
                [
                  storeName,
                ],
              );

              if (containsResult != true) {
                // Create object store without keyPath (use key directly)
                db.callMethod('createObjectStore', [storeName]);
              }
            }
          } catch (e) {
            // If check fails, try to create the store anyway
            // This might fail if store already exists, which is fine
            try {
              db.callMethod('createObjectStore', [storeName]);
            } catch (e2) {
              // Store might already exist, ignore error
            }
          }
        }
      } catch (e) {
        // Log error but don't fail initialization
        print('Warning: Failed to upgrade IndexedDB: $e');
      }
    });

    // Wait for success or error event
    final completer = Completer<dynamic>();
    String? errorMessage;

    // Listen for error event
    (openRequest as dynamic).onError.listen((html.Event event) {
      if (!completer.isCompleted) {
        final target = event.target;
        if (target != null) {
          final request = target as js.JsObject;
          final error = request['error'];
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
    });

    // Listen for success event
    (openRequest as dynamic).onSuccess.listen((html.Event event) {
      if (!completer.isCompleted) {
        try {
          final target = event.target;
          if (target != null) {
            final request = target as js.JsObject;
            final db = request['result'];
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
    });

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

    final db = _db as js.JsObject;
    final transaction =
        db.callMethod('transaction', [storeName, 'readwrite']) as js.JsObject;
    final store =
        transaction.callMethod('objectStore', [storeName]) as js.JsObject;

    // Store data with key (IndexedDB will use key as the primary key)
    final request =
        store.callMethod('put', [encryptedData, key]) as js.JsObject;

    final completer = Completer<void>();
    (request as dynamic).onSuccess = (_) => completer.complete();
    (request as dynamic).onError = (html.Event event) {
      completer.completeError(
        Exception('Failed to store data: ${event.target}'),
      );
    };
    await completer.future;
  }

  /// Retrieve encrypted data
  Future<Uint8List?> get(String key) async {
    if (_db == null) {
      throw StateError('Storage not initialized. Call init() first.');
    }

    final db = _db as js.JsObject;
    final transaction =
        db.callMethod('transaction', [storeName, 'readonly']) as js.JsObject;
    final store =
        transaction.callMethod('objectStore', [storeName]) as js.JsObject;
    final request = store.callMethod('get', [key]) as js.JsObject;

    final completer = Completer<Uint8List?>();
    (request as dynamic).onSuccess = (html.Event event) {
      try {
        final target = event.target;
        if (target != null) {
          final req = target as js.JsObject;
          final result = req['result'];

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
          } else if (result is js.JsObject) {
            // Try to extract data from JsObject (for backward compatibility)
            final data = result['data'];
            if (data is Uint8List) {
              completer.complete(data);
            } else {
              completer.complete(null);
            }
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
    (request as dynamic).onError = (html.Event event) {
      completer.completeError(
        Exception('Failed to retrieve data: ${event.target}'),
      );
    };

    return await completer.future;
  }

  /// Delete encrypted data
  Future<void> delete(String key) async {
    if (_db == null) {
      throw StateError('Storage not initialized. Call init() first.');
    }

    final db = _db as js.JsObject;
    final transaction =
        db.callMethod('transaction', [storeName, 'readwrite']) as js.JsObject;
    final store =
        transaction.callMethod('objectStore', [storeName]) as js.JsObject;
    final request = store.callMethod('delete', [key]) as js.JsObject;

    final completer = Completer<void>();
    (request as dynamic).onSuccess = (_) => completer.complete();
    (request as dynamic).onError = (html.Event event) {
      completer.completeError(
        Exception('Failed to delete data: ${event.target}'),
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
