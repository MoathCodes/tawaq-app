import 'package:hisn_elmoslem/hisn_elmoslem.dart';
import 'package:tawaq/l10n/app_localizations.dart';

/// A Hisn al-Muslim title (chapter) for browse and category cards.
class FortressCategory {
  /// Creates a category row.
  const FortressCategory({
    required this.chapterId,
    required this.title,
    required this.recurrence,
    required this.supplicationCount,
    this.featured = false,
  });

  /// Hisn title id.
  final int chapterId;

  /// Arabic chapter name.
  final String title;

  /// Hisn recurrence schedule for localized subtitle display.
  final HisnRecurrence recurrence;

  /// Number of dhikr items in this title.
  final int supplicationCount;

  /// Whether this title is in the Hisn featured set.
  final bool featured;
}

/// Parsed commentary segment (intro prose or a numbered list item).
class FortressCommentaryBlock {
  /// Creates a commentary block.
  const FortressCommentaryBlock({
    required this.body,
    this.listNumber,
    this.citations = const [],
  });

  /// Optional list marker (`7` in `7- قوله: …`).
  final int? listNumber;

  /// Main prose with `/55` citation markers removed.
  final String body;

  /// Source lines extracted from `/55 … /55` pairs.
  final List<String> citations;
}

/// Ordered name fragments for first-run default fortress bookmarks.
const List<String> fortressDefaultBookmarkFragments = [
  ...HisnFeaturedTitles.fragments,
  'الأَذْكَارُ بَعْدَ السَّلاَمِ',
  'دُعَاءُ السَّفَرِ',
  'دُخُولِ السُّوقِ',
  'فَضْلُ الصَّلاَةِ عَلَى النَّبيِّ',
];

/// Localized recurrence label for fortress chapter subtitles.
String fortressRecurrenceLabel(
  HisnRecurrence recurrence,
  AppLocalizations l10n,
) =>
    switch (recurrence) {
      HisnRecurrence.daily => l10n.daily,
      HisnRecurrence.weekly => l10n.weekly,
      HisnRecurrence.monthly => l10n.monthly,
      HisnRecurrence.yearly => l10n.yearly,
    };
