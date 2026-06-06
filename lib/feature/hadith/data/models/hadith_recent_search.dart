import 'package:freezed_annotation/freezed_annotation.dart';

part 'hadith_recent_search.freezed.dart';
part 'hadith_recent_search.g.dart';

/// Persisted recent-search entry stored in local storage.
@freezed
abstract class HadithRecentSearch with _$HadithRecentSearch {
  /// Creates a persisted recent-search entry.
  factory HadithRecentSearch({
    required int id,
    required String query,
    required DateTime searchedAt,
  }) = _HadithRecentSearch;

  /// Deserializes a recent-search entry from JSON.
  factory HadithRecentSearch.fromJson(Map<String, dynamic> json) =>
      _$HadithRecentSearchFromJson(json);
}
