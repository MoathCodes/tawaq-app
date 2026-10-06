import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/core/text/arabic_search_normalize.dart';

/// Normalizes picker search text without changing Quran source or display text.
String normalizeQuranSearchQuery(String query) {
  final digits = query.replaceAllMapped(RegExp('[٠-٩]'), (match) {
    return (match[0]!.codeUnitAt(0) - 0x0660).toString();
  });
  return normalizeArabicForSearch(digits.toLowerCase().trim());
}

/// Matches common Latin transliteration punctuation and vowel variants only.
/// This derives search keys; source names and Quran text are never rewritten.
String _surahNameKey(String name) =>
    normalizeQuranSearchQuery(name)
        .replaceFirst(RegExp(r'^al[\s-]*'), '')
        .replaceAll(RegExp(r"[\s’'\-]"), '')
        .replaceAllMapped(RegExp(r'([aeiou])\1+'), (m) => m[1]!)
        .replaceFirst(RegExp(r'(?<=[aeiou])h$'), '');

/// Ranks [surahs] by relevance to [query] using the shared Quran surah search.
Iterable<Surah> searchSurahs(List<Surah> surahs, String query) {
  final normalized = normalizeQuranSearchQuery(query);
  if (normalized.isEmpty) return surahs;
  final queryNum = int.tryParse(normalized);
  final nameQuery = _surahNameKey(query);

  final results = <(Surah, int)>[];
  for (final surah in surahs) {
    var score = 0;

    if (queryNum != null && surah.number == queryNum) {
      score = 100;
    } else if (surah.number.toString().startsWith(normalized)) {
      score = 80;
    } else if (normalizeQuranSearchQuery(surah.nameEnglish ?? '')
        .startsWith(normalized)) {
      score = 70;
    } else if (surah.nameArabicSimplified != null &&
        normalizeQuranSearchQuery(surah.nameArabicSimplified!)
            .startsWith(normalized)) {
      score = 70;
    } else if (normalizeQuranSearchQuery(surah.englishNameTranslation ?? '')
        .startsWith(normalized)) {
      score = 65;
    } else if (normalizeQuranSearchQuery(surah.nameEnglish ?? '')
        .contains(normalized)) {
      score = 50;
    } else if (normalizeQuranSearchQuery(surah.englishNameTranslation ?? '')
        .contains(normalized)) {
      score = 45;
    } else if (surah.nameArabicSimplified != null &&
        normalizeQuranSearchQuery(surah.nameArabicSimplified!)
            .contains(normalized)) {
      score = 50;
    }

    if (score == 0 &&
        nameQuery.length >= 2 &&
        [surah.nameEnglish, surah.englishNameTranslation, surah.nameArabic]
            .whereType<String>()
            .any((name) => _surahNameKey(name).contains(nameQuery))) {
      score = 40;
    }
    if (score > 0) results.add((surah, score));
  }

  results.sort((a, b) {
    final scoreCompare = b.$2.compareTo(a.$2);
    if (scoreCompare != 0) return scoreCompare;
    return a.$1.number.compareTo(b.$1.number);
  });

  return results.map((e) => e.$1);
}
