import 'dart:convert';

import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:hivez_flutter/hivez_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/feature/hadith/data/models/hadith_favorite.dart';
import 'package:tawaq/feature/hadith/data/models/hadith_recent_search.dart';

part 'hadith_local_database.g.dart';

/// Provides the local database used by the hadith feature.
@Riverpod(keepAlive: true)
HadithLocalDatabase hadithLocalDatabase(Ref ref) {
  final favoritesBox = Box<String, dynamic>('hadith_favorites');
  final recentsBox = Box<int, HadithRecentSearch>('hadith_recent_searches');

  ref.onDispose(() async {
    await favoritesBox.closeBox();
    await recentsBox.closeBox();
  });

  return HadithLocalDatabase(
    favoritesBox: favoritesBox,
    recentsBox: recentsBox,
  );
}

/// Handles local persistence for hadith favorites and recent searches.
class HadithLocalDatabase {
  /// Creates the local database wrapper.
  HadithLocalDatabase({
    required this._favoritesBox,
    required this._recentsBox,
  });
  static const _maxHiveIntKey = 0xFFFFFFFF;
  static const _maxRecentSearches = 12;
  static const _savedAtKey = 'savedAt';
  static const _hadithKey = 'hadith';

  /// Soft cap for persisted favorites (oldest by [savedAt] pruned first).
  static const maxFavorites = 500;

  final Box<String, dynamic> _favoritesBox;
  final Box<int, HadithRecentSearch> _recentsBox;

  /// Stores a favorite hadith.
  Future<void> addFavorite(String key, DetailedHadith hadith) async {
    final envelope = <String, dynamic>{
      _savedAtKey: DateTime.now().toIso8601String(),
      _hadithKey: hadith.toJson(),
    };
    await _favoritesBox.put(key, jsonEncode(envelope));
    await _pruneFavorites();
  }

  /// Stores a recent-search query.
  Future<void> addRecentSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final latest = await _recentsBox.getValuesWhere(
      (entry) => entry.query == trimmed,
    );

    for (final old in latest) {
      await _recentsBox.delete(old.id);
    }

    final now = DateTime.now();
    var id = now.millisecondsSinceEpoch ~/ 1000;
    if (id < 0) id = 0;
    if (id > _maxHiveIntKey) {
      id = id % _maxHiveIntKey;
    }

    while (await _recentsBox.containsKey(id)) {
      id = (id + 1) & _maxHiveIntKey;
    }

    await _recentsBox.put(
      id,
      HadithRecentSearch(id: id, query: trimmed, searchedAt: now),
    );

    await _pruneRecentSearches();
  }

  /// Deletes a favorite by key.
  Future<void> deleteFavorite(String key) async {
    await _favoritesBox.delete(key);
  }

  /// Clears the recent-search history.
  Future<void> clearRecentSearches() async {
    await _recentsBox.clear();
  }

  /// Removes one recent-search query from history.
  Future<void> removeRecentSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final matches = await _recentsBox.getValuesWhere(
      (entry) => entry.query == trimmed,
    );

    for (final entry in matches) {
      await _recentsBox.delete(entry.id);
    }
  }

  /// Returns every stored favorite hadith (corrupt entries skipped).
  Future<List<DetailedHadith>> getAllFavorites() async {
    await _pruneFavorites();
    final entries = await _readFavoriteEntries();
    return entries
        .map((entry) => entry.hadith)
        .whereType<DetailedHadith>()
        .toList(growable: false);
  }

  /// Drops oldest favorites beyond [max] by [savedAt] (oldest first).
  Future<void> _pruneFavorites({int max = maxFavorites}) async {
    final entries = await _readFavoriteEntries();
    if (entries.length <= max) return;

    entries.sort((a, b) => a.savedAt.compareTo(b.savedAt));
    final overflow = entries.length - max;
    final keysToDelete = entries.take(overflow).map((e) => e.key).toList();
    await _favoritesBox.deleteAll(keysToDelete);
  }

  Future<List<_FavoriteEntry>> _readFavoriteEntries() async {
    final keys = (await _favoritesBox.getAllKeys()).toList(growable: false);
    final entries = <_FavoriteEntry>[];
    final corruptKeys = <String>[];

    for (final key in keys) {
      final value = await _favoritesBox.get(key);
      if (value == null) continue;

      final parsed = _parseFavoriteEntry(key, value);
      if (parsed == null) {
        corruptKeys.add(key);
        continue;
      }
      entries.add(parsed);
    }

    if (corruptKeys.isNotEmpty) {
      await _favoritesBox.deleteAll(corruptKeys);
    }

    return entries;
  }

  _FavoriteEntry? _parseFavoriteEntry(String key, dynamic value) {
    try {
      final decoded = _decodeFavoriteValue(value);
      if (decoded == null) return null;

      final savedAt = decoded.savedAt;
      final hadith = decoded.hadith;
      if (hadith == null) return null;

      return _FavoriteEntry(key: key, savedAt: savedAt, hadith: hadith);
    } catch (_) {
      return null;
    }
  }

  ({DateTime savedAt, DetailedHadith? hadith})? _decodeFavoriteValue(
    dynamic value,
  ) {
    if (value is String) {
      final decoded = jsonDecode(value);
      return _decodeFavoriteMap(decoded);
    }

    if (value is Map) {
      return _decodeFavoriteMap(Map<String, dynamic>.from(value));
    }

    if (value is HadithFavorite) {
      return (
        savedAt: value.savedAt,
        hadith: DetailedHadith(
          hadith: value.hadith,
          rawi: value.rawi,
          mohdith: value.mohdith,
          book: value.book,
          numberOrPage: value.numberOrPage,
          grade: value.hukm,
          explainGrade: value.hukm,
        ),
      );
    }

    return null;
  }

  ({DateTime savedAt, DetailedHadith? hadith})? _decodeFavoriteMap(
    Object? decoded,
  ) {
    if (decoded is! Map) return null;
    final map = Map<String, dynamic>.from(decoded);

    // Envelope: { savedAt, hadith: {...} }
    if (map[_hadithKey] is Map) {
      final savedAtRaw = map[_savedAtKey];
      final savedAt = savedAtRaw is String
          ? DateTime.tryParse(savedAtRaw) ?? DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.fromMillisecondsSinceEpoch(0);
      final hadith = DetailedHadith.fromJson(
        Map<String, dynamic>.from(map[_hadithKey] as Map),
      );
      return (savedAt: savedAt, hadith: hadith);
    }

    // Legacy: bare DetailedHadith JSON (no savedAt).
    if (map.containsKey('hadith') && map[_hadithKey] is String) {
      final hadith = DetailedHadith.fromJson(map);
      return (
        savedAt: DateTime.fromMillisecondsSinceEpoch(0),
        hadith: hadith,
      );
    }

    // Legacy HadithFavorite JSON shape.
    if (map.containsKey('key') && map.containsKey('hukm')) {
      final favorite = HadithFavorite.fromJson(map);
      return (
        savedAt: favorite.savedAt,
        hadith: DetailedHadith(
          hadith: favorite.hadith,
          rawi: favorite.rawi,
          mohdith: favorite.mohdith,
          book: favorite.book,
          numberOrPage: favorite.numberOrPage,
          grade: favorite.hukm,
          explainGrade: favorite.hukm,
        ),
      );
    }

    // Bare DetailedHadith map without envelope.
    if (map.containsKey('hadith') || map.containsKey('rawi')) {
      return (
        savedAt: DateTime.fromMillisecondsSinceEpoch(0),
        hadith: DetailedHadith.fromJson(map),
      );
    }

    return null;
  }

  /// Returns recent searches ordered from newest to oldest.
  Future<List<HadithRecentSearch>> getRecentSearches({int limit = 12}) async {
    await _pruneRecentSearches(max: limit);

    // Box is capped on write; this read is bounded to [limit] entries.
    final values = await _recentsBox.getAllValues();
    final list = values.toList()
      ..sort((a, b) => b.searchedAt.compareTo(a.searchedAt));
    if (list.length <= limit) return list;
    return list.take(limit).toList(growable: false);
  }

  Future<void> _pruneRecentSearches({int max = _maxRecentSearches}) async {
    final values = await _recentsBox.getAllValues();
    final list = values.toList()
      ..sort((a, b) => b.searchedAt.compareTo(a.searchedAt));
    if (list.length <= max) return;

    for (final entry in list.skip(max)) {
      await _recentsBox.delete(entry.id);
    }
  }

  /// Checks whether a favorite exists for the given key.
  Future<bool> isFavorite(String key) async {
    return _favoritesBox.containsKey(key);
  }
}

class _FavoriteEntry {
  const _FavoriteEntry({
    required this.key,
    required this.savedAt,
    required this.hadith,
  });

  final String key;
  final DateTime savedAt;
  final DetailedHadith hadith;
}
