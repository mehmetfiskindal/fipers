// This file is only imported on native platforms
// It provides the factory function without importing platform-specific code
import 'fipers_interface.dart';

// Import using conditional - this will only work on native
// We use a dynamic import to avoid parsing issues on web
import 'fipers_native.dart' show FipersNative;

/// Factory function for creating a Fipers instance on native platforms.
Fipers createFipersInstance() {
  return FipersNative();
}
