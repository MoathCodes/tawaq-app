// Keep explicit constructor names so Hive CE preserves persisted field IDs.
// ignore_for_file: unnecessary_type_name_in_constructor

import 'package:freezed_annotation/freezed_annotation.dart';

part 'hadith_favorite.freezed.dart';
part 'hadith_favorite.g.dart';

/// Persisted favorite hadith entry stored in local storage.
@freezed
abstract class HadithFavorite with _$HadithFavorite {
  /// Creates a persisted favorite hadith entry.
  factory HadithFavorite({
    required String key,
    required String hadith,
    required String rawi,
    required String mohdith,
    required String book,
    required String numberOrPage,
    required String hukm,
    required DateTime savedAt,
  }) = _HadithFavorite;

  /// Deserializes a favorite hadith entry from JSON.
  factory HadithFavorite.fromJson(Map<String, dynamic> json) =>
      _$HadithFavoriteFromJson(json);
}
