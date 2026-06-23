import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/surah_selector.dart';

/// Resolves the hizb (1–60) containing [ayahId] from denormalized bounds.
int? hizbNumberForAyahId(MushafReaderController controller, int ayahId) {
  for (var n = 1; n <= 60; n++) {
    final bounds = controller.hizbAyahBounds(n);
    if (bounds == null) continue;
    if (ayahId >= bounds.startAyahId && ayahId <= bounds.endAyahId) {
      return n;
    }
  }
  return null;
}

/// Ranks [hizbs] by relevance to [query] (number, prefix, or starting surah name).
Iterable<Hizb> searchHizbs({
  required List<Hizb> hizbs,
  required MushafReaderController controller,
  required String query,
  required bool isArabic,
}) {
  if (query.isEmpty) return hizbs;

  final normalized = query.toLowerCase().trim();
  final arabicQuery = normalizeArabicForSurahSearch(normalized);
  final queryNum = int.tryParse(normalized);

  final results = <(Hizb, int)>[];
  for (final hizb in hizbs) {
    var score = 0;
    if (queryNum != null && hizb.number == queryNum) {
      score = 100;
    } else if (hizb.number.toString().startsWith(normalized)) {
      score = 80;
    } else {
      final surahNumber = hizb.startSurahNumber;
      if (surahNumber != null) {
        final surah = controller.getSurahSync(surahNumber);
        if (surah?.nameEnglish?.toLowerCase().startsWith(normalized) ?? false) {
          score = 70;
        } else if (surah?.nameArabicSimplified != null &&
            normalizeArabicForSurahSearch(
              surah!.nameArabicSimplified!,
            ).startsWith(arabicQuery)) {
          score = 70;
        } else if (surah?.englishNameTranslation?.toLowerCase().startsWith(
              normalized,
            ) ??
            false) {
          score = 65;
        }
      }
    }
    if (score > 0) results.add((hizb, score));
  }

  results.sort((a, b) {
    final scoreCompare = b.$2.compareTo(a.$2);
    if (scoreCompare != 0) return scoreCompare;
    return a.$1.number.compareTo(b.$1.number);
  });

  return results.map((e) => e.$1);
}
