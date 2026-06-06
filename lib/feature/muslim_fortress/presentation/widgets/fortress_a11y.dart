import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/theme.dart';

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

  /// Toggle for exposing long dhikr / Quranic body text to screen readers.
  static String readDhikrToggleLabel(
    AppLocalizations l10n, {
    required bool expanded,
  }) =>
      expanded ? l10n.fortressHideDetails : l10n.fortressShowDetails;

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

/// Focus-reading thikr block: structured header, optional full-text exposure.
class FortressAccessibleThikrPanel extends HookWidget {
  /// Creates an accessible thikr panel.
  const FortressAccessibleThikrPanel({
    required this.categoryTitle,
    required this.index,
    required this.total,
    required this.remaining,
    required this.targetCount,
    required this.isDone,
    required this.body,
    super.key,
  });

  final String categoryTitle;
  final int index;
  final int total;
  final int remaining;
  final int targetCount;
  final bool isDone;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final contentVisible = useState(false);

    final headerLabel = FortressA11y.thikrSectionLabel(
      l10n: l10n,
      categoryTitle: categoryTitle,
      index: index,
      total: total,
      remaining: remaining,
      targetCount: targetCount,
      isDone: isDone,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          container: true,
          label: headerLabel,
          child: const SizedBox(width: double.infinity, height: 0),
        ),
        Center(
          child: FButton(
            variant: .outline,
            onPress: () => contentVisible.value = !contentVisible.value,
            prefix: Icon(
              contentVisible.value
                  ? FLucideIcons.eyeOff
                  : FLucideIcons.eye,
              size: 18,
            ),
            child: Text(
              FortressA11y.readDhikrToggleLabel(
                l10n,
                expanded: contentVisible.value,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (contentVisible.value)
          body
        else
          FortressExcludeDecorative(child: body),
      ],
    );
  }
}

/// Explicit button semantics for fortress nav actions (prev / next / study).
class FortressLabeledNavButton extends StatelessWidget {
  /// Creates a labeled nav button.
  const FortressLabeledNavButton({
    required this.label,
    required this.enabled,
    required this.onPress,
    required this.child,
    this.prefix,
    super.key,
  });

  final String label;
  final bool enabled;
  final VoidCallback? onPress;
  final Widget child;
  final Widget? prefix;

  @override
  Widget build(BuildContext context) => NonSelectable(
    child: FButton(
      variant: .outline,
      semanticsLabel: label,
      onPress: enabled ? onPress : null,
      prefix: prefix,
      child: child,
    ),
  );
}
