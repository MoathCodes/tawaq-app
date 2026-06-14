/// Optional elements to include in a shared ayah image.
enum AyahShareInclude {
  /// Decorative surah header banner.
  surahHeader,

  /// Basmalah line before the verses.
  basmalah,

  /// App name footer.
  appName,

  /// Keep mushaf line breaks when sharing a partial page range.
  preserveLineBreaks,
}

/// Default include options for a share image.
///
/// Surah header and app name are always on. Basmalah is on whenever the range
/// includes a surah opening on the page, except Al-Fatiha (1) and At-Tawbah (9).
Set<AyahShareInclude> defaultAyahShareIncludes({
  required bool basmalahAvailable,
}) {
  return {
    AyahShareInclude.surahHeader,
    AyahShareInclude.appName,
    if (basmalahAvailable) AyahShareInclude.basmalah,
  };
}
