import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/core/utils/lru_ayah_cache.dart';

void main() {
  group('LruAyahCache', () {
    test('evicts oldest entries and never reports false hits', () {
      const maxSize = 3;
      final cache = LruAyahCache<String>(maxSize: maxSize);

      for (var i = 0; i < maxSize + 2; i++) {
        cache.store('src', 1, i, 'v$i');
      }

      expect(cache.length, lessThanOrEqualTo(maxSize));
      expect(cache.length, maxSize);

      // Evicted keys must be misses, not (hit:true, value:null).
      expect(cache.lookup('src', 1, 0), (hit: false, value: null));
      expect(cache.lookup('src', 1, 1), (hit: false, value: null));

      expect(cache.lookup('src', 1, 2), (hit: true, value: 'v2'));
      expect(cache.lookup('src', 1, 3), (hit: true, value: 'v3'));
      expect(cache.lookup('src', 1, 4), (hit: true, value: 'v4'));
    });

    test('distinguishes cached null from a miss', () {
      final cache = LruAyahCache<String>(maxSize: 2)..store('src', 1, 1, null);

      expect(cache.lookup('src', 1, 1), (hit: true, value: null));
      expect(cache.lookup('src', 1, 2), (hit: false, value: null));
    });
  });
}
