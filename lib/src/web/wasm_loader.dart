import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:js_util' as js_util;
import 'dart:typed_data';

/// WebAssembly module loader for Fipers
class WasmLoader {
  static js.JsObject? _module;
  static bool _initialized = false;

  /// Initialize WASM module
  static Future<void> init() async {
    if (_initialized && _module != null) {
      return;
    }

    try {
      // Check if module is already loaded
      if (js.context.hasProperty('createFipersModule')) {
        final moduleFactory = js.context['createFipersModule'];
        if (moduleFactory != null) {
          // Create module instance
          final promise = (moduleFactory as js.JsFunction).apply([]);
          _module = await _promiseToFuture(promise);
          _initialized = true;
          return;
        }
      }

      // Load WASM module dynamically
      // The module should be loaded from the assets
      final script = html.ScriptElement()
        ..type = 'text/javascript'
        ..src = 'packages/fipers/assets/fipers.js';
      
      html.document.head!.append(script);
      
      await script.onLoad.first;
      
      // Get the module factory function
      final moduleFactory = js.context['createFipersModule'];
      if (moduleFactory == null) {
        throw Exception('WASM module factory not found. Make sure fipers.js is loaded.');
      }

      // Create module instance (returns a Promise)
      final promise = (moduleFactory as js.JsFunction).apply([]);
      _module = await _promiseToFuture(promise);
      
      _initialized = true;
    } catch (e) {
      throw Exception('Failed to load WASM module: $e');
    }
  }

  /// Convert JavaScript Promise to Dart Future
  static Future<js.JsObject> _promiseToFuture(dynamic promise) {
    return js_util.promiseToFuture<js.JsObject>(promise);
  }

  /// Call WASM function
  static dynamic callFunction(
    String name,
    List<dynamic> args,
  ) {
    if (!_initialized || _module == null) {
      throw StateError('WASM module not initialized. Call init() first.');
    }

    try {
      return _module!.callMethod('ccall', [
        name,
        'number', // return type
        js.JsObject.jsify(args.map((arg) {
          if (arg is String) return 'string';
          if (arg is int) return 'number';
          if (arg is Uint8List) return 'array';
          return 'number';
        }).toList()),
        js.JsObject.jsify(args),
      ]);
    } catch (e) {
      throw Exception('Failed to call WASM function $name: $e');
    }
  }

  /// Allocate string in WASM memory
  static int allocateString(String str) {
    if (!_initialized || _module == null) {
      throw StateError('WASM module not initialized.');
    }

    return _module!.callMethod('stringToUTF8', [str, null, null]);
  }

  /// Free string from WASM memory
  static void freeString(int ptr) {
    if (!_initialized || _module == null) {
      return;
    }

    _module!.callMethod('_free', [ptr]);
  }

  /// Allocate bytes in WASM memory
  static int allocateBytes(Uint8List data) {
    if (!_initialized || _module == null) {
      throw StateError('WASM module not initialized.');
    }

    final ptr = _module!.callMethod('_malloc', [data.length]);
    final heap = _module!['HEAPU8'] as js.JsObject;
    final heapArray = heap as js.JsArray;
    
    for (int i = 0; i < data.length; i++) {
      heapArray[i] = data[i];
    }
    
    return ptr;
  }

  /// Free bytes from WASM memory
  static void freeBytes(int ptr) {
    if (!_initialized || _module == null) {
      return;
    }

    _module!.callMethod('_free', [ptr]);
  }

  /// Read bytes from WASM memory
  static Uint8List readBytes(int ptr, int length) {
    if (!_initialized || _module == null) {
      throw StateError('WASM module not initialized.');
    }

    final heap = _module!['HEAPU8'] as js.JsObject;
    final result = Uint8List(length);
    
    for (int i = 0; i < length; i++) {
      result[i] = heap[i + ptr] as int;
    }
    
    return result;
  }
}

