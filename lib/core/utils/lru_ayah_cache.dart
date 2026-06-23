import 'package:tawaq/core/utils/lru_map.dart';

/// In-memory LRU for ayah-scoped database rows keyed by `(source, sura, aya)`.
class LruAyahCache<T> {
  /// Creates a cache retaining at most [maxSize] entries.
  LruAyahCache({this.maxSize = defaultMaxSize})
    : assert(maxSize > 0, 'maxSize must be positive');

  /// Default capacity shared by tafsir and translation row caches.
  static const defaultMaxSize = 32;

  /// Maximum number of cached rows.
  final int maxSize;

  late final LruMap<String, T?> _cache = LruMap<String, T?>(maxSize);
  final _filled = <String>{};

  static String key(String sourceName, int sura, int aya) =>
      '$sourceName-$sura-$aya';

  /// Returns a cache hit for [sourceName]/[sura]/[aya], including cached `null`.
  ({bool hit, T? value}) lookup(String sourceName, int sura, int aya) {
    final cacheKey = key(sourceName, sura, aya);
    if (!_filled.contains(cacheKey)) {
      return (hit: false, value: null);
    }
    return (hit: true, value: _cache[cacheKey]);
  }

  /// Stores [value] for [sourceName]/[sura]/[aya].
  void store(String sourceName, int sura, int aya, T? value) {
    final cacheKey = key(sourceName, sura, aya);
    _filled.add(cacheKey);
    _cache[cacheKey] = value;
  }
}
