/// How the user scoped a memorization range in the range dialog.
enum RangeScopePreset {
  /// A single ayah (from = to).
  thisAyah,

  /// Ayah 1 through the last ayah of a surah.
  thisSurah,

  /// The juz containing the seed ayah.
  thisJuz,

  /// The hizb containing the seed ayah.
  thisHizb,

  /// Start at the seed ayah and continue to the end of the Quran.
  continueFromHere,

  /// Manually chosen endpoints.
  custom,
}
