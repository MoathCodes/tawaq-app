import 'package:mushaf_reader/mushaf_reader.dart';

/// Mushaf page and selection rules for ayah share images.
abstract final class AyahShareLogic {
  /// Collects unique ayah IDs on a page in reading order.
  static List<int> orderedAyahIdsOnPage(QuranPage page) {
    final ids = <int>[];
    final seen = <int>{};
    for (final block in page.surahs) {
      for (final fragment in block.ayahs) {
        if (seen.add(fragment.ayahId)) {
          ids.add(fragment.ayahId);
        }
      }
    }
    return ids;
  }

  /// Returns the surah block containing [ayahId], if any.
  static SurahBlock? surahBlockForAyah(QuranPage page, int ayahId) {
    for (final block in page.surahs) {
      if (block.ayahs.any((fragment) => fragment.ayahId == ayahId)) {
        return block;
      }
    }
    return null;
  }

  /// Whether the selection includes the start of [block] on this page.
  ///
  /// Uses [SurahBlock.hasBasmalah], which is `true` when the block begins at
  /// verse 1 of the surah (see mushaf_reader repository).
  static bool selectionIncludesBlockStart(
    SurahBlock block,
    Set<int> selectedIds,
  ) {
    if (!block.hasBasmalah || block.ayahs.isEmpty) return false;
    return selectedIds.contains(block.ayahs.first.ayahId);
  }

  /// Whether a standalone basmalah line should render for [block].
  ///
  /// Mirrors [MushafPage] — basmalah only when the surah starts on the page
  /// and the surah is neither Al-Fatiha (1) nor At-Tawbah (9).
  static bool shouldShowShareBasmalah(SurahBlock block, Set<int> selectedIds) {
    return selectionIncludesBlockStart(block, selectedIds) &&
        block.surahNumber != 9 &&
        block.surahNumber != 1;
  }

  /// Whether any block in the selection can show a basmalah line.
  static bool shareBasmalahAvailable(QuranPage page, List<int> ayahIds) {
    final selectedIds = ayahIds.toSet();
    return page.surahs.any(
      (block) => shouldShowShareBasmalah(block, selectedIds),
    );
  }

  /// Whether [ayahIds] includes verses from more than one surah on [page].
  static bool rangeSpansMultipleSurahs(QuranPage page, List<int> ayahIds) {
    final idSet = ayahIds.toSet();
    final surahs = <int>{};
    for (final block in page.surahs) {
      if (block.ayahs.any((f) => idSet.contains(f.ayahId))) {
        surahs.add(block.surahNumber);
      }
    }
    return surahs.length > 1;
  }

  /// Whether the selection touches any surah block on [page].
  static bool shareSurahHeaderAvailable(QuranPage page, List<int> ayahIds) {
    final selectedIds = ayahIds.toSet();
    return page.surahs.any(
      (block) =>
          block.ayahs.any((fragment) => selectedIds.contains(fragment.ayahId)),
    );
  }

  /// Whether to show the surah header above [block]'s selected ayahs.
  ///
  /// Shows a header for every surah segment touched by the selection,
  /// including blocks that begin mid-page ([SurahBlock.hasBasmalah] is false).
  static bool shouldShowShareSurahHeader(
    SurahBlock block,
    Set<int> selectedIds,
  ) {
    return block.ayahs.any((fragment) => selectedIds.contains(fragment.ayahId));
  }

  /// First selected ayah id on [page] in reading order.
  static int? firstSelectedAyahOnPage(QuranPage page, Set<int> selectedIds) {
    for (final block in page.surahs) {
      for (final fragment in block.ayahs) {
        if (selectedIds.contains(fragment.ayahId)) {
          return fragment.ayahId;
        }
      }
    }
    return null;
  }

  /// Whether [PageAyahWidget] should strip newlines for [block]'s selection.
  ///
  /// Compacts text when the share range starts mid-line: the first ayah on the
  /// page and/or the first ayah of the surah block on the page are missing.
  /// Surah openings on the page ([SurahBlock.hasBasmalah]) keep mushaf breaks.
  static bool shouldRemoveNewLinesForBlock(
    QuranPage page,
    SurahBlock block,
    Set<int> selectedIds,
  ) {
    final selectedFragments = block.ayahs
        .where((fragment) => selectedIds.contains(fragment.ayahId))
        .toList();
    if (selectedFragments.isEmpty) return false;

    final firstSelectedId = selectedFragments.first.ayahId;
    final blockStartId = block.ayahs.first.ayahId;
    if (firstSelectedId != blockStartId) return true;

    if (block.hasBasmalah) return false;

    final pageStartId = orderedAyahIdsOnPage(page).firstOrNull;
    final firstOnPageId = firstSelectedAyahOnPage(page, selectedIds);
    return pageStartId != null &&
        firstOnPageId == firstSelectedId &&
        !selectedIds.contains(pageStartId);
  }

  /// Maps a discrete ayah index to a normalized slider value in `[0, 1]`.
  static double ayahIndexToSliderValue(int index, int count) {
    if (count <= 1) return 0;
    return index / (count - 1);
  }

  /// Maps a normalized slider value to the nearest ayah index.
  static int sliderValueToAyahIndex(double value, int count) {
    if (count <= 1) return 0;
    return (value * (count - 1)).round().clamp(0, count - 1);
  }
}
