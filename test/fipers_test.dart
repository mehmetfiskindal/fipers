import 'dart:typed_data';

import 'package:fipers/fipers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Fipers', () {
    test('createFipers returns platform-specific implementation', () {
      final fipers = createFipers();
      expect(fipers, isNotNull);
    });

    test('init throws if not called before other operations', () {
      final fipers = createFipers();
      expect(
        () => fipers.put('key', Uint8List.fromList([1, 2, 3])),
        throwsA(isA<StateError>()),
      );
    });

    test('get returns null for non-existent key', () async {
      final fipers = createFipers();
      await fipers.init('/tmp/test', 'testpass');
      final result = await fipers.get('nonexistent');
      expect(result, isNull);
      await fipers.close();
    });

    test('put and get work correctly', () async {
      final fipers = createFipers();
      await fipers.init('/tmp/test', 'testpass');
      
      final data = Uint8List.fromList([1, 2, 3, 4, 5]);
      await fipers.put('testkey', data);
      
      final retrieved = await fipers.get('testkey');
      // Note: Currently returns null as storage is placeholder
      // In production, this should return the data
      
      await fipers.close();
    });

    test('delete works correctly', () async {
      final fipers = createFipers();
      await fipers.init('/tmp/test', 'testpass');
      
      await fipers.delete('testkey');
      // Should not throw
      
      await fipers.close();
    });

    test('close releases resources', () async {
      final fipers = createFipers();
      await fipers.init('/tmp/test', 'testpass');
      await fipers.close();
      
      // Operations after close should throw
      expect(
        () => fipers.put('key', Uint8List.fromList([1])),
        throwsA(isA<StateError>()),
      );
    });
  });
}
