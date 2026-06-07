import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/feature/hadith/data/database/hadith_local_database.dart';
import 'package:tawaq/feature/hadith/data/models/hadith_recent_search.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_identity.dart';

part 'hadith_repository.g.dart';

/// Provides the shared Dorar client.
///
/// Dorar is initialized via `DorarHadithFlutter.ensureInitialized()` in `main.dart`.
@Riverpod(keepAlive: true)
DorarClient dorarClient(Ref ref) {
  final client = DorarClient();
  ref.onDispose(() async {
    await client.dispose();
  });
  return client;
}

/// Provides the repository used by the hadith feature.
@riverpod
HadithRepository hadithRepository(Ref ref) {
  final log = ref.read(loggerProvider);
  final client = ref.read(dorarClientProvider);
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
    final key = favoriteKeyFromHadith(hadith);
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

  /// Returns the stable bookmark key for a hadith.
  String favoriteKeyFromHadith(HadithBase hadith) {
    return hadithStableKey(hadith);
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

  /// Runs the fast hadith search endpoint.
  Future<ApiResponse<List<Hadith>>> searchFast(
    HadithSearchParams params,
  ) async {
    const logPrefix = '[HadithRepository.searchFast] ';
    try {
      _log.d('$logPrefix query="${params.value}" page=${params.page}');
      return await _client.searchHadith(params);
    } catch (e, stackTrace) {
      _log.e('$logPrefix Error', error: e, stackTrace: stackTrace);
      rethrow;
    }
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

  /// Fetches a sharh record by ID.
  Future<Sharh> getSharh(String sharhId) async {
    return _client.getSharhById(sharhId);
  }

  /// Fetches hadiths similar to the supplied hadith ID.
  Future<List<DetailedHadith>> getSimilarHadith(String hadithId) async {
    return _client.getSimilarHadith(hadithId);
  }

  /// Fetches the alternate narration for the supplied hadith ID.
  Future<DetailedHadith?> getAlternateHadith(String hadithId) async {
    return _client.getAlternateHadith(hadithId);
  }

  /// Fetches the usul entry for the supplied hadith ID.
  Future<UsulHadith> getUsulHadith(String hadithId) async {
    final response = await _client.getUsulHadith(hadithId);
    return response.data;
  }

  /// Searches rawi entries in the remote hadith API.
  Future<List<RawiItem>> searchRawi(String query) async {
    return _client.searchRawi(query);
  }
}
