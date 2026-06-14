/// Canonical bounds for the Madinah Mushaf (Hafs).
abstract final class MushafConstants {
  /// Total Mushaf pages (1–604).
  static const int pageCount = 604;

  /// Total ayahs in the Hafs enumeration (1–6236).
  static const int ayahCount = 6236;

  /// Total surahs (1–114).
  static const int surahCount = 114;

  /// Total juzs (1–30).
  static const int juzCount = 30;

  /// Number of two-page spreads (`pageCount` / 2).
  static const int twoPageSpreadCount = pageCount ~/ 2;

  /// Default light-theme surah header banner (precompiled `.svg.vec`).
  static const String surahHeaderLightAsset =
      'assets/images/surah-header.svg.vec';

  /// Default dark-theme surah header banner (precompiled `.svg.vec`).
  static const String surahHeaderDarkAsset =
      'assets/images/surah-header-dark.svg.vec';
}
