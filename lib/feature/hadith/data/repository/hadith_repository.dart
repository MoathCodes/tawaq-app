import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/bootstrap/app_init_providers.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/feature/hadith/data/database/hadith_local_database.dart';
import 'package:tawaq/feature/hadith/data/models/hadith_recent_search.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_identity.dart';

part 'hadith_repository.g.dart';

/// Provides the shared Dorar client.
///
/// Dorar is initialized lazily on first Hadith route use. Construction waits
/// for [dorarInitProvider] so the cache path is configured first.
@Riverpod(keepAlive: true)
Future<DorarClient> dorarClient(Ref ref) async {
  await ref.watch(dorarInitProvider.future);
  final client = DorarClient();
  ref.onDispose(() async {
    await client.dispose();
  });
  return client;
}

/// Provides the repository used by the hadith feature.
// Used by app-lived state owners outside this feature route.
@Riverpod(keepAlive: true)
Future<HadithRepository> hadithRepository(Ref ref) async {
  final log = ref.read(loggerProvider);
  final local = ref.read(hadithLocalDatabaseProvider);
  return HadithRepository.lazy(
    client: () => ref.read(dorarClientProvider.future),
    local: local,
    log: log,
  );
}

/// Clears only failed initialization owners before an explicit user retry.
/// Successful clients remain alive; request failures do not recreate them.
void retryFailedHadithInitialization(Ref ref) {
  final initFailed =
      ref.exists(dorarInitProvider) && ref.read(dorarInitProvider).hasError;
  final clientFailed =
      ref.exists(dorarClientProvider) && ref.read(dorarClientProvider).hasError;
  final repositoryFailed =
      ref.exists(hadithRepositoryProvider) &&
      ref.read(hadithRepositoryProvider).hasError;
  if (initFailed) ref.invalidate(dorarInitProvider);
  if (clientFailed) ref.invalidate(dorarClientProvider);
  if (repositoryFailed) ref.invalidate(hadithRepositoryProvider);
}

/// Coordinates hadith persistence and remote API access.
class HadithRepository {
  /// Creates the repository.
  HadithRepository({
    required DorarClient client,
    required HadithLocalDatabase local,
    required Logger log,
  }) : _resolveClient = (() async => client),
       _local = local,
       _log = log;
  HadithRepository.lazy({
    required Future<DorarClient> Function() client,
    required HadithLocalDatabase local,
    required Logger log,
  }) : _resolveClient = client,
       _local = local,
       _log = log;

  final Future<DorarClient> Function() _resolveClient;
  final HadithLocalDatabase _local;
  final Logger _log;

  /// Stores a recent-search query locally.
  Future<void> addRecentSearch(String query) async {
    await _local.addRecentSearch(query);
  }

  /// Persists a hadith as a favorite.
  Future<DetailedHadith> createFavorite(DetailedHadith hadith) async {
    final entries = await _local.getFavoriteEntries();
    final existing = entries
        .where(
          (entry) =>
              entry.hadith != null &&
              hadithStableKey(entry.hadith!) == hadithStableKey(hadith),
        )
        .firstOrNull;
    await _local.addFavorite(existing?.key ?? hadithStableKey(hadith), hadith);
    return hadith;
  }

  /// Deletes a favorite by its stable key.
  Future<void> deleteFavorite(String key) async {
    await _local.deleteFavorite(key);
  }

  /// Clears all stored recent searches.
  Future<void> clearRecentSearches() async {
    await _local.clearRecentSearches();
  }

  /// Removes one stored recent-search query.
  Future<void> removeRecentSearch(String query) async {
    await _local.removeRecentSearch(query);
  }

  /// Returns durable bookmark identities, including unreadable entries.
  Future<List<SavedHadithEntry>> getFavoriteEntries() =>
      _local.getFavoriteEntries();

  /// Returns all saved favorites.
  Future<List<DetailedHadith>> getFavorites() async {
    return _local.getAllFavorites();
  }

  /// Returns recent searches ordered from newest to oldest.
  Future<List<HadithRecentSearch>> getRecentSearches({int limit = 12}) async {
    return _local.getRecentSearches(limit: limit);
  }

  /// Checks whether the given key is already bookmarked.
  Future<bool> isFavoriteByKey(String key) async {
    return _local.isFavorite(key);
  }

  /// Searches the offline book choices.
  Future<List<ReferenceChoice>> searchBooks(String query) async =>
      (await (await _resolveClient()).searchBooks(query))
          .map(_choice)
          .toList(growable: false);

  /// Searches explanation prose with the endpoint's own paging contract.
  Future<ApiResponse<List<SharhSnippet>>> searchProse(
    SharhTextSearchParams params,
  ) async => (await _resolveClient()).searchSharhText(params);

  /// Runs the detailed hadith search endpoint.
  Future<ApiResponse<List<DetailedHadith>>> searchDetailed(
    HadithSearchParams params,
  ) async {
    const logPrefix = '[HadithRepository.searchDetailed] ';
    try {
      _log.d('$logPrefix query="${params.value}" page=${params.page}');
      return await (await _resolveClient()).searchHadithDetailed(params);
    } catch (e, stackTrace) {
      _log.e('$logPrefix Error', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Searches scholars in the offline reference snapshot.
  Future<List<ReferenceChoice>> searchScholars(String query) async =>
      (await (await _resolveClient()).searchMohdith(query))
          .map(_choice)
          .toList(growable: false);

  /// Searches rawi entries in the offline reference snapshot.
  Future<List<ReferenceChoice>> searchRawi(String query) async =>
      (await (await _resolveClient()).searchRawi(query))
          .map(_choice)
          .toList(growable: false);

  Future<ApiResponse<List<DetailedHadith>>> browseCategory(
    CategoryBrowseParams params,
  ) async => (await _resolveClient()).categories.browse(params);

  /// Toggles a detailed record using its existing stored key when present.
  Future<void> toggleFavorite(DetailedHadith hadith) async {
    final entries = await _local.getFavoriteEntries();
    final existing = entries
        .where(
          (entry) =>
              entry.hadith != null &&
              hadithStableKey(entry.hadith!) == hadithStableKey(hadith),
        )
        .firstOrNull;
    if (existing != null) {
      await deleteFavorite(existing.key);
    } else {
      await createFavorite(hadith);
    }
  }
}

ReferenceChoice _choice(ReferenceItem item) =>
    ReferenceChoice(id: item.id, name: item.name);
