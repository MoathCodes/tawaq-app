/// Why the user is picking a reciter/moshaf — drives moshaf auto-resolution.
enum RecitationPickIntent {
  /// General listening (whole surah, drawer switch).
  general,

  /// Ayah-level playback (single ayah, range, highlight sync).
  ayahLevel,
}
