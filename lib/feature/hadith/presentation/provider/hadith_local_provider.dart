import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/feature/hadith/data/repository/hadith_repository.dart';
import 'package:tawaq/feature/hadith/data/database/hadith_local_database.dart';
part 'hadith_local_provider.g.dart';

/// The only writable runtime authority for persisted Hadith favorites.
@Riverpod(keepAlive: true)
class HadithFavoritesStore extends _$HadithFavoritesStore {
  @override
  Future<Map<String, SavedHadithEntry>> build() async {
    final repository = await ref.read(hadithRepositoryProvider.future);
    final favorites = await repository.getFavoriteEntries();
    return Map.unmodifiable({for (final entry in favorites) entry.key: entry});
  }

  /// Explicitly removes a retained unreadable entry using its durable key.
  Future<void> remove(String key) async {
    final repository = await ref.read(hadithRepositoryProvider.future);
    await repository.deleteFavorite(key);
    final entries = await repository.getFavoriteEntries();
    if (ref.mounted)
      state = AsyncData(
        Map.unmodifiable({for (final entry in entries) entry.key: entry}),
      );
  }

  /// Toggles [hadith] on disk, then atomically publishes the stored snapshot.
  Future<void> toggle(DetailedHadith hadith) async {
    final repository = await ref.read(hadithRepositoryProvider.future);
    await repository.toggleFavorite(hadith);
    final favorites = await repository.getFavoriteEntries();
    if (!ref.mounted) return;
    state = AsyncData(
      Map.unmodifiable({for (final entry in favorites) entry.key: entry}),
    );
  }
}

/// Ordered view of the canonical favorites store.
@riverpod
Future<List<DetailedHadith>> hadithFavorites(Ref ref) async {
  final favorites = await ref.watch(hadithFavoritesStoreProvider.future);
  return List.unmodifiable(
    favorites.values.map((entry) => entry.hadith).whereType<DetailedHadith>(),
  );
}

/// Returns the user's persisted recent-search queries.
@Riverpod(keepAlive: true)
class HadithRecentSearchesStore extends _$HadithRecentSearchesStore {
  static const _defaultLimit = 12;
  Future<void> _writeTail = Future<void>.value();

  @override
  Future<List<String>> build() async {
    final repository = await ref.read(hadithRepositoryProvider.future);
    final entries = await repository.getRecentSearches();
    return entries.map((entry) => entry.query).toList(growable: false);
  }

  /// Persists and then publishes a recent query.
  Future<void> add(String query) => _serialize(() async {
    final normalized = query.trim();
    if (normalized.isEmpty) return;

    final repository = await ref.read(hadithRepositoryProvider.future);
    await repository.addRecentSearch(normalized);
    await _reload(repository);
  });

  /// Removes one query on disk before publishing the new list.
  Future<void> removeQuery(String query) => _serialize(() async {
    final repository = await ref.read(hadithRepositoryProvider.future);
    await repository.removeRecentSearch(query);
    await _reload(repository);
  });

  /// Clears storage before publishing the empty list.
  Future<void> clearAll() => _serialize(() async {
    final repository = await ref.read(hadithRepositoryProvider.future);
    await repository.clearRecentSearches();
    if (!ref.mounted) return;
    state = const AsyncData(<String>[]);
  });

  Future<void> _reload(HadithRepository repository) async {
    final entries = await repository.getRecentSearches();
    if (!ref.mounted) return;
    state = AsyncData(
      entries
          .map((entry) => entry.query)
          .take(_defaultLimit)
          .toList(growable: false),
    );
  }

  Future<void> _serialize(Future<void> Function() operation) {
    final next = _writeTail.then((_) => operation());
    _writeTail = next.then<void>((_) {}, onError: (_, _) {});
    return next;
  }
}
