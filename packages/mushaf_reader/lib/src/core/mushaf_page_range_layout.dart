import 'package:mushaf_reader/src/core/mushaf_constants.dart';
import 'package:mushaf_reader/src/data/models/ayah_fragment.dart';
import 'package:mushaf_reader/src/data/models/quran_page.dart';
import 'package:mushaf_reader/src/data/models/surah_block.dart';

/// Layout rules for rendering a subset of ayahs on a mushaf page.
///
/// Used by [MushafPageRange]. Host apps may call [basmalahPossible] and
/// [surahHeaderPossible] to drive UI toggles; the host still passes
/// [MushafPageRange.showSurahHeader] / [showBasmalah] to enable or disable
/// each chrome category.
abstract final class MushafPageRangeLayout {
  /// Collects unique ayah IDs on [page] in reading order.
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

  /// Ayah fragments from [block] that appear in [selectedIds].
  static List<AyahFragment> fragmentsForSelection(
    SurahBlock block,
    Set<int> selectedIds,
  ) {
    return block.ayahs
        .where((fragment) => selectedIds.contains(fragment.ayahId))
        .toList();
  }

  /// Whether the selection includes the start of [block] on this page.
  static bool selectionIncludesBlockStart(
    SurahBlock block,
    Set<int> selectedIds,
  ) {
    if (!block.hasBasmalah || block.ayahs.isEmpty) return false;
    return selectedIds.contains(block.ayahs.first.ayahId);
  }

  /// Whether a surah header can render for [block] when the host enables
  /// surah headers.
  static bool shouldShowSurahHeader(
    SurahBlock block,
    Set<int> selectedIds,
  ) {
    return block.ayahs.any((fragment) => selectedIds.contains(fragment.ayahId));
  }

  /// Whether a basmalah line can render for [block] when the host enables
  /// basmalah — mirrors [MushafPage] (excludes surahs 1 and 9).
  static bool shouldShowBasmalah(SurahBlock block, Set<int> selectedIds) {
    return selectionIncludesBlockStart(block, selectedIds) &&
        block.surahNumber != 9 &&
        block.surahNumber != 1;
  }

  /// Whether any selected block on [page] could show a basmalah line.
  static bool basmalahPossible(QuranPage page, Iterable<int> ayahIds) {
    final selectedIds = ayahIds.toSet();
    return page.surahs.any(
      (block) => shouldShowBasmalah(block, selectedIds),
    );
  }

  /// Whether any selected block on [page] could show a surah header.
  static bool surahHeaderPossible(QuranPage page, Iterable<int> ayahIds) {
    final selectedIds = ayahIds.toSet();
    return page.surahs.any(
      (block) => shouldShowSurahHeader(block, selectedIds),
    );
  }

  /// Whether [ayahIds] includes verses from more than one surah on [page].
  static bool spansMultipleSurahs(QuranPage page, Iterable<int> ayahIds) {
    final idSet = ayahIds.toSet();
    final surahs = <int>{};
    for (final block in page.surahs) {
      if (block.ayahs.any((f) => idSet.contains(f.ayahId))) {
        surahs.add(block.surahNumber);
      }
    }
    return surahs.length > 1;
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

  /// Whether any [block] on [page] would strip mushaf line breaks for
  /// [selectedIds] in range mode.
  static bool newlinesWouldCompact(QuranPage page, Iterable<int> selectedIds) {
    final ids = selectedIds.toSet();
    return page.surahs.any(
      (block) => shouldCompactNewlines(page, block, ids),
    );
  }

  /// Whether ayah text should strip mushaf line breaks for [block].
  ///
  /// Compacts text when the range starts mid-line. Surah openings on the page
  /// ([SurahBlock.hasBasmalah]) keep mushaf breaks.
  static bool shouldCompactNewlines(
    QuranPage page,
    SurahBlock block,
    Set<int> selectedIds,
  ) {
    final selectedFragments = fragmentsForSelection(block, selectedIds);
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

  /// Contiguous ayah ids between [startAyahId] and [endAyahId] on [page].
  static List<int> contiguousIdsOnPage(
    QuranPage page, {
    required int startAyahId,
    required int endAyahId,
  }) {
    final ordered = orderedAyahIdsOnPage(page);
    final startIndex = ordered.indexOf(startAyahId);
    final endIndex = ordered.indexOf(endAyahId);
    if (startIndex == -1 || endIndex == -1) {
      throw ArgumentError(
        'Ayah ids $startAyahId and/or $endAyahId are not on page '
        '${page.pageNumber}',
      );
    }
    final lo = startIndex < endIndex ? startIndex : endIndex;
    final hi = startIndex < endIndex ? endIndex : startIndex;
    return ordered.sublist(lo, hi + 1);
  }

  /// Global contiguous ayah ids from [startAyahId] through [endAyahId].
  static List<int> contiguousGlobalIds({
    required int startAyahId,
    required int endAyahId,
  }) {
    if (startAyahId < 1 ||
        endAyahId < 1 ||
        startAyahId > MushafConstants.ayahCount ||
        endAyahId > MushafConstants.ayahCount) {
      throw ArgumentError(
        'Ayah ids must be in 1..${MushafConstants.ayahCount}',
      );
    }
    final lo = startAyahId < endAyahId ? startAyahId : endAyahId;
    final hi = startAyahId < endAyahId ? endAyahId : startAyahId;
    return List.generate(hi - lo + 1, (i) => lo + i);
  }
}
