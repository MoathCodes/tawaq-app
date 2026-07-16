/// Regex for alef normalization in Arabic search.
final RegExp kArabicSearchAlefRegex = RegExp('[أإآٱ]');

/// Arabic diacritics (tashkeel) and related marks removed before letter folding.
final RegExp kArabicSearchDiacriticsRegex = RegExp(
  r'[\u064B-\u065F\u0670\u06D6-\u06ED]',
);

/// Normalizes Arabic text for fuzzy search and matching.
///
/// Apply to **both** the query and the candidate field so comparisons stay
/// symmetric. Handles:
/// - Diacritics (tashkeel)
/// - Alef variants (أ إ آ ٱ → ا)
/// - Ta marbuta (ة → ه)
/// - Alef maksura (ى → ي)
/// - Kashida / tatweel (ـ)
///
/// Package-local copies exist in `mushaf_reader` (ayah index search) and
/// `dorar_hadith` (`normalizeArabicSearch`); keep them aligned when changing
/// this function.
String normalizeArabicForSearch(String text) {
  return text
      .replaceAll(kArabicSearchDiacriticsRegex, '')
      .replaceAll(kArabicSearchAlefRegex, 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي')
      .replaceAll('ـ', '');
}

/// Returns whether [text] contains [query] after Arabic search normalization.
bool arabicSearchContains(String text, String query) {
  if (query.isEmpty) return true;
  return normalizeArabicForSearch(text).contains(normalizeArabicForSearch(query));
}

/// Returns whether [text] starts with [query] after Arabic search normalization.
bool arabicSearchStartsWith(String text, String query) {
  if (query.isEmpty) return true;
  return normalizeArabicForSearch(text).startsWith(
    normalizeArabicForSearch(query),
  );
}
