import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'hadith_filters.freezed.dart';
part 'hadith_filters.g.dart';

/// Lookup dimension for hadith filter autocomplete.
enum HadithLookupKind {
  /// Scholars (mohdith).
  scholars,

  /// Books.
  books,

  /// Narrators (rawi).
  rawi,
}

/// Search filters used by the hadith search screen.
@freezed
abstract class HadithFilters with _$HadithFilters {
  /// Creates a hadith filter set.
  const factory({
    @Default(SearchMethod.anyWord) SearchMethod searchMethod,
    @Default(<HadithTypeFilter>{}) Set<HadithTypeFilter> types,

    /// When true, limit results to hadiths that include takhrij in their
    /// metadata (Dorar.net `#specialist` tab / `&all` URL flag; site UI
    /// label: "متخصص").
    @Default(false) bool specialist,
    @Default('') String exclude,
    @Default(<String>[]) List<String> optionalPhrases,
    HadithSort? sort,
    @Default(<HadithDegree>[]) List<HadithDegree> degrees,
    @Default(<ReferenceChoice>[]) List<ReferenceChoice> scholars,
    @Default(<ReferenceChoice>[]) List<ReferenceChoice> books,
    @Default(<ReferenceChoice>[]) List<ReferenceChoice> rawi,
  }) = _HadithFilters;

  /// Deserializes a hadith filter set from JSON.
  factory fromJson(Map<String, dynamic> json) => _$HadithFiltersFromJson(json);
}

/// Convenience helpers for working with hadith filters.
extension HadithFiltersX on HadithFilters {
  /// Returns the number of active filter criteria.
  int get activeCount {
    var count = 0;
    if (searchMethod != SearchMethod.anyWord) count++;
    count += types.length;
    if (specialist) count++;
    if (exclude.trim().isNotEmpty) count++;
    count += optionalPhrases.where((p) => p.trim().isNotEmpty).length;
    if (sort != null) count++;
    count += degrees.length;
    count += scholars.length;
    count += books.length;
    count += rawi.length;
    return count;
  }
}
