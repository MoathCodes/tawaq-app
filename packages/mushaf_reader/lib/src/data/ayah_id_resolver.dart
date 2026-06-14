import 'package:mushaf_reader/src/data/models/surah.dart';

import 'package:mushaf_reader/src/core/mushaf_constants.dart';

/// Maps (surah, ayah-in-surah) to the global ayah id without Hive I/O.
///
/// Uses per-surah verse counts from cached [Surah.ayahCount], with a static
/// Hafs table as fallback when counts are missing from storage.
///
/// For the common case without surah metadata, prefer [Ayah.globalIdFor].
abstract final class AyahIdResolver {
  /// Total ayahs in the Madinah Mushaf (Hafs).
  ///
  /// Alias for [MushafConstants.ayahCount].
  static const int totalAyahs = MushafConstants.ayahCount;

  /// Verse count per surah (1–114), standard Hafs enumeration.
  static const List<int> ayahsPerSurah = <int>[
    7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99,
    128, 111, 110, 98, 135, 112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34,
    30, 73, 54, 45, 83, 182, 88, 75, 85, 54, 53, 89, 59, 37, 35, 38, 29, 18,
    45, 60, 49, 62, 55, 78, 96, 29, 22, 24, 13, 14, 11, 11, 18, 12, 12, 30,
    52, 52, 44, 28, 28, 20, 56, 40, 31, 50, 40, 46, 42, 29, 19, 36, 25, 22,
    17, 19, 26, 30, 20, 15, 21, 11, 8, 8, 19, 5, 8, 8, 11, 11, 8, 3, 9, 5,
    4, 7, 3, 6, 3, 5, 4, 5, 6,
  ];

  /// Builds `_starts[s]` = global id of the first ayah in surah `s` (1–114).
  ///
  /// Index 0 is unused. After building, the next id would be [totalAyahs] + 1.
  static List<int> buildStarts(Map<int, Surah> surahsByNumber) {
    final starts = List<int>.filled(115, 0);
    var nextId = 1;
    for (var surah = 1; surah <= 114; surah++) {
      starts[surah] = nextId;
      nextId += _ayahCountForSurah(surah, surahsByNumber);
    }
    assert(
      nextId == totalAyahs + 1,
      'Ayah id table sums to ${nextId - 1}, expected $totalAyahs',
    );
    return starts;
  }

  /// Returns global ayah id, or `null` if [surah] / [ayahInSurah] is out of range.
  static int? globalId({
    required int surah,
    required int ayahInSurah,
    required List<int> startsBySurah,
    Map<int, Surah>? surahsByNumber,
  }) {
    if (surah < 1 || surah > 114) return null;
    final count = _ayahCountForSurah(surah, surahsByNumber);
    if (ayahInSurah < 1 || ayahInSurah > count) return null;
    return startsBySurah[surah] + ayahInSurah - 1;
  }

  static int _ayahCountForSurah(int surah, Map<int, Surah>? surahsByNumber) {
    final fromBox = surahsByNumber?[surah]?.ayahCount;
    if (fromBox != null && fromBox > 0) return fromBox;
    return ayahsPerSurah[surah - 1];
  }
}
