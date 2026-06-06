import 'package:mushaf_reader/mushaf_reader.dart';

/// Pure ayah reference formatting (no localization or UI dependencies).
abstract final class AyahReferenceLogic {
  /// Resolves a display surah name from metadata, with English fallback.
  static String surahName(
    Surah? surah,
    int surahNumber, {
    required bool preferArabic,
    required String fallbackName,
  }) {
    if (surah == null) return fallbackName;
    return (preferArabic ? surah.nameArabic : surah.nameEnglish) ??
        surah.nameArabic ??
        surah.nameEnglish ??
        fallbackName;
  }

  /// Filesystem-safe ayah reference for export filenames (English surah name).
  static String filenameReference({
    required Ayah ayah,
    required Surah? surah,
  }) {
    if (surah == null) {
      return Ayah.sanitizeReferenceForFilename(ayah.reference);
    }
    return Ayah.sanitizeReferenceForFilename(
      ayah.referenceWithSurahName(surah, preferArabic: false),
    );
  }
}
