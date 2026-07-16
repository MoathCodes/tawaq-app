import 'package:tawaq/feature/quran/presentation/widgets/share/ayah_share_card.dart' show AyahShareCard;

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

/// Maps selected share includes to [AyahShareCard] display flags.
class AyahShareCardOptions {
  /// Creates share card options from [includes].
  const AyahShareCardOptions(this.includes);

  /// Default include options for a share image.
  factory AyahShareCardOptions.defaults({required bool basmalahAvailable}) {
    return AyahShareCardOptions({
      AyahShareInclude.surahHeader,
      AyahShareInclude.appName,
      if (basmalahAvailable) AyahShareInclude.basmalah,
    });
  }

  /// Selected include options.
  final Set<AyahShareInclude> includes;

  /// Whether to show the decorative surah header.
  bool get showSurahHeader => includes.contains(AyahShareInclude.surahHeader);

  /// Whether to show the basmalah line.
  bool get showBasmalah => includes.contains(AyahShareInclude.basmalah);

  /// Whether to show the app name footer.
  bool get showAppName => includes.contains(AyahShareInclude.appName);

  /// Whether to preserve mushaf line breaks in partial ranges.
  bool get preserveMushafLineBreaks =>
      includes.contains(AyahShareInclude.preserveLineBreaks);

  /// Applies availability constraints and returns updated options.
  AyahShareCardOptions constrained({
    required bool basmalahAvailable,
    required bool lineBreaksToggleAvailable,
  }) {
    final next = Set.of(includes);
    if (!basmalahAvailable) {
      next.remove(AyahShareInclude.basmalah);
    }
    if (!lineBreaksToggleAvailable) {
      next.remove(AyahShareInclude.preserveLineBreaks);
    }
    return AyahShareCardOptions(next);
  }

  /// Returns a copy with updated includes.
  AyahShareCardOptions copyWithIncludes(Set<AyahShareInclude> includes) {
    return AyahShareCardOptions(includes);
  }
}

/// Default include options for a share image.
///
/// Surah header and app name are always on. Basmalah is on whenever the range
/// includes a surah opening on the page, except Al-Fatiha (1) and At-Tawbah (9).
Set<AyahShareInclude> defaultAyahShareIncludes({
  required bool basmalahAvailable,
}) {
  return AyahShareCardOptions.defaults(
    basmalahAvailable: basmalahAvailable,
  ).includes;
}
