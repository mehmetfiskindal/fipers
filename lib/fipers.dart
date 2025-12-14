// Export the interface
export 'src/fipers_interface.dart' show Fipers;

// Conditional imports for platform-specific implementations
import 'src/fipers_interface.dart';
import 'src/fipers_native.dart'
    if (dart.library.html) 'src/fipers_web.dart';

/// Creates a platform-specific instance of Fipers.
///
/// On native platforms (Android, iOS, macOS, Linux, Windows), this returns
/// [FipersNative] which uses FFI for encryption operations.
///
/// On Web platform, this returns [FipersWeb] which uses WebCrypto API and IndexedDB.
Fipers createFipers() {
  // Conditional import ensures the correct implementation is imported
  // ignore: undefined_class
  return FipersNative();
}
