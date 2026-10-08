import 'package:tawaq/feature/hadith/domain/models/hadith_display_text.dart';

import 'dart:async';

import 'package:flutter/services.dart';

import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/mouse_click.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_identity.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_highlight.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_judgment.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/hadith_accessibility.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/hadith_meta_field.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/results/hadith_source_ruling.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/share/hadith_share_actions.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/theme.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/results/hadith_card_layout.dart';

class HadithResultCard extends ConsumerWidget {
  const new({
    required this.hadith,
    super.key,
    this.resultOrdinal,
    this.isFavorite,
    this.isSelected,
    this.onToggleFavorite,
    this.onSelect,
    this.showMetadataAvailability = true,
    this.showFavoriteAction = true,
    this.hadithMaxLines = 4,
    this.query = '',
    this.focusNode,
  });

  /// Compact card for nested detail panes (similar/alternate hadith).
  factory embedded({
    required DetailedHadith hadith,
    required VoidCallback onSelect,
    Key? key,
  }) {
    return HadithResultCard(
      key: key,
      hadith: hadith,
      onSelect: onSelect,
      showMetadataAvailability: false,
      showFavoriteAction: false,
      hadithMaxLines: 6,
    );
  }

  final FocusNode? focusNode;
  final String query;
  final DetailedHadith hadith;

  /// Honest page-local position when the surrounding list has established it.
  final int? resultOrdinal;
  final bool? isFavorite;
  final bool? isSelected;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onSelect;
  final bool showMetadataAvailability;
  final bool showFavoriteAction;
  final int hadithMaxLines;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final l10n = context.l10n;
    final hadithKey = hadithStableKey(hadith);

    // Select membership for this key only — avoids rebuilding every card on
    // unrelated favorite list identity changes when this entry is unchanged.
    final favoriteFromProvider = ref.watch(
      hadithFavoritesProvider.select((async) {
        final list = async.asData?.value;
        if (list == null) return false;
        return list.any((entry) => hadithStableKey(entry) == hadithKey);
      }),
    );
    final isFavoriteValue = isFavorite ?? favoriteFromProvider;
    final selectedFromProvider = ref.watch(
      hadithSessionControllerProvider.select((session) {
        return session.selectedHadithKey == hadithKey;
      }),
    );
    final isSelectedValue = isSelected ?? selectedFromProvider;

    final onSelectAction =
        onSelect ??
        () {
          unawaited(
            ref
                .read(hadithSessionControllerProvider.notifier)
                .selectHadith(hadith),
          );
        };

    final onToggleFavoriteAction =
        onToggleFavorite ??
        (showFavoriteAction
            ? () {
                unawaited(_toggleFavorite(context, ref, l10n));
              }
            : null);

    final favoriteButton = showFavoriteAction && onToggleFavoriteAction != null
        ? FButton.icon(
            variant: FButtonVariant.ghost,
            semanticsLabel: hadithFavoriteToggleSemanticsLabel(
              isFavorite: isFavoriteValue,
              l10n: l10n,
            ),
            onPress: onToggleFavoriteAction,
            child: HadithDecorExcludeSemantics(
              child: Icon(
                isFavoriteValue
                    ? FLucideIcons.bookmarkCheck
                    : FLucideIcons.bookmark,
                color: isFavoriteValue
                    ? colors.primary
                    : colors.mutedForeground,
              ),
            ),
          )
        : null;

    final rowLabel = hadithResultRowSemanticsLabel(
      hadith,
      l10n,
      isFavorite: isFavoriteValue,
      isSelected: isSelectedValue,
      resultOrdinal: resultOrdinal,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return _HadithResultCardBody(
          hadith: hadith,
          query: query,
          focusNode: focusNode,
          maxWidth: constraints.maxWidth,
          isSelected: isSelectedValue,
          showMetadataAvailability: showMetadataAvailability,
          hadithMaxLines: hadithMaxLines,
          onPress: onSelectAction,
          semanticsLabel: rowLabel,
          favoriteButton: favoriteButton,
        );
      },
    );
  }

  Future<void> _toggleFavorite(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    try {
      await ref
          .read(hadithSessionControllerProvider.notifier)
          .toggleFavorite(hadith);
    } on Object {
      if (!context.mounted) return;
      showFToast(context: context, title: Text(l10n.hadithBookmarkFailed));
    }
  }
}

class _HadithResultCardBody extends HookWidget {
  const new({
    required this.hadith,
    required this.maxWidth,
    required this.query,
    this.focusNode,
    required this.isSelected,
    required this.showMetadataAvailability,
    required this.hadithMaxLines,
    required this.onPress,
    required this.semanticsLabel,
    this.favoriteButton,
  });

  final DetailedHadith hadith;
  final FocusNode? focusNode;
  final String query;
  final double maxWidth;
  final bool isSelected;
  final bool showMetadataAvailability;
  final int hadithMaxLines;
  final VoidCallback onPress;
  final String semanticsLabel;
  final Widget? favoriteButton;

  int _effectiveHadithMaxLines(FBreakpoints breakpoints) {
    if (maxWidth < breakpoints.sm) {
      return hadithMaxLines.clamp(2, 3);
    }
    if (maxWidth < breakpoints.md) {
      return hadithMaxLines.clamp(3, 4);
    }
    return hadithMaxLines;
  }

  TextAlign _hadithTextAlign(FBreakpoints breakpoints) {
    return TextAlign.start;
  }

  @override
  Widget build(BuildContext context) {
    final fallbackFocus = useFocusNode();
    final node = focusNode ?? fallbackFocus;
    useListenable(node);
    final theme = context.theme;
    final colors = theme.colors;
    final l10n = context.l10n;
    final breakpoints = theme.breakpoints;
    final effectiveMaxLines = _effectiveHadithMaxLines(breakpoints);
    final textAlign = _hadithTextAlign(breakpoints);

    final hovered = useState(false);

    return HadithCardFrame(
      surface: isSelected
          ? colors.secondary
          : hovered.value
          ? colors.secondary.withValues(alpha: .35)
          : colors.card,
      border: isSelected
          ? colors.primary
          : hovered.value
          ? colors.mutedForeground
          : colors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            container: true,
            label: semanticsLabel,
            button: true,
            selected: isSelected,
            onTap: onPress,
            child: Focus(
              focusNode: node,
              onKeyEvent: (_, event) {
                if (event is KeyDownEvent &&
                    (event.logicalKey == LogicalKeyboardKey.enter ||
                        event.logicalKey == LogicalKeyboardKey.space)) {
                  onPress();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: FFocusedOutline(
                focused: node.hasFocus,
                child: ExcludeFocus(
                  child: MouseClick(
                    onClick: onPress,
                    onHoverChange: (value) => hovered.value = value,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: AppSpacing.sm,
                      children: [
                        ExcludeSemantics(
                          child: Text.rich(
                            _highlight(
                              hadithDisplayText(hadith),
                              query,
                              colors,
                            ),
                            maxLines: effectiveMaxLines,
                            overflow: TextOverflow.ellipsis,
                            textAlign: textAlign,
                            textDirection: TextDirection.rtl,
                            style: theme.typography.body.lg.copyWith(
                              height: 1.9,
                            ),
                          ),
                        ),
                        HadithDecorExcludeSemantics(
                          child: HadithSourceRuling(
                            hukm: hadithRulingText(hadith),
                            tone: hadith.verdictTone,
                            fitContent: true,
                          ),
                        ),
                        ExcludeSemantics(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final fields = [
                                (l10n.hadithNarrator, hadith.rawi),
                                (l10n.hadithMuhaddith, hadith.mohdith),
                                (
                                  l10n.hadithSource,
                                  l10n.hadithSourceCitation(
                                    hadith.book,
                                    hadith.numberOrPage,
                                  ),
                                ),
                              ];
                              return HadithAttributionLayout(
                                compact: [
                                  for (final field in fields)
                                    HadithMetaField(
                                      label: field.$1,
                                      value: field.$2,
                                      layout: HadithMetaFieldLayout.inline,
                                    ),
                                ],
                                wide: [
                                  for (final field in fields)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      spacing: 4,
                                      children: [
                                        Text(
                                          field.$1,
                                          style: theme.typography.body.sm
                                              .copyWith(
                                                color: colors.mutedForeground,
                                              ),
                                        ),
                                        Text(
                                          field.$2,
                                          style: theme.typography.body.sm,
                                        ),
                                      ],
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                        if (showMetadataAvailability)
                          HadithDecorExcludeSemantics(
                            child: HadithDetailsAvailabilityRow(hadith: hadith),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          HadithShareActions(
            hadith: hadith,
            favoriteButton: favoriteButton,
            trailingAction: hadith.categories.isEmpty
                ? null
                : Consumer(
                    builder: (context, ref, _) => FPopoverMenu(
                      menu: [
                        FItemGroup(
                          children: [
                            for (final category in hadith.categories)
                              FItem(
                                title: Text(category.name),
                                onPress: () => ref
                                    .read(
                                      hadithSessionControllerProvider.notifier,
                                    )
                                    .openCategory(
                                      ThematicCategory(
                                        id: category.id,
                                        name: category.name,
                                        uri: Uri.https(
                                          'dorar.net',
                                          '/hadith-category/cat/${category.id}',
                                        ),
                                      ),
                                    ),
                              ),
                          ],
                        ),
                      ],
                      builder: (_, popover, _) => FButton(
                        variant: .ghost,
                        size: .sm,
                        mainAxisSize: MainAxisSize.min,
                        onPress: popover.toggle,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(l10n.hadithTopics),
                            const SizedBox(width: 4),
                            const Icon(FLucideIcons.chevronDown, size: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class HadithDetailsAvailabilityRow extends StatelessWidget {
  const new({required this.hadith, super.key});

  final DetailedHadith hadith;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasTakhrij = (hadith.takhrij ?? '').trim().isNotEmpty;

    final chips = <Widget>[
      if (hadith.explanationReference != null || hadith.hasSharhMetadata)
        HadithInfoMiniChip(
          icon: FLucideIcons.bookOpenText,
          text:
              hadith.explanationReference?.relationship ==
                  ContentRelationship.similar
              ? l10n.hadithSimilarExplanation
              : l10n.hadithSharh,
        ),
      if (hasTakhrij)
        HadithInfoMiniChip(icon: FLucideIcons.link, text: l10n.hadithTakhrij),
      if (hadith.asbabAvailability == Availability.advertised)
        HadithInfoMiniChip(
          icon: FLucideIcons.messageSquareText,
          text: l10n.hadithAsbab,
        ),
      if (hadith.hasUsulHadith ||
          hadith.usulAvailability == Availability.advertised)
        HadithInfoMiniChip(
          icon: FLucideIcons.sparkles,
          text: l10n.hadithUsulHadith,
        ),
      if (hadith.hasSimilarHadith)
        HadithInfoMiniChip(
          icon: FLucideIcons.eye,
          text: l10n.hadithSimilarHadith,
        ),
      if (hadith.hasAlternateHadithSahih)
        HadithInfoMiniChip(
          icon: FLucideIcons.arrowRightFromLine,
          text: l10n.hadithAlternateHadithSahih,
        ),
    ];

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: chips,
    );
  }
}

class HadithInfoMiniChip extends StatelessWidget {
  const new({required this.icon, required this.text, super.key});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return HadithDecorExcludeSemantics(
      child: FBadge(
        variant: .secondary,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.xs,
          children: [
            Icon(icon, size: 12, color: theme.colors.mutedForeground),
            Text(
              text,
              style: theme.typography.body.xs.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

TextSpan _highlight(String source, String query, FColors colors) {
  final ranges = hadithQueryRanges(source, query);
  if (ranges.isEmpty) return TextSpan(text: source);
  var offset = 0;
  final spans = <TextSpan>[];
  for (final range in ranges) {
    if (range.start > offset)
      spans.add(TextSpan(text: source.substring(offset, range.start)));
    spans.add(
      TextSpan(
        text: source.substring(range.start, range.end),
        style: TextStyle(
          backgroundColor: colors.secondary,
          color: colors.foreground,
        ),
      ),
    );
    offset = range.end;
  }
  if (offset < source.length)
    spans.add(TextSpan(text: source.substring(offset)));
  return TextSpan(children: spans);
}
