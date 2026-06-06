import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'hadith_filters.freezed.dart';
part 'hadith_filters.g.dart';

/// A lookup reference used by hadith search filters.
@freezed
abstract class HadithLookupRef with _$HadithLookupRef {
  /// Creates a lookup reference.
  const factory HadithLookupRef({required String id, required String name}) =
      _HadithLookupRef;

  /// Deserializes a lookup reference from JSON.
  factory HadithLookupRef.fromJson(Map<String, dynamic> json) =>
      _$HadithLookupRefFromJson(json);
}

/// Search filters used by the hadith search screen.
@freezed
abstract class HadithFilters with _$HadithFilters {
  /// Creates a hadith filter set.
  const factory HadithFilters({
    @Default(SearchMethod.anyWord) SearchMethod searchMethod,
    @Default(SearchZone.all) SearchZone zone,
    @Default(false) bool specialist,
    @Default(<HadithDegree>[]) List<HadithDegree> degrees,
    @Default(<HadithLookupRef>[]) List<HadithLookupRef> scholars,
    @Default(<HadithLookupRef>[]) List<HadithLookupRef> books,
    @Default(<HadithLookupRef>[]) List<HadithLookupRef> rawi,
  }) = _HadithFilters;

  /// Deserializes a hadith filter set from JSON.
  factory HadithFilters.fromJson(Map<String, dynamic> json) =>
      _$HadithFiltersFromJson(json);
}

/// Converts lookup references into the Dorar Hadith API reference types.
extension HadithLookupRefX on HadithLookupRef {
  /// Converts this lookup reference to a scholar reference.
  MohdithReference toMohdithReference() => MohdithReference(id: id, name: name);

  /// Converts this lookup reference to a book reference.
  BookReference toBookReference() => BookReference(id: id, name: name);

  /// Converts this lookup reference to a rawi reference.
  RawiReference toRawiReference() => RawiReference(id: id, name: name);
}

/// Convenience helpers for working with hadith filters.
extension HadithFiltersX on HadithFilters {
  /// Returns the number of active filter criteria.
  int get activeCount {
    var count = 0;
    if (searchMethod != SearchMethod.anyWord) count++;
    if (zone != SearchZone.all) count++;
    if (specialist) count++;
    count += degrees.length;
    count += scholars.length;
    count += books.length;
    count += rawi.length;
    return count;
  }
}
