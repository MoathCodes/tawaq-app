import 'models.dart';

/// How Quranic thikr content should be rendered by consumers.
sealed class HisnQuranPresentation {
  /// Creates a presentation mode.
  const HisnQuranPresentation();

  /// Verse ranges referenced by this thikr.
  List<HisnVerseRange> get ranges;
}

/// A single ayah — render with inline [AyahWidget] / equivalent.
final class HisnQuranSingleAyah extends HisnQuranPresentation {
  /// Creates a single-ayah presentation.
  const HisnQuranSingleAyah(this.range);

  /// The referenced ayah.
  final HisnVerseRange range;

  @override
  List<HisnVerseRange> get ranges => [range];
}

/// A multi-ayah passage that does not align to full mushaf pages.
///
/// Render as one continuous glyph flow for the exact ayahs in [ranges].
final class HisnQuranPassage extends HisnQuranPresentation {
  /// Creates a passage presentation.
  const HisnQuranPassage(this.ranges);

  @override
  final List<HisnVerseRange> ranges;
}

/// One or more complete mushaf pages.
///
/// Render with [MushafPage] for each page in [pages]. The original
/// [ranges] are kept for metadata and validation.
final class HisnQuranMushafPages extends HisnQuranPresentation {
  /// Creates a mushaf-page presentation.
  const HisnQuranMushafPages({
    required this.pages,
    required this.ranges,
  });

  /// Mushaf page numbers (1–604), sorted ascending.
  final List<int> pages;

  @override
  final List<HisnVerseRange> ranges;
}
