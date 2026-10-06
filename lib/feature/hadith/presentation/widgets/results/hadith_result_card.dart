import 'dart:async';

import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/mouse_click.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_identity.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_judgment.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/hadith_accessibility.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/hadith_meta_field.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/results/hadith_hukm_badge.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/share/hadith_share_actions.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/theme.dart';

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
    required this.isSelected,
    required this.showMetadataAvailability,
    required this.hadithMaxLines,
    required this.onPress,
    required this.semanticsLabel,
    this.favoriteButton,
  });

  final DetailedHadith hadith;
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
    return maxWidth < breakpoints.sm ? TextAlign.start : TextAlign.justify;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final l10n = context.l10n;
    final breakpoints = theme.breakpoints;
    final effectiveMaxLines = _effectiveHadithMaxLines(breakpoints);
    final textAlign = _hadithTextAlign(breakpoints);

    final hovered = useState(false);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isSelected
            ? colors.secondary
            : hovered.value
            ? colors.secondary.withValues(alpha: 0.35)
            : colors.background,
        borderRadius: theme.radii.xl,
        border: Border.all(
          color: isSelected
              ? colors.primary
              : hovered.value
              ? colors.mutedForeground
              : colors.border.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            container: true,
            label: semanticsLabel,
            button: true,
            selected: isSelected,
            onTap: onPress,
            child: MouseClick(
              onClick: onPress,
              onHoverChange: (value) => hovered.value = value,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.sm,
                children: [
                  ExcludeSemantics(
                    child: Text(
                      hadith.hadith,
                      maxLines: effectiveMaxLines,
                      overflow: TextOverflow.ellipsis,
                      textAlign: textAlign,
                      style: theme.typography.body.lg.copyWith(height: 1.9),
                    ),
                  ),
                  HadithDecorExcludeSemantics(
                    child: HadithHukmBadge(
                      hukm: hadith.hukm,
                      tone: hadithSourceJudgmentTone(hadith),
                    ),
                  ),
                  ExcludeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: AppSpacing.xs,
                      children: [
                        HadithMetaField(
                          label: l10n.hadithNarrator,
                          value: hadith.rawi,
                          layout: HadithMetaFieldLayout.inline,
                        ),
                        HadithMetaField(
                          label: l10n.hadithMuhaddith,
                          value: hadith.mohdith,
                          layout: HadithMetaFieldLayout.inline,
                        ),
                        HadithMetaField(
                          label: l10n.hadithSource,
                          value: l10n.hadithSourceCitation(
                            hadith.book,
                            hadith.numberOrPage,
                          ),
                          layout: HadithMetaFieldLayout.inline,
                        ),
                      ],
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
          const SizedBox(height: AppSpacing.sm),
          HadithShareActions(hadith: hadith, favoriteButton: favoriteButton),
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
      if (hadith.hasSharhMetadata)
        HadithInfoMiniChip(
          icon: FLucideIcons.bookOpenText,
          text: l10n.hadithSharh,
        ),
      if (hasTakhrij)
        HadithInfoMiniChip(icon: FLucideIcons.link, text: l10n.hadithTakhrij),
      if (hadith.hasUsulHadith)
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
