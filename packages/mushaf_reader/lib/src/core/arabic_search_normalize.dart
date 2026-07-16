/// Regex for alef normalization in Arabic search.
final RegExp kArabicSearchAlefRegex = RegExp('[أإآٱ]');

/// Arabic diacritics (tashkeel) and related marks removed before letter folding.
final RegExp kArabicSearchDiacriticsRegex = RegExp(
  r'[\u064B-\u065F\u0670\u06D6-\u06ED]',
);

/// Normalizes Arabic text for ayah search by removing common variations.
///
/// Handles:
/// - Diacritics (tashkeel)
/// - Alef variations (أ إ آ ٱ)
/// - Teh marbuta vs heh (ة → ه)
/// - Yeh variations (ى → ي)
/// - Tatweel / kashida (ـ)
///
/// Keep aligned with `tawaq/lib/core/text/arabic_search_normalize.dart`.
String normalizeArabicForSearch(String text) {
  return text
      .replaceAll(kArabicSearchDiacriticsRegex, '')
      .replaceAll(kArabicSearchAlefRegex, 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي')
      .replaceAll('ـ', '');
}
