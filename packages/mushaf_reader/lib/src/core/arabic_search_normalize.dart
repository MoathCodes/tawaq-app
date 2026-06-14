/// Regex for alef normalization in Arabic search.
final RegExp kArabicSearchAlefRegex = RegExp('[أإآٱ]');

/// Normalizes Arabic text for ayah search by removing common variations.
///
/// Handles:
/// - Alef variations (أ إ آ ٱ)
/// - Teh marbuta vs heh (ة → ه)
/// - Yeh variations (ى → ي)
/// - Tatweel / kashida (ـ)
String normalizeArabicForSearch(String text) {
  return text
      .replaceAll(kArabicSearchAlefRegex, 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي')
      .replaceAll('ـ', '');
}
