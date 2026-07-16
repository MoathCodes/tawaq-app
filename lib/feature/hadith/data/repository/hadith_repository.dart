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
@riverpod
Future<HadithRepository> hadithRepository(Ref ref) async {
  final log = ref.read(loggerProvider);
  final client = await ref.watch(dorarClientProvider.future);
  final local = ref.read(hadithLocalDatabaseProvider);
  return HadithRepository(client: client, local: local, log: log);
}

/// Coordinates hadith persistence and remote API access.
class HadithRepository {
  /// Creates the repository.
  HadithRepository({
    required this._client,
    required this._local,
    required this._log,
  });

  final DorarClient _client;
  final HadithLocalDatabase _local;
  final Logger _log;

  /// Stores a recent-search query locally.
  Future<void> addRecentSearch(String query) async {
    await _local.addRecentSearch(query);
  }

  /// Persists a hadith as a favorite.
  Future<DetailedHadith> createFavorite(DetailedHadith hadith) async {
    final key = hadithStableKey(hadith);
    await _local.addFavorite(key, hadith);
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

  /// Searches books and wraps the result in an API response.
  Future<ApiResponse<List<BookItem>>> searchBooks(String query) async {
    final results = await _client.searchBooks(query);
    return ApiResponse(
      data: results,
      metadata: SearchMetadata(length: results.length),
    );
  }

  /// Runs the detailed hadith search endpoint.
  Future<ApiResponse<List<DetailedHadith>>> searchDetailed(
    HadithSearchParams params,
  ) async {
    const logPrefix = '[HadithRepository.searchDetailed] ';
    try {
      _log.d('$logPrefix query="${params.value}" page=${params.page}');
      return await _client.searchHadithDetailed(params);
    } catch (e, stackTrace) {
      _log.e('$logPrefix Error', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Searches scholars in the remote hadith API.
  Future<List<MohdithItem>> searchScholars(String query) async {
    return _client.searchMohdith(query);
  }

  /// Searches rawi entries in the remote hadith API.
  Future<List<RawiItem>> searchRawi(String query) async {
    return _client.searchRawi(query);
  }

  /// Resolves a hadith into its detailed record.
  Future<DetailedHadith?> resolveDetails(Hadith hadith) async {
    final params = HadithSearchParams(
      value: hadith.hadith,
      searchMethod: SearchMethod.exactMatch,
    );

    final response = await searchDetailed(params);
    if (response.data.isEmpty) return null;

    final normalizedText = hadith.hadith.trim();
    for (final candidate in response.data) {
      if (candidate.hadith.trim() == normalizedText &&
          candidate.rawi == hadith.rawi &&
          candidate.mohdith == hadith.mohdith) {
        return candidate;
      }
    }

    return response.data.first;
  }

  /// Toggles the bookmarked state of a hadith.
  Future<void> toggleFavorite(HadithBase hadith) async {
    const logPrefix = '[HadithRepository.toggleFavorite] ';
    try {
      final key = hadithStableKey(hadith);
      final isFavorite = await isFavoriteByKey(key);
      if (isFavorite) {
        await deleteFavorite(key);
        return;
      }

      if (hadith is DetailedHadith) {
        await createFavorite(hadith);
        return;
      }

      if (hadith is Hadith) {
        final resolved = await resolveDetails(hadith);
        if (resolved == null) {
          throw StateError('Unable to resolve hadith details for bookmarking');
        }
        await createFavorite(resolved);
        return;
      }

      throw StateError(
        'Unsupported hadith type for bookmarking: ${hadith.runtimeType}',
      );
    } catch (e, stackTrace) {
      _log.e('$logPrefix Error', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
