import 'package:mushaf_reader/mushaf_reader.dart';

/// Resolves a localized surah name without inventing a numbered placeholder.
///
/// A missing name is expected while the mushaf catalog is loading. Callers
/// should hide the name-bearing UI until this returns a value.
String? localizedSurahName(
  Surah? surah, {
  required bool preferArabic,
}) {
  if (surah == null) return null;
  return preferArabic
      ? (surah.nameArabic ?? surah.nameEnglish)
      : (surah.nameEnglish ?? surah.nameArabic);
}
