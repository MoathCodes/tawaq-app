/// Summary card for a featured chapter on the welcome screen.
class FortressFeaturedDua {
  /// Creates a featured card model.
  const FortressFeaturedDua({
    required this.chapterId,
    required this.title,
    required this.reference,
    required this.itemCount,
  });

  /// Hisn title id for navigation.
  final int chapterId;

  /// Chapter title.
  final String title;

  /// Short takhreej excerpt from the first item.
  final String reference;

  /// Number of dhikr items in the featured chapter (for length hint).
  final int itemCount;
}
