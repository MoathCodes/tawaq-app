import 'package:hisn_elmoslem/hisn_elmoslem.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/feature/muslim_fortress/data/repository/hisn_repository.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_category.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_dua_item.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_fake_hadith.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_featured_dua.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_search_results.dart';

part 'fortress_service.g.dart';

/// Minimum trimmed query length before global search runs.
const fortressSearchMinQueryLength = 2;

/// Provides the fortress service used by UI providers.
@Riverpod(keepAlive: true)
Future<FortressService> fortressService(Ref ref) async {
  final repository = await ref.watch(hisnRepositoryProvider.future);
  return FortressService(repository);
}

/// Coordinates Hisn fortress operations and business rules.
class FortressService {
  /// Creates the fortress service.
  FortressService(this._repository);

  final HisnRepository _repository;

  /// All titles as sidebar/browse categories.
  List<FortressCategory> loadChapters() => _repository.loadChapters();

  /// Dhikr items for a title id with resolved category title.
  Future<List<FortressDuaItem>> loadDuasForChapter(
    int chapterId, {
    required List<FortressCategory> chapters,
  }) {
    final categoryTitle = _resolveCategoryTitle(chapters, chapterId);
    return Future.value(
      _repository.loadItemsForTitleId(
        chapterId,
        categoryTitle: categoryTitle,
      ),
    );
  }

  /// Dhikr items for a category model.
  List<FortressDuaItem> loadItemsForChapter(FortressCategory category) =>
      _repository.loadItemsForChapter(category);

  /// Global search across titles and dhikr contents.
  ///
  /// Returns [FortressSearchResults.empty] when [query] is shorter than
  /// [fortressSearchMinQueryLength] characters (after trim).
  FortressSearchResults search(String query, {int limit = 30}) {
    final trimmed = query.trim();
    if (trimmed.length < fortressSearchMinQueryLength) {
      return FortressSearchResults.empty;
    }
    return _repository.search(trimmed, limit: limit);
  }

  /// Known weak/fabricated hadith warnings.
  List<FortressFakeHadith> loadFakeHadithWarnings() =>
      _repository.loadFakeHadithWarnings();

  /// Featured cards for the welcome layout.
  List<FortressFeaturedDua> loadFeaturedDuas() =>
      _repository.loadFeaturedDuas();

  /// Full commentary for a content id (load on demand for study sheets).
  HisnCommentary? loadCommentaryForContent(int contentId) =>
      _repository.loadCommentaryForContent(contentId);

  String _resolveCategoryTitle(
    List<FortressCategory> chapters,
    int chapterId,
  ) {
    for (final category in chapters) {
      if (category.chapterId == chapterId) return category.title;
    }
    return '';
  }
}
