import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:fipers/fipers.dart';
import 'package:flutter_test/flutter_test.dart';

/// Benchmark test suite for Fipers - Comparison with Hive CE
void main() {
  group('Fipers Benchmark Tests (vs Hive CE)', () {
    late String testStoragePath;
    late Fipers fipers;
    late Directory storageDir;

    setUp(() {
      // Create temporary directory for testing
      final tempDir = Directory.systemTemp.createTempSync('fipers_benchmark_');
      testStoragePath = tempDir.path;
      storageDir = Directory(testStoragePath);
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
        if (await storageDir.exists()) {
          await storageDir.delete(recursive: true);
        }
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    /// Calculate total size of storage directory
    Future<int> _calculateStorageSize() async {
      int totalSize = 0;
      if (await storageDir.exists()) {
        await for (final entity in storageDir.list(recursive: true)) {
          if (entity is File) {
        totalSize += await entity.length();
          }
        }
      }
      return totalSize;
    }

    /// Format file size in MB
    String _formatSizeMB(int bytes) {
      return (bytes / (1024 * 1024)).toStringAsFixed(2);
    }

    /// Run benchmark for given number of operations
    Future<BenchmarkResult> _runBenchmark(int operationCount) async {
      await fipers.init(testStoragePath, 'benchmark-passphrase');

      // Use smaller data size to match Hive CE benchmark (approximately)
      // Hive CE uses variable sizes, but we'll use 100 bytes per operation
      // to be more realistic and avoid file system limits
      final dataSize = 100; // 100 bytes per operation
      final data = Uint8List(dataSize);
      final random = Random();

      // Warm-up
      for (int i = 0; i < 10; i++) {
        for (int j = 0; j < data.length; j++) {
          data[j] = random.nextInt(256);
        }
        await fipers.put('warmup-$i', data);
      }

      // Clear for actual benchmark
      await fipers.close();
      if (await storageDir.exists()) {
        await storageDir.delete(recursive: true);
        await storageDir.create();
      }
      fipers = createFipers();
      await fipers.init(testStoragePath, 'benchmark-passphrase');

      // Actual benchmark with error handling
      final stopwatch = Stopwatch()..start();
      int successCount = 0;
      int errorCount = 0;
      
      for (int i = 0; i < operationCount; i++) {
        try {
          // Generate random data for each operation
          for (int j = 0; j < data.length; j++) {
            data[j] = random.nextInt(256);
          }
          await fipers.put('key-$i', data);
          successCount++;
        } catch (e) {
          errorCount++;
          // If we get too many errors, stop the benchmark
          if (errorCount > operationCount * 0.1) {
            print('Warning: Too many errors ($errorCount), stopping benchmark');
            break;
          }
        }
      }
      stopwatch.stop();

      final elapsedSeconds = stopwatch.elapsedMilliseconds / 1000.0;
      final storageSize = await _calculateStorageSize();

      if (errorCount > 0) {
        print('Warning: $errorCount errors occurred during benchmark');
      }

      return BenchmarkResult(
        operations: successCount,
        timeSeconds: elapsedSeconds,
        sizeBytes: storageSize,
      );
    }

    test('Benchmark: 10 operations', () async {
      final result = await _runBenchmark(10);
      print('\n=== Benchmark: 10 operations ===');
      print('Time: ${result.timeSeconds.toStringAsFixed(2)} s');
      print('Size: ${_formatSizeMB(result.sizeBytes)} MB');
      print('Throughput: ${(10 / result.timeSeconds).toStringAsFixed(0)} ops/s');
      
      expect(result.timeSeconds, lessThan(1.0), reason: 'Should complete in < 1s');
    });

    test('Benchmark: 100 operations', () async {
      final result = await _runBenchmark(100);
      print('\n=== Benchmark: 100 operations ===');
      print('Time: ${result.timeSeconds.toStringAsFixed(2)} s');
      print('Size: ${_formatSizeMB(result.sizeBytes)} MB');
      print('Throughput: ${(100 / result.timeSeconds).toStringAsFixed(0)} ops/s');
      
      expect(result.timeSeconds, lessThan(5.0), reason: 'Should complete in < 5s');
    });

    test('Benchmark: 1,000 operations', () async {
      final result = await _runBenchmark(1000);
      print('\n=== Benchmark: 1,000 operations ===');
      print('Time: ${result.timeSeconds.toStringAsFixed(2)} s');
      print('Size: ${_formatSizeMB(result.sizeBytes)} MB');
      print('Throughput: ${(1000 / result.timeSeconds).toStringAsFixed(0)} ops/s');
      
      expect(result.timeSeconds, lessThan(30.0), reason: 'Should complete in < 30s');
    });

    test('Benchmark: 10,000 operations', () async {
      final result = await _runBenchmark(10000);
      print('\n=== Benchmark: 10,000 operations ===');
      print('Time: ${result.timeSeconds.toStringAsFixed(2)} s');
      print('Size: ${_formatSizeMB(result.sizeBytes)} MB');
      print('Throughput: ${(10000 / result.timeSeconds).toStringAsFixed(0)} ops/s');
      
      expect(result.timeSeconds, lessThan(300.0), reason: 'Should complete in < 300s');
    });

    test('Benchmark: 100,000 operations', () async {
      // Skip due to file system limits (too many files)
    }, skip: 'Skipped - creates too many files, may hit file system limits');

    test('Benchmark: 1,000,000 operations', () async {
      // Skip for now - requires very long timeout and may hit file system limits
      // Uncomment to run:
      // final result = await _runBenchmark(1000000);
      // print('\n=== Benchmark: 1,000,000 operations ===');
      // print('Time: ${result.timeSeconds.toStringAsFixed(2)} s');
      // print('Size: ${_formatSizeMB(result.sizeBytes)} MB');
      // print('Throughput: ${(1000000 / result.timeSeconds).toStringAsFixed(0)} ops/s');
      // expect(result.timeSeconds, lessThan(600.0), reason: 'Should complete in < 600s');
    }, timeout: const Timeout(Duration(minutes: 10)), skip: 'Skipped - requires very long timeout');

    test('Full Benchmark Comparison Table', () async {
      print('\n\n');
      print('=' * 80);
      print('FIPERS BENCHMARK RESULTS (vs Hive CE)');
      print('=' * 80);
      print('Operations | Fipers Time | Fipers Size | Hive CE Time | Hive CE Size');
      print('-' * 80);

      // Benchmark configurations matching Hive CE test
      // Using smaller operation counts to avoid file system limits
      final benchmarks = [10, 100, 1000, 10000];
      // Note: 100,000 and 1,000,000 operations skipped due to file system limits
      // Each operation creates a separate file, which can hit inode limits
      final hiveCETimes = [0.00, 0.00, 0.02, 0.13];
      final hiveCESizes = [0.00, 0.01, 0.11, 1.10];

      for (int i = 0; i < benchmarks.length; i++) {
        final opCount = benchmarks[i];
        print('Running benchmark for $opCount operations...');
        final result = await _runBenchmark(opCount);
        
        final fipersTime = result.timeSeconds.toStringAsFixed(2);
        final fipersSize = _formatSizeMB(result.sizeBytes);
        final hiveTime = hiveCETimes[i].toStringAsFixed(2);
        final hiveSize = hiveCESizes[i].toStringAsFixed(2);

        print('${opCount.toString().padLeft(9)} | ${fipersTime.padLeft(11)} s | ${fipersSize.padLeft(10)} MB | ${hiveTime.padLeft(12)} s | ${hiveSize.padLeft(12)} MB');

        // Calculate speedup/slowdown
        if (hiveCETimes[i] > 0) {
          final speedup = hiveCETimes[i] / result.timeSeconds;
          if (speedup > 1) {
            print('  → Fipers is ${speedup.toStringAsFixed(2)}x faster');
          } else {
            print('  → Fipers is ${(1 / speedup).toStringAsFixed(2)}x slower');
          }
        }

        // Calculate size difference
        final sizeDiff = result.sizeBytes / (1024 * 1024) - hiveCESizes[i];
        if (sizeDiff > 0) {
          print('  → Fipers uses ${sizeDiff.toStringAsFixed(2)} MB more space');
        } else {
          print('  → Fipers uses ${(-sizeDiff).toStringAsFixed(2)} MB less space');
        }

        print('-' * 80);

        // Clean up for next benchmark
        await fipers.close();
        if (await storageDir.exists()) {
          await storageDir.delete(recursive: true);
          await storageDir.create();
        }
        fipers = createFipers();
      }

      print('\n');
    });
  });
}

/// Benchmark result data class
class BenchmarkResult {
  final int operations;
  final double timeSeconds;
  final int sizeBytes;

  BenchmarkResult({
    required this.operations,
    required this.timeSeconds,
    required this.sizeBytes,
  });
}

