import '../data/mushaf_page_index.dart';
import '../models/models.dart';

/// Resolves Madinah Mushaf pages from surah/ayah ranges.
abstract final class MushafPageResolver {
  static final _startsBySurah = _buildStarts();

  /// Mushaf page for a surah/ayah reference.
  static int pageForSurahAyah({required int surah, required int ayah}) {
    final id = globalIdForSurahAyah(surah: surah, ayah: ayah);
    if (id == null) {
      throw ArgumentError('Invalid surah/ayah: $surah:$ayah');
    }
    return MushafPageIndex.pageByGlobalId[id];
  }

  /// Global ayah id (1–6236) or null when out of range.
  static int? globalIdForSurahAyah({required int surah, required int ayah}) {
    if (surah < 1 || surah > 114) return null;
    final count = MushafPageIndex.ayahsPerSurah[surah - 1];
    if (ayah < 1 || ayah > count) return null;
    return _startsBySurah[surah] + ayah - 1;
  }

  /// Whether [range] covers an entire surah from ayah 1 to the last ayah.
  static bool isCompleteSurah(HisnVerseRange range) {
    if (range.startAyah != 1) return false;
    return range.endAyah == MushafPageIndex.ayahsPerSurah[range.surah - 1];
  }

  /// Sorted unique mushaf pages touched by [ranges].
  static List<int> pagesForRanges(List<HisnVerseRange> ranges) {
    final pages = <int>{};
    for (final range in ranges) {
      for (var ayah = range.startAyah; ayah <= range.endAyah; ayah++) {
        pages.add(pageForSurahAyah(surah: range.surah, ayah: ayah));
      }
    }
    return pages.toList()..sort();
  }

  /// All (surah, ayah) pairs covered by [ranges].
  static Set<SurahAyahRef> expandRanges(List<HisnVerseRange> ranges) {
    final refs = <SurahAyahRef>{};
    for (final range in ranges) {
      for (var ayah = range.startAyah; ayah <= range.endAyah; ayah++) {
        refs.add(SurahAyahRef(range.surah, ayah));
      }
    }
    return refs;
  }

  /// All (surah, ayah) pairs printed on [pages].
  static Set<SurahAyahRef> ayahsOnPages(Iterable<int> pages) {
    final pageSet = pages.toSet();
    final refs = <SurahAyahRef>{};
    for (var id = 1; id <= MushafPageIndex.totalAyahs; id++) {
      final page = MushafPageIndex.pageByGlobalId[id];
      if (!pageSet.contains(page)) continue;
      final ref = surahAyahForGlobalId(id);
      if (ref != null) refs.add(ref);
    }
    return refs;
  }

  /// Whether [ranges] cover exactly the ayahs on [pages] (no more, no less).
  static bool rangesMatchPagesExactly(
    List<HisnVerseRange> ranges,
    List<int> pages,
  ) {
    final rangeAyahs = expandRanges(ranges);
    final pageAyahs = ayahsOnPages(pages);
    return rangeAyahs.length == pageAyahs.length &&
        rangeAyahs.containsAll(pageAyahs);
  }

  /// Surah/ayah for a global ayah id.
  static SurahAyahRef? surahAyahForGlobalId(int globalId) {
    if (globalId < 1 || globalId > MushafPageIndex.totalAyahs) return null;
    for (var surah = 114; surah >= 1; surah--) {
      final start = _startsBySurah[surah];
      final count = MushafPageIndex.ayahsPerSurah[surah - 1];
      final end = start + count - 1;
      if (globalId >= start && globalId <= end) {
        return SurahAyahRef(surah, globalId - start + 1);
      }
    }
    return null;
  }

  static List<int> _buildStarts() {
    final starts = List<int>.filled(115, 0);
    var nextId = 1;
    for (var surah = 1; surah <= 114; surah++) {
      starts[surah] = nextId;
      nextId += MushafPageIndex.ayahsPerSurah[surah - 1];
    }
    return starts;
  }
}

/// A surah/ayah coordinate.
final class SurahAyahRef {
  /// Creates a reference.
  const SurahAyahRef(this.surah, this.ayah);

  /// Surah number (1–114).
  final int surah;

  /// Ayah number within the surah.
  final int ayah;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurahAyahRef && surah == other.surah && ayah == other.ayah;

  @override
  int get hashCode => Object.hash(surah, ayah);

  @override
  String toString() => '$surah:$ayah';
}
