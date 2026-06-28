import 'package:flutter/material.dart';
import 'package:tawaq/l10n/app_localizations.dart';

/// Accessibility labels and small wrappers for the Hisn (Muslim Fortress) UI.
abstract final class FortressA11y {
  FortressA11y._();

  /// Announced label for a prev/next control (disabled state is via [enabled]).
  static String navActionLabel(
    AppLocalizations l10n, {
    required bool isPrevious,
  }) => isPrevious ? l10n.fortressPrevious : l10n.next;

  /// Header for the active thikr in focus reading (category, index, repeats).
  static String thikrSectionLabel({
    required AppLocalizations l10n,
    required String categoryTitle,
    required int index,
    required int total,
    required int remaining,
    required int targetCount,
    required bool isDone,
  }) {
    final position = '${index + 1} / $total';
    final progress = isDone
        ? l10n.fortressCompleted
        : l10n.fortressRemainingCount(remaining);
    return '$categoryTitle. $position. $progress. ×$targetCount';
  }

  /// Empty global search state.
  static String searchEmptyLabel(AppLocalizations l10n, String query) =>
      '${l10n.fortressNoSearchResults}. "$query"';

  /// Empty sidebar filter state.
  static String sidebarEmptyLabel(AppLocalizations l10n, {required bool favorites}) =>
      favorites
          ? '${l10n.fortressEmptyFavoritesTitle}. ${l10n.fortressEmptyFavoritesHint}'
          : '${l10n.fortressEmptySearchTitle}. ${l10n.fortressEmptySearchHint}';

  /// Welcome / recommendation chapter card (title + recurrence + count).
  static String categoryCardLabel(
    AppLocalizations l10n, {
    required String title,
    required String recurrence,
    required int supplicationCount,
  }) =>
      '$title. $recurrence. ${l10n.fortressSupplicationCount(supplicationCount)}';

  /// Chapter list preview row (index, repeats, expand/collapse).
  static String previewRowLabel(
    AppLocalizations l10n, {
    required int oneBasedIndex,
    required bool isExpanded,
    required int targetCount,
  }) =>
      '$oneBasedIndex. ×$targetCount. '
      '${isExpanded ? l10n.collapse : l10n.fortressShowDetails}';
}

/// Drops decorative / redundant nodes from the semantics tree.
class FortressExcludeDecorative extends StatelessWidget {
  /// Creates an exclusion wrapper.
  const FortressExcludeDecorative({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(child: child);
}
