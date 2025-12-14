// Export the interface
export 'src/fipers_interface.dart' show Fipers;

// Conditional imports for platform-specific implementations
// On native platforms (where dart.library.io exists), use native implementation
// On web (where dart.library.io doesn't exist), use web implementation
import 'src/fipers_interface.dart';
import 'src/fipers_native_export.dart' show createFipersInstance
    if (dart.library.html) 'src/fipers_web_export.dart' show createFipersInstance;

/// Creates a platform-specific instance of Fipers.
///
/// On native platforms (Android, iOS, macOS, Linux, Windows), this returns
/// [FipersNative] which uses FFI for encryption operations.
///
/// On Web platform, this returns [FipersWeb] which uses WebCrypto API and IndexedDB.
Fipers createFipers() {
  // Conditional import ensures the correct implementation is imported
  return createFipersInstance();
}
