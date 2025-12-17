// Export the interface
export 'src/fipers_interface.dart' show Fipers;

// Import native implementation
import 'src/fipers_interface.dart';
import 'src/fipers_native_export.dart' show createFipersInstance;

/// Creates a native instance of Fipers.
///
/// On native platforms (Android, iOS, macOS, Linux, Windows), this returns
/// [FipersNative] which uses FFI for encryption operations.
///
/// Note: Web platform is not supported.
Fipers createFipers() {
  return createFipersInstance();
}
