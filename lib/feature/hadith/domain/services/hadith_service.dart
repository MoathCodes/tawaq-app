import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/feature/hadith/data/models/hadith_recent_search.dart';
import 'package:tawaq/feature/hadith/data/repository/hadith_repository.dart';

part 'hadith_service.g.dart';

/// Provides the hadith service used by the UI and controllers.
@riverpod
Future<HadithService> hadithService(Ref ref) async {
  final repository = await ref.watch(hadithRepositoryProvider.future);
  final log = ref.read(loggerProvider);
  return HadithService(repository: repository, log: log);
}

/// Coordinates hadith operations and post-processing.
class HadithService {
  /// Creates the hadith service.
  HadithService({required this._repository, required this._log});

  final HadithRepository _repository;
  final Logger _log;

  /// Stores a recent-search query.
  Future<void> addRecentSearch(String query) {
    return _repository.addRecentSearch(query);
  }

  /// Clears the recent-search history.
  Future<void> clearRecentSearches() {
    return _repository.clearRecentSearches();
  }

  /// Removes one query from the recent-search history.
  Future<void> removeRecentSearch(String query) {
    return _repository.removeRecentSearch(query);
  }

  /// Returns the bookmarked hadiths.
  Future<List<DetailedHadith>> getFavorites() {
    return _repository.getFavorites();
  }

  /// Returns recent searches, newest first.
  Future<List<HadithRecentSearch>> getRecentSearches({int limit = 12}) {
    return _repository.getRecentSearches(limit: limit);
  }

  /// Resolves a hadith into its detailed record.
  Future<DetailedHadith?> resolveDetails(Hadith hadith) async {
    final params = HadithSearchParams(
      value: hadith.hadith,
      searchMethod: SearchMethod.exactMatch,
    );

    final response = await _repository.searchDetailed(params);
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

  /// Searches books for lookup suggestions.
  Future<ApiResponse<List<BookItem>>> searchBooks(String query) {
    return _repository.searchBooks(query);
  }

  /// Runs the fast hadith search endpoint.
  Future<ApiResponse<List<Hadith>>> searchFast(HadithSearchParams params) {
    return _repository.searchFast(params);
  }

  /// Returns a sharh with the explanatory text normalized for display.
  Future<Sharh> getSharh(String sharhId) {
    String? extractPureSharh(String? rawSharhText) {
      final regex = RegExp(
        r'^[\s\S]*?(?:التخريج|خلاصة حكم المحدث)[\s\S]*?\n\s*\n(?!\s*التخريج)',
      );

      return rawSharhText?.replaceAll(regex, '').trim();
    }

    return _repository.getSharh(sharhId).then((sharh) {
      final pureSharhText = extractPureSharh(sharh.sharhText);
      return sharh.copyWith(
        sharhMetadata: sharh.sharhMetadata?.copyWith(sharh: pureSharhText),
      );
    });
  }

  /// Returns hadiths similar to the supplied hadith ID.
  Future<List<DetailedHadith>> getSimilarHadith(String hadithId) {
    return _repository.getSimilarHadith(hadithId);
  }

  /// Returns the alternate narration for the supplied hadith ID.
  Future<DetailedHadith?> getAlternateHadith(String hadithId) {
    return _repository.getAlternateHadith(hadithId);
  }

  /// Returns the usul entry for the supplied hadith ID.
  Future<UsulHadith> getUsulHadith(String hadithId) {
    return _repository.getUsulHadith(hadithId);
  }

  /// Runs the detailed hadith search endpoint.
  Future<ApiResponse<List<DetailedHadith>>> searchDetailed(
    HadithSearchParams params,
  ) {
    return _repository.searchDetailed(params);
  }

  /// Searches scholars for lookup suggestions.
  Future<List<MohdithItem>> searchScholars(String query) {
    return _repository.searchScholars(query);
  }

  /// Searches rawi entries for lookup suggestions.
  Future<List<RawiItem>> searchRawi(String query) {
    return _repository.searchRawi(query);
  }

  /// Toggles the bookmarked state of a hadith.
  Future<void> toggleFavorite(HadithBase hadith) async {
    const logPrefix = '[HadithService.toggleFavorite] ';
    try {
      final key = _repository.favoriteKeyFromHadith(hadith);
      final isFavorite = await _repository.isFavoriteByKey(key);
      if (isFavorite) {
        await _repository.deleteFavorite(key);
        return;
      }

      if (hadith is DetailedHadith) {
        await _repository.createFavorite(hadith);
        return;
      }

      if (hadith is Hadith) {
        final resolved = await resolveDetails(hadith);
        if (resolved == null) {
          throw StateError('Unable to resolve hadith details for bookmarking');
        }
        await _repository.createFavorite(resolved);
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
