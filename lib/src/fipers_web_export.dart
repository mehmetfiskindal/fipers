// This file is only imported on web platforms
// It provides the factory function without importing platform-specific code
import 'fipers_interface.dart';

// Import using conditional - this will only work on web
// We use a dynamic import to avoid parsing issues on native
// Note: This file should never be imported on native platforms due to conditional import in fipers.dart
import 'fipers_web.dart' show FipersWeb;

/// Factory function for creating a Fipers instance on web platforms.
Fipers createFipersInstance() {
  return FipersWeb();
}
