import '../data/mushaf_page_resolver.dart';
import '../models/models.dart';
import '../models/quran_presentation.dart';

/// Classifies parsed Quranic ranges into a [HisnQuranPresentation].
abstract final class QuranPresentationClassifier {
  /// Derives the recommended rendering mode for [ranges].
  static HisnQuranPresentation classify(List<HisnVerseRange> ranges) {
    if (ranges.isEmpty) {
      throw ArgumentError.value(ranges, 'ranges', 'must not be empty');
    }

    if (ranges.length == 1 && ranges.first.isSingleVerse) {
      return HisnQuranSingleAyah(ranges.first);
    }

    final pages = MushafPageResolver.pagesForRanges(ranges);
    final allCompleteSurahs = ranges.every(MushafPageResolver.isCompleteSurah);

    if (allCompleteSurahs) {
      return HisnQuranMushafPages(pages: pages, ranges: ranges);
    }

    if (MushafPageResolver.rangesMatchPagesExactly(ranges, pages)) {
      return HisnQuranMushafPages(pages: pages, ranges: ranges);
    }

    return HisnQuranPassage(ranges);
  }
}
