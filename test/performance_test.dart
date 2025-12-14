import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:fipers/fipers.dart';
import 'package:flutter_test/flutter_test.dart';

/// Performance test suite for Fipers
void main() {
  group('Fipers Performance Tests', () {
    late String testStoragePath;
    late Fipers fipers;

    setUp(() {
      // Create temporary directory for testing
      final tempDir = Directory.systemTemp.createTempSync('fipers_perf_test_');
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

    test('Initialization Performance', () async {
      final stopwatch = Stopwatch()..start();
      await fipers.init(testStoragePath, 'test-passphrase');
      stopwatch.stop();

      final elapsed = stopwatch.elapsedMilliseconds;
      print('Initialization time: ${elapsed}ms');

      expect(elapsed, lessThan(5000), reason: 'Initialization should be fast');
    });

    test('Put Operation Performance - Small Data (1KB)', () async {
      await fipers.init(testStoragePath, 'test-passphrase');

      final data = Uint8List(1024); // 1KB
      final random = Random();
      for (int i = 0; i < data.length; i++) {
        data[i] = random.nextInt(256);
      }

      final stopwatch = Stopwatch()..start();
      await fipers.put('small-key', data);
      stopwatch.stop();

      final elapsed = stopwatch.elapsedMilliseconds;
      final throughput = (data.length / 1024) / (elapsed / 1000); // KB/s

      print('Put (1KB) time: ${elapsed}ms');
      print('Put (1KB) throughput: ${throughput.toStringAsFixed(2)} KB/s');

      expect(elapsed, lessThan(1000), reason: 'Put operation should be fast');
    });

    test('Put Operation Performance - Medium Data (100KB)', () async {
      await fipers.init(testStoragePath, 'test-passphrase');

      final data = Uint8List(100 * 1024); // 100KB
      final random = Random();
      for (int i = 0; i < data.length; i++) {
        data[i] = random.nextInt(256);
      }

      final stopwatch = Stopwatch()..start();
      await fipers.put('medium-key', data);
      stopwatch.stop();

      final elapsed = stopwatch.elapsedMilliseconds;
      final throughput = (data.length / 1024) / (elapsed / 1000); // KB/s

      print('Put (100KB) time: ${elapsed}ms');
      print('Put (100KB) throughput: ${throughput.toStringAsFixed(2)} KB/s');

      expect(elapsed, lessThan(5000), reason: 'Put operation should be fast');
    });

    test('Put Operation Performance - Large Data (1MB)', () async {
      await fipers.init(testStoragePath, 'test-passphrase');

      final data = Uint8List(1024 * 1024); // 1MB
      final random = Random();
      for (int i = 0; i < data.length; i++) {
        data[i] = random.nextInt(256);
      }

      final stopwatch = Stopwatch()..start();
      await fipers.put('large-key', data);
      stopwatch.stop();

      final elapsed = stopwatch.elapsedMilliseconds;
      final throughput = (data.length / (1024 * 1024)) / (elapsed / 1000); // MB/s

      print('Put (1MB) time: ${elapsed}ms');
      print('Put (1MB) throughput: ${throughput.toStringAsFixed(2)} MB/s');

      expect(elapsed, lessThan(10000), reason: 'Put operation should be fast');
    });

    test('Get Operation Performance - Small Data (1KB)', () async {
      await fipers.init(testStoragePath, 'test-passphrase');

      final data = Uint8List(1024); // 1KB
      final random = Random();
      for (int i = 0; i < data.length; i++) {
        data[i] = random.nextInt(256);
      }

      await fipers.put('small-key', data);

      final stopwatch = Stopwatch()..start();
      final retrieved = await fipers.get('small-key');
      stopwatch.stop();

      final elapsed = stopwatch.elapsedMilliseconds;
      final throughput = (data.length / 1024) / (elapsed / 1000); // KB/s

      print('Get (1KB) time: ${elapsed}ms');
      print('Get (1KB) throughput: ${throughput.toStringAsFixed(2)} KB/s');

      expect(retrieved, isNotNull);
      expect(elapsed, lessThan(1000), reason: 'Get operation should be fast');
    });

    test('Get Operation Performance - Medium Data (100KB)', () async {
      await fipers.init(testStoragePath, 'test-passphrase');

      final data = Uint8List(100 * 1024); // 100KB
      final random = Random();
      for (int i = 0; i < data.length; i++) {
        data[i] = random.nextInt(256);
      }

      await fipers.put('medium-key', data);

      final stopwatch = Stopwatch()..start();
      final retrieved = await fipers.get('medium-key');
      stopwatch.stop();

      final elapsed = stopwatch.elapsedMilliseconds;
      final throughput = (data.length / 1024) / (elapsed / 1000); // KB/s

      print('Get (100KB) time: ${elapsed}ms');
      print('Get (100KB) throughput: ${throughput.toStringAsFixed(2)} KB/s');

      expect(retrieved, isNotNull);
      expect(elapsed, lessThan(5000), reason: 'Get operation should be fast');
    });

    test('Get Operation Performance - Large Data (1MB)', () async {
      await fipers.init(testStoragePath, 'test-passphrase');

      final data = Uint8List(1024 * 1024); // 1MB
      final random = Random();
      for (int i = 0; i < data.length; i++) {
        data[i] = random.nextInt(256);
      }

      await fipers.put('large-key', data);

      final stopwatch = Stopwatch()..start();
      final retrieved = await fipers.get('large-key');
      stopwatch.stop();

      final elapsed = stopwatch.elapsedMilliseconds;
      final throughput = (data.length / (1024 * 1024)) / (elapsed / 1000); // MB/s

      print('Get (1MB) time: ${elapsed}ms');
      print('Get (1MB) throughput: ${throughput.toStringAsFixed(2)} MB/s');

      expect(retrieved, isNotNull);
      expect(elapsed, lessThan(10000), reason: 'Get operation should be fast');
    });

    test('Delete Operation Performance', () async {
      await fipers.init(testStoragePath, 'test-passphrase');

      final data = Uint8List(1024);
      await fipers.put('delete-key', data);

      final stopwatch = Stopwatch()..start();
      await fipers.delete('delete-key');
      stopwatch.stop();

      final elapsed = stopwatch.elapsedMilliseconds;
      print('Delete time: ${elapsed}ms');

      expect(elapsed, lessThan(1000), reason: 'Delete operation should be fast');
    });

    test('Batch Put Operations Performance (100 items)', () async {
      await fipers.init(testStoragePath, 'test-passphrase');

      const itemCount = 100;
      final data = Uint8List(1024); // 1KB per item
      final random = Random();

      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < itemCount; i++) {
        // Generate random data for each item
        for (int j = 0; j < data.length; j++) {
          data[j] = random.nextInt(256);
        }
        await fipers.put('batch-key-$i', data);
      }
      stopwatch.stop();

      final elapsed = stopwatch.elapsedMilliseconds;
      final avgTime = elapsed / itemCount;
      final totalData = (itemCount * data.length) / 1024; // Total KB
      final throughput = totalData / (elapsed / 1000); // KB/s

      print('Batch Put (100 items, 1KB each) total time: ${elapsed}ms');
      print('Batch Put average time per item: ${avgTime.toStringAsFixed(2)}ms');
      print('Batch Put throughput: ${throughput.toStringAsFixed(2)} KB/s');

      expect(elapsed, lessThan(30000), reason: 'Batch put should complete in reasonable time');
    });

    test('Batch Get Operations Performance (100 items)', () async {
      await fipers.init(testStoragePath, 'test-passphrase');

      const itemCount = 100;
      final data = Uint8List(1024); // 1KB per item
      final random = Random();

      // First, store all items
      for (int i = 0; i < itemCount; i++) {
        for (int j = 0; j < data.length; j++) {
          data[j] = random.nextInt(256);
        }
        await fipers.put('batch-key-$i', data);
      }

      // Now retrieve all items
      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < itemCount; i++) {
        final retrieved = await fipers.get('batch-key-$i');
        expect(retrieved, isNotNull);
      }
      stopwatch.stop();

      final elapsed = stopwatch.elapsedMilliseconds;
      final avgTime = elapsed / itemCount;
      final totalData = (itemCount * data.length) / 1024; // Total KB
      final throughput = totalData / (elapsed / 1000); // KB/s

      print('Batch Get (100 items, 1KB each) total time: ${elapsed}ms');
      print('Batch Get average time per item: ${avgTime.toStringAsFixed(2)}ms');
      print('Batch Get throughput: ${throughput.toStringAsFixed(2)} KB/s');

      expect(elapsed, lessThan(30000), reason: 'Batch get should complete in reasonable time');
    });

    test('Mixed Operations Performance (Put/Get/Delete)', () async {
      await fipers.init(testStoragePath, 'test-passphrase');

      const operationCount = 50;
      final data = Uint8List(1024);
      final random = Random();

      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < operationCount; i++) {
        // Generate random data
        for (int j = 0; j < data.length; j++) {
          data[j] = random.nextInt(256);
        }

        // Put
        await fipers.put('mixed-key-$i', data);

        // Get
        final retrieved = await fipers.get('mixed-key-$i');
        expect(retrieved, isNotNull);

        // Delete
        await fipers.delete('mixed-key-$i');
      }
      stopwatch.stop();

      final elapsed = stopwatch.elapsedMilliseconds;
      final avgTime = elapsed / (operationCount * 3); // 3 operations per iteration

      print('Mixed Operations (50 iterations, Put/Get/Delete) total time: ${elapsed}ms');
      print('Mixed Operations average time per operation: ${avgTime.toStringAsFixed(2)}ms');

      expect(elapsed, lessThan(30000), reason: 'Mixed operations should complete in reasonable time');
    });

    test('String Data Performance', () async {
      await fipers.init(testStoragePath, 'test-passphrase');

      const testStrings = [
        'Hello, World!',
        'This is a longer string to test performance with text data.',
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
      ];

      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < testStrings.length; i++) {
        final data = Uint8List.fromList(utf8.encode(testStrings[i]));
        await fipers.put('string-key-$i', data);

        final retrieved = await fipers.get('string-key-$i');
        expect(retrieved, isNotNull);
        final decoded = utf8.decode(retrieved!);
        expect(decoded, equals(testStrings[i]));
      }
      stopwatch.stop();

      final elapsed = stopwatch.elapsedMilliseconds;
      print('String Data Operations time: ${elapsed}ms');

      expect(elapsed, lessThan(5000), reason: 'String operations should be fast');
    });

    test('Concurrent Operations Performance', () async {
      await fipers.init(testStoragePath, 'test-passphrase');

      const concurrentCount = 10;
      final data = Uint8List(1024);
      final random = Random();

      final stopwatch = Stopwatch()..start();
      final futures = <Future>[];

      for (int i = 0; i < concurrentCount; i++) {
        // Generate random data
        for (int j = 0; j < data.length; j++) {
          data[j] = random.nextInt(256);
        }

        futures.add(
          Future(() async {
            await fipers.put('concurrent-key-$i', data);
            final retrieved = await fipers.get('concurrent-key-$i');
            expect(retrieved, isNotNull);
          }),
        );
      }

      await Future.wait(futures);
      stopwatch.stop();

      final elapsed = stopwatch.elapsedMilliseconds;
      print('Concurrent Operations (10 parallel) time: ${elapsed}ms');

      expect(elapsed, lessThan(10000), reason: 'Concurrent operations should complete in reasonable time');
    });

    test('Memory Efficiency - Large Dataset', () async {
      await fipers.init(testStoragePath, 'test-passphrase');

      const itemCount = 1000;
      final data = Uint8List(1024); // 1KB per item = ~1MB total
      final random = Random();

      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < itemCount; i++) {
        for (int j = 0; j < data.length; j++) {
          data[j] = random.nextInt(256);
        }
        await fipers.put('memory-key-$i', data);
      }
      stopwatch.stop();

      final elapsed = stopwatch.elapsedMilliseconds;
      final totalDataMB = (itemCount * data.length) / (1024 * 1024);
      final throughput = totalDataMB / (elapsed / 1000); // MB/s

      print('Memory Efficiency Test (1000 items, ~1MB total) time: ${elapsed}ms');
      print('Memory Efficiency Test throughput: ${throughput.toStringAsFixed(2)} MB/s');

      // Verify all items can be retrieved
      int retrievedCount = 0;
      for (int i = 0; i < itemCount; i++) {
        final retrieved = await fipers.get('memory-key-$i');
        if (retrieved != null) {
          retrievedCount++;
        }
      }

      expect(retrievedCount, equals(itemCount), reason: 'All items should be retrievable');

      expect(elapsed, lessThan(60000), reason: 'Large dataset operations should complete in reasonable time');
    });

    test('Re-initialization Performance', () async {
      // First initialization
      final stopwatch1 = Stopwatch()..start();
      await fipers.init(testStoragePath, 'test-passphrase');
      stopwatch1.stop();

      // Store some data
      final data = Uint8List(1024);
      await fipers.put('reinit-key', data);
      await fipers.close();

      // Re-initialization with same passphrase
      final fipers2 = createFipers();
      final stopwatch2 = Stopwatch()..start();
      await fipers2.init(testStoragePath, 'test-passphrase');
      stopwatch2.stop();

      final firstInit = stopwatch1.elapsedMilliseconds;
      final secondInit = stopwatch2.elapsedMilliseconds;

      print('First initialization time: ${firstInit}ms');
      print('Re-initialization time: ${secondInit}ms');

      // Re-initialization should be similar or faster (salt already exists)
      expect(secondInit, lessThan(5000), reason: 'Re-initialization should be fast');

      await fipers2.close();
    });
  });
}

