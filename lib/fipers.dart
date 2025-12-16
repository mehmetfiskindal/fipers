// Export the interface
export 'src/fipers_interface.dart' show Fipers;

// Conditional imports for platform-specific implementations
// On native platforms (where dart.library.io exists), use native implementation
// On web (where dart.library.io doesn't exist), use web implementation
import 'src/fipers_interface.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional import: on native (dart.library.io exists), use native; on web, use web
// Both export the same function name, so we can use it directly
import 'src/fipers_native_export.dart' show createFipersInstance
    if (dart.library.html) 'src/fipers_web_export.dart' show createFipersInstance;

/// Creates a platform-specific instance of Fipers.
///
/// On native platforms (Android, iOS, macOS, Linux, Windows), this returns
/// [FipersNative] which uses FFI for encryption operations.
///
/// On Web platform, this returns [FipersWeb] which uses WebCrypto API and IndexedDB.
Fipers createFipers() {
  // Conditional import handles platform selection:
  // - On native: dart.library.io exists -> imports fipers_native_export -> creates FipersNative
  // - On web: dart.library.io doesn't exist -> imports fipers_web_export -> creates FipersWeb
  // The runtime check below is a safety measure in case conditional imports don't work as expected
  final instance = createFipersInstance();
  
  // Runtime verification: ensure we got the right implementation
  if (!kIsWeb && instance.runtimeType.toString().contains('Web')) {
    throw StateError(
      'Platform mismatch: Expected FipersNative on native platform, but got ${instance.runtimeType}. '
      'This indicates a conditional import issue.',
    );
  }
  if (kIsWeb && instance.runtimeType.toString().contains('Native')) {
    throw StateError(
      'Platform mismatch: Expected FipersWeb on web platform, but got ${instance.runtimeType}. '
      'This indicates a conditional import issue.',
    );
  }
  
  return instance;
}
