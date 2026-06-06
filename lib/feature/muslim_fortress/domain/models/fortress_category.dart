import 'package:hisn_elmoslem/hisn_elmoslem.dart';

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
