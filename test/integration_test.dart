import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:fipers/fipers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Fipers Integration Tests', () {
    late String testStoragePath;
    late Fipers fipers;

    setUp(() {
      // Create temporary directory for testing
      final tempDir = Directory.systemTemp.createTempSync('fipers_test_');
      testStoragePath = tempDir.path;
      fipers = createFipers();
    });

    tearDown(() async {
      // Clean up
      try {
        await fipers.close();
      } catch (e) {
        // Ignore errors during cleanup
      }
      
      // Remove test directory
      try {
        final dir = Directory(testStoragePath);
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    test('init initializes storage successfully', () async {
      await fipers.init(testStoragePath, 'test-passphrase');
      // Should not throw
    });

    test('put and get work correctly', () async {
      await fipers.init(testStoragePath, 'test-passphrase');
      
      final testData = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
      await fipers.put('test-key', testData);
      
      final retrieved = await fipers.get('test-key');
      
      expect(retrieved, isNotNull);
      expect(retrieved!.length, equals(testData.length));
      expect(retrieved, equals(testData));
    });

    test('get returns null for non-existent key', () async {
      await fipers.init(testStoragePath, 'test-passphrase');
      
      final result = await fipers.get('non-existent-key');
      
      expect(result, isNull);
    });

    test('delete removes key successfully', () async {
      await fipers.init(testStoragePath, 'test-passphrase');
      
      final testData = Uint8List.fromList([1, 2, 3]);
      await fipers.put('test-key', testData);
      
      // Verify it exists
      final before = await fipers.get('test-key');
      expect(before, isNotNull);
      
      // Delete it
      await fipers.delete('test-key');
      
      // Verify it's gone
      final after = await fipers.get('test-key');
      expect(after, isNull);
    });

    test('multiple keys can be stored independently', () async {
      await fipers.init(testStoragePath, 'test-passphrase');
      
      final data1 = Uint8List.fromList([1, 2, 3]);
      final data2 = Uint8List.fromList([4, 5, 6]);
      
      await fipers.put('key1', data1);
      await fipers.put('key2', data2);
      
      final retrieved1 = await fipers.get('key1');
      final retrieved2 = await fipers.get('key2');
      
      expect(retrieved1, equals(data1));
      expect(retrieved2, equals(data2));
    });

    test('large data can be stored and retrieved', () async {
      await fipers.init(testStoragePath, 'test-passphrase');
      
      // Create 1MB of data
      final largeData = Uint8List(1024 * 1024);
      for (int i = 0; i < largeData.length; i++) {
        largeData[i] = (i % 256) as int;
      }
      
      await fipers.put('large-key', largeData);
      
      final retrieved = await fipers.get('large-key');
      
      expect(retrieved, isNotNull);
      expect(retrieved!.length, equals(largeData.length));
      expect(retrieved, equals(largeData));
    });

    test('data is encrypted (different passphrase cannot decrypt)', () async {
      await fipers.init(testStoragePath, 'passphrase1');
      
      final testData = Uint8List.fromList([1, 2, 3, 4, 5]);
      await fipers.put('test-key', testData);
      
      await fipers.close();
      
      // Try to read with different passphrase
      final fipers2 = createFipers();
      await fipers2.init(testStoragePath, 'passphrase2');
      
      // Should either return null or throw (depending on implementation)
      // For now, we expect it to fail gracefully
      final result = await fipers2.get('test-key');
      // Result might be null or decryption might fail
      // The important thing is that it doesn't return the original data
      if (result != null) {
        expect(result, isNot(equals(testData)));
      }
      
      await fipers2.close();
    });

    test('close releases resources', () async {
      await fipers.init(testStoragePath, 'test-passphrase');
      await fipers.close();
      
      // Operations after close should throw
      expect(
        () => fipers.put('key', Uint8List.fromList([1])),
        throwsA(isA<StateError>()),
      );
    });

    test('init can be called only once', () async {
      await fipers.init(testStoragePath, 'test-passphrase');
      
      expect(
        () => fipers.init(testStoragePath, 'test-passphrase'),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('Fipers Web Tests', () {
    test('web platform throws UnsupportedError', () {
      // This test should only run on web platform
      // For other platforms, it will be skipped
      if (!Platform.isLinux && !Platform.isWindows && !Platform.isMacOS) {
        final fipers = createFipers();
        
        expect(
          () => fipers.init('/tmp/test', 'passphrase'),
          throwsA(isA<UnsupportedError>()),
        );
      }
    }, skip: Platform.isLinux || Platform.isWindows || Platform.isMacOS);
  });
}

