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

  final Box<String, dynamic> _favoritesBox;
  final Box<int, HadithRecentSearch> _recentsBox;

  /// Stores a favorite hadith.
  Future<void> addFavorite(String key, DetailedHadith hadith) async {
    await _favoritesBox.put(key, jsonEncode(hadith.toJson()));
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

  /// Returns every stored favorite hadith.
  Future<List<DetailedHadith>> getAllFavorites() async {
    final values = await _favoritesBox.getAllValues();
    return values
        .map(_toDetailedHadith)
        .whereType<DetailedHadith>()
        .toList(growable: false);
  }

  DetailedHadith? _toDetailedHadith(dynamic value) {
    if (value is String) {
      return DetailedHadith.fromJson(jsonDecode(value) as Map<String, dynamic>);
    }

    if (value is Map<String, dynamic>) {
      return DetailedHadith.fromJson(value);
    }

    if (value is HadithFavorite) {
      return DetailedHadith(
        hadith: value.hadith,
        rawi: value.rawi,
        mohdith: value.mohdith,
        book: value.book,
        numberOrPage: value.numberOrPage,
        grade: value.hukm,
        explainGrade: value.hukm,
      );
    }

    return null;
  }

  /// Returns recent searches ordered from newest to oldest.
  Future<List<HadithRecentSearch>> getRecentSearches({int limit = 12}) async {
    final values = await _recentsBox.getAllValues();
    final list = values.toList()
      ..sort((a, b) => b.searchedAt.compareTo(a.searchedAt));
    if (list.length <= limit) return list;
    return list.take(limit).toList(growable: false);
  }

  /// Checks whether a favorite exists for the given key.
  Future<bool> isFavorite(String key) async {
    return _favoritesBox.containsKey(key);
  }
}
