import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter/material.dart';
import 'package:tawaq/l10n/app_localizations.dart';

/// Maximum characters included in narrator snippets for list semantics.
const int kHadithSemanticsSnippetMaxLength = 96;

/// Truncates [text] for screen-reader labels without full hadith bodies.
String hadithSemanticsSnippet(
  String text, {
  int maxLength = kHadithSemanticsSnippetMaxLength,
}) {
  final trimmed = text.trim();
  if (trimmed.length <= maxLength) return trimmed;
  return '${trimmed.substring(0, maxLength).trim()}…';
}

/// Compact list-row label: source, narrator snippet, grade, bookmark/selection.
String hadithResultRowSemanticsLabel(
  DetailedHadith hadith,
  AppLocalizations l10n, {
  required bool isFavorite,
  required bool isSelected,
}) {
  final narrator = '${l10n.hadithFieldLabel(l10n.hadithNarrator)}'
      '${hadithSemanticsSnippet(hadith.rawi)}';
  final parts = <String>[
    l10n.hadithSourceCitation(hadith.book, hadith.numberOrPage),
    narrator,
    hadith.hukm,
  ];
  if (isFavorite) {
    parts.add(l10n.bookmarks);
  }
  if (isSelected) {
    parts.add(l10n.hadithDetailsTab);
  }
  return parts.join('. ');
}

/// Label for an active filter chip that removes one constraint.
String hadithFilterChipSemanticsLabel(
  String filterLabel,
  AppLocalizations l10n,
) {
  return '${l10n.hadithActiveFilters}: $filterLabel. '
      '${l10n.hadithClearAllFilters}';
}

/// Label for a recent-search shortcut chip.
String hadithRecentSearchChipSemanticsLabel(
  String query,
  AppLocalizations l10n,
) {
  return '${l10n.hadithRecentSearches}: $query';
}

/// Label for removing one recent-search entry.
String hadithRemoveRecentSearchSemanticsLabel(
  String query,
  AppLocalizations l10n,
) {
  return '${l10n.hadithRecentSearches}: $query. ${l10n.hadithClearAllRecents}';
}

/// Semantic label for the bookmark toggle on a result row.
String hadithFavoriteToggleSemanticsLabel({
  required bool isFavorite,
  required AppLocalizations l10n,
}) {
  if (isFavorite) {
    return '${l10n.fortressFavorites}. ${l10n.editsSavedTitle}';
  }
  return l10n.fortressFavorites;
}

/// Announced while search results or bookmarks are loading.
String hadithSearchLoadingSemanticsLabel(AppLocalizations l10n) => l10n.loading;

/// Announced for the icon-only control that closes the filters popover.
String hadithCloseFiltersSemanticsLabel(AppLocalizations l10n) =>
    '${l10n.cancel}. ${l10n.hadithFilterTab}';

/// Hides decorative visuals from the semantics tree.
class HadithDecorExcludeSemantics extends StatelessWidget {
  /// Creates a decorator excluder.
  const HadithDecorExcludeSemantics({required this.child, super.key});

  /// The subtree to hide from assistive technologies.
  final Widget child;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(child: child);
}

/// One merged semantics node for a hadith result row (metadata only).
class HadithResultRowSemantics extends StatelessWidget {
  /// Creates row-level semantics for a result card.
  const HadithResultRowSemantics({
    required this.label,
    required this.child,
    this.button = false,
    super.key,
  });

  /// Screen-reader label for the row.
  final String label;

  /// Visual row content; inner text should stay under [ExcludeSemantics].
  final Widget child;

  /// Whether assistive tech should treat the row as a button.
  final bool button;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: button,
      excludeSemantics: true,
      child: child,
    );
  }
}
