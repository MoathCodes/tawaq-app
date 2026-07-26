/// Fixed-capacity least-recently-used map backed by insertion-ordered [Map].
class LruMap<K, V> {
  /// Creates an LRU map that retains at most [maxSize] entries.
  LruMap(this.maxSize) : assert(maxSize > 0, 'maxSize must be positive');

  /// Maximum number of entries to retain.
  final int maxSize;

  final _map = <K, V>{};

  /// Current number of retained entries.
  int get length => _map.length;

  /// Returns the value for [key], refreshing its recency, or `null` if absent.
  ///
  /// Distinguishes a missing key from a present `null` value when [V] is
  /// nullable — use [containsKey] when that distinction matters.
  V? operator [](K key) {
    if (!_map.containsKey(key)) return null;
    final value = _map.remove(key) as V;
    _map[key] = value;
    return value;
  }

  /// Inserts or updates [key], evicting the oldest entry when over capacity.
  void operator []=(K key, V value) {
    _map.remove(key);
    _map[key] = value;
    while (_map.length > maxSize) {
      _map.remove(_map.keys.first);
    }
  }

  /// Whether [key] is currently cached.
  bool containsKey(K key) => _map.containsKey(key);
}
