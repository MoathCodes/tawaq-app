import 'package:mushaf_reader/mushaf_reader.dart';

/// Further normalizes Arabic text for fuzzy search, beyond
/// [Surah.nameArabicSimplified], by folding letters that are commonly
/// typed interchangeably (e.g. on keyboards without a dedicated key):
/// alef maksura/ya (ى/ي) and teh marbuta/ha (ة/ه).
///
/// Must be applied to both the search query and the candidate field so
/// the two sides stay comparable.
String normalizeArabicForSurahSearch(String s) {
  return s.replaceAll('ى', 'ي').replaceAll('ة', 'ه');
}

/// Ranks [surahs] by relevance to [query] using the shared Quran surah search.
Iterable<Surah> searchSurahs(List<Surah> surahs, String query) {
  if (query.isEmpty) return surahs;

  final normalized = query.toLowerCase().trim();
  final arabicQuery = normalizeArabicForSurahSearch(normalized);
  final queryNum = int.tryParse(normalized);

  final results = <(Surah, int)>[];
  for (final surah in surahs) {
    var score = 0;

    if (queryNum != null && surah.number == queryNum) {
      score = 100;
    } else if (surah.number.toString().startsWith(normalized)) {
      score = 80;
    } else if (surah.nameEnglish?.toLowerCase().startsWith(normalized) ?? false) {
      score = 70;
    } else if (surah.nameArabicSimplified != null &&
        normalizeArabicForSurahSearch(
          surah.nameArabicSimplified!,
        ).startsWith(arabicQuery)) {
      score = 70;
    } else if (surah.englishNameTranslation?.toLowerCase().startsWith(
          normalized,
        ) ??
        false) {
      score = 65;
    } else if (surah.nameEnglish?.toLowerCase().contains(normalized) ?? false) {
      score = 50;
    } else if (surah.englishNameTranslation?.toLowerCase().contains(
          normalized,
        ) ??
        false) {
      score = 45;
    } else if (surah.nameArabicSimplified != null &&
        normalizeArabicForSurahSearch(
          surah.nameArabicSimplified!,
        ).contains(arabicQuery)) {
      score = 50;
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
