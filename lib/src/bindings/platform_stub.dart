// Stub Platform class for web platform
// This file is only used when dart:io is not available
class Platform {
  static bool get isAndroid => false;
  static bool get isIOS => false;
  static bool get isLinux => false;
  static bool get isMacOS => false;
  static bool get isWindows => false;
  static String get operatingSystem => 'web';
  static String get resolvedExecutable => '';
}

class Directory {
  static String get current => '';
}
