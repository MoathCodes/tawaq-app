import 'enums.dart';

/// Inclusive surah/ayah range parsed from `QuranText[(s:a:e)]` markers.
final class HisnVerseRange {
  /// Creates a verse range within a single surah.
  const HisnVerseRange({
    required this.surah,
    required this.startAyah,
    required this.endAyah,
  }) : assert(surah >= 1 && surah <= 114),
       assert(startAyah >= 1),
       assert(endAyah >= startAyah);

  /// Surah number (1–114).
  final int surah;

  /// First ayah in the range (inclusive).
  final int startAyah;

  /// Last ayah in the range (inclusive).
  final int endAyah;

  /// Number of ayahs in this range.
  int get length => endAyah - startAyah + 1;

  /// Whether this is a single ayah.
  bool get isSingleVerse => startAyah == endAyah;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HisnVerseRange &&
          surah == other.surah &&
          startAyah == other.startAyah &&
          endAyah == other.endAyah;

  @override
  int get hashCode => Object.hash(surah, startAyah, endAyah);

  @override
  String toString() => 'HisnVerseRange($surah:$startAyah-$endAyah)';
}

/// A chapter/title in Hisn al-Muslim.
final class HisnTitle {
  /// Creates a title.
  const HisnTitle({
    required this.id,
    required this.name,
    required this.order,
    required this.recurrence,
    this.searchText = '',
    this.audioFileName,
  });

  /// Primary key.
  final int id;

  /// Arabic title name.
  final String name;

  /// Display order.
  final int order;

  /// How often this title is recited.
  final HisnRecurrence recurrence;

  /// Normalized search text from the database.
  final String searchText;

  /// Local audio filename (ignored when using remote URLs only).
  final String? audioFileName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is HisnTitle && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Remote audio reference for a dhikr item.
final class HisnAudio {
  /// Creates remote audio metadata.
  const HisnAudio({required this.remoteUrl});

  /// Remote MP3 URL (e.g. hisnmuslim.com).
  final Uri remoteUrl;
}

/// Lightweight commentary presence flags for list/browse UI.
final class HisnCommentaryFlags {
  /// Creates flags.
  const HisnCommentaryFlags({
    required this.hasSharh,
    required this.hasHadith,
    required this.hasBenefit,
  });

  /// Whether sharh text is present.
  final bool hasSharh;

  /// Whether related hadith text is present.
  final bool hasHadith;

  /// Whether benefit text is present.
  final bool hasBenefit;

  /// Whether any commentary field is present.
  bool get isNotEmpty => hasSharh || hasHadith || hasBenefit;
}

/// Commentary / explanation attached to a content row.
final class HisnCommentary {
  /// Creates commentary.
  const HisnCommentary({
    required this.id,
    required this.contentId,
    required this.sharh,
    required this.hadith,
    required this.benefit,
  });

  /// Primary key.
  final int id;

  /// Foreign key to [HisnContent.id].
  final int contentId;

  /// Detailed sharh text.
  final String sharh;

  /// Related hadith text.
  final String hadith;

  /// Benefit / faidah text.
  final String benefit;

  /// Whether any commentary field is non-empty.
  bool get isEmpty => sharh.isEmpty && hadith.isEmpty && benefit.isEmpty;

  /// Whether any commentary field is present.
  bool get isNotEmpty => !isEmpty;
}

/// A known weak or fabricated hadith warning.
final class HisnFakeHadith {
  /// Creates a fake-hadith entry.
  const HisnFakeHadith({
    required this.id,
    required this.text,
    required this.darga,
    required this.source,
  });

  /// Primary key.
  final int id;

  /// Hadith text.
  final String text;

  /// Grading / darga.
  final String darga;

  /// Source reference.
  final String source;
}

/// Search query parameters.
final class HisnSearchQuery {
  /// Creates a search query.
  const HisnSearchQuery({
    required this.value,
    this.mode = HisnSearchMode.typical,
    this.target = HisnSearchTarget.content,
    this.limit = 50,
    this.offset = 0,
  });

  /// Search text.
  final String value;

  /// Matching strategy.
  final HisnSearchMode mode;

  /// Titles or contents.
  final HisnSearchTarget target;

  /// Page size.
  final int limit;

  /// Result offset.
  final int offset;
}

/// Criteria for filtering contents by source or authenticity.
final class HisnFilterCriteria {
  /// Creates filter criteria.
  const HisnFilterCriteria({
    this.activeSources = const {},
    this.activeAuthenticities = const {},
    this.filterBySource = false,
    this.filterByAuthenticity = false,
  });

  /// Active source filters (when [filterBySource] is true).
  final Set<HisnSourceFilter> activeSources;

  /// Active authenticity filters (when [filterByAuthenticity] is true).
  final Set<HisnAuthenticity> activeAuthenticities;

  /// Whether to filter by hadith source substrings.
  final bool filterBySource;

  /// Whether to filter by `hokm` value.
  final bool filterByAuthenticity;

  /// No filtering applied.
  static const none = HisnFilterCriteria();
}
