// Stub for dart:html and dart:js on native platforms
// This file is only used when dart:html is not available

// HTML stubs
class Window {
  dynamic get indexedDB => null;
  dynamic get crypto => null;
  dynamic get localStorage => <String, String>{};
}

class CryptoKey {}

class Event {
  dynamic target;
  Event(this.target);
}

class Blob {}

class FileReader {
  void readAsArrayBuffer(dynamic blob) {}
  dynamic get result => null;
  Stream<Event> get onLoadEnd => const Stream.empty();
}

final window = Window();

// JS stubs (for dart:js compatibility)
class JsObject {
  dynamic callMethod(String method, List<dynamic> args) => null;
  dynamic operator [](String key) => null;
  void operator []=(String key, dynamic value) {}

  JsObject.from(dynamic object);
  JsObject._();
}

// Helper function for jsify (dart:js compatibility)
JsObject jsify(Map<String, dynamic> map) => JsObject._();

// Export js namespace for compatibility
final context = <String, dynamic>{};
