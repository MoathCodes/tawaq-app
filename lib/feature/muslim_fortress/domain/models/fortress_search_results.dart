import 'package:tawaq/feature/muslim_fortress/domain/fortress_models.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_dua_item.dart';

/// A content-level global search hit with its parent chapter.
class FortressSearchContentHit {
  /// Creates a search content hit.
  const new({
    required this.chapterId,
    required this.categoryTitle,
    required this.item,
  });

  /// Parent Hisn title id.
  final int chapterId;

  /// Parent chapter title.
  final String categoryTitle;

  /// Matching dhikr item.
  final FortressDuaItem item;
}

/// Aggregated Hisn search results for titles and contents.
class FortressSearchResults {
  /// Creates search results.
  const new({
    required this.titles,
    required this.contents,
    required this.totalTitles,
    required this.totalContents,
  });

  /// Empty result set used before a query or when nothing matches.
  static const empty = FortressSearchResults(
    titles: [],
    contents: [],
    totalTitles: 0,
    totalContents: 0,
  );

  /// Matching title rows (may be truncated by query limit).
  final List<FortressCategory> titles;

  /// Matching content hits (may be truncated by query limit).
  final List<FortressSearchContentHit> contents;

  /// Total title matches reported by Hisn search.
  final int totalTitles;

  /// Total content matches reported by Hisn search.
  final int totalContents;

  /// Whether both title and content lists are empty.
  bool get isEmpty => titles.isEmpty && contents.isEmpty;
}
