import 'dart:async';

import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/custom_cards.dart';
import 'package:tawaq/core/widgets/mouse_click.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_identity.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/hadith_accessibility.dart';
import 'package:tawaq/theme/theme.dart';

class HadithResultCard extends ConsumerWidget {
  const HadithResultCard({
    required this.hadith,
    super.key,
    this.isFavorite,
    this.isSelected,
    this.onToggleFavorite,
    this.onSelect,
    this.showMetadataAvailability = true,
    this.showFavoriteAction = true,
    this.hadithMaxLines = 4,
  });

  /// Compact card for nested detail panes (similar/alternate hadith).
  HadithResultCard.embedded({
    required DetailedHadith hadith,
    required VoidCallback onSelect,
    Key? key,
  }) : this(
         hadith: hadith,
         onSelect: onSelect,
         isFavorite: false,
         isSelected: false,
         showMetadataAvailability: false,
         showFavoriteAction: false,
         hadithMaxLines: 6,
         key: key,
       );

  final DetailedHadith hadith;
  final bool? isFavorite;
  final bool? isSelected;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onSelect;
  final bool showMetadataAvailability;
  final bool showFavoriteAction;
  final int hadithMaxLines;

  int _effectiveHadithMaxLines(double maxWidth, FBreakpoints breakpoints) {
    if (maxWidth < breakpoints.sm) {
      return hadithMaxLines.clamp(2, 3);
    }
    if (maxWidth < breakpoints.md) {
      return hadithMaxLines.clamp(3, 4);
    }
    return hadithMaxLines;
  }

  TextAlign _hadithTextAlign(double maxWidth, FBreakpoints breakpoints) {
    return maxWidth < breakpoints.sm ? TextAlign.start : TextAlign.justify;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final colors = theme.colors;
    final l10n = context.l10n;
    final hadithKey = hadithStableKey(hadith);

    final bool isFavoriteValue = isFavorite ??
        ref.watch(
          hadithSearchControllerProvider.select(
            (value) =>
                (value.asData?.value.favoriteKeys ?? const <String>[])
                    .contains(hadithKey),
          ),
        );
    final bool isSelectedValue = isSelected ??
        ref.watch(
          hadithSelectorProvider.select(
            (value) {
              final selected = value.asData?.value;
              return selected != null &&
                  hadithStableKey(selected) == hadithKey;
            },
          ),
        );

    final VoidCallback onSelectAction = onSelect ??
        () {
          unawaited(
            ref
                .read(hadithScreenControllerProvider.notifier)
                .selectHadith(hadith),
          );
        };

    final onToggleFavoriteAction = onToggleFavorite ??
        (showFavoriteAction
            ? () {
                unawaited(
                  ref
                      .read(hadithSearchControllerProvider.notifier)
                      .toggleFavorite(hadith),
                );
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

    Widget buildCard(double maxWidth) {
      final breakpoints = context.theme.breakpoints;
      final effectiveMaxLines = _effectiveHadithMaxLines(maxWidth, breakpoints);
      final textAlign = _hadithTextAlign(maxWidth, breakpoints);

      return HoverCard(
        backgroundColor: colors.background,
        borderColor: isSelectedValue
            ? colors.primary
            : colors.border.withValues(alpha: 0.6),
        activeBorderColor: colors.primary,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.sm,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.secondary.withValues(alpha: 0.6),
                borderRadius: theme.radii.md,
                border: Border.all(
                  color: colors.border.withValues(alpha: 0.5),
                ),
              ),
              child: ExcludeSemantics(
                child: Text(
                  hadith.hadith,
                  maxLines: effectiveMaxLines,
                  overflow: TextOverflow.ellipsis,
                  textAlign: textAlign,
                  style: theme.typography.lg.copyWith(height: 1.9),
                ),
              ),
            ),
            ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  HadithMetaLine(
                    label: l10n.hadithNarrator,
                    value: hadith.rawi,
                  ),
                  HadithMetaLine(
                    label: l10n.hadithMuhaddith,
                    value: hadith.mohdith,
                  ),
                  HadithMetaLine(
                    label: l10n.hadithSource,
                    value: l10n.hadithSourceCitation(
                      hadith.book,
                      hadith.numberOrPage,
                    ),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                HadithDecorExcludeSemantics(
                  child: HadithHukmBadge(hukm: hadith.hukm),
                ),
                if (showMetadataAvailability)
                  HadithDecorExcludeSemantics(
                    child: HadithDetailsAvailabilityRow(hadith: hadith),
                  ),
              ],
            ),
          ],
        ),
      );
    }

    final rowLabel = hadithResultRowSemanticsLabel(
      hadith,
      l10n,
      isFavorite: isFavoriteValue,
      isSelected: isSelectedValue,
    );

    Widget buildRow(Widget card) {
      return MouseClick(
        onClick: onSelectAction,
        semanticsLabel: rowLabel,
        child: card,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final card = buildRow(buildCard(constraints.maxWidth));
        final favorite = favoriteButton;
        if (favorite == null) return card;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: card),
            favorite,
          ],
        );
      },
    );
  }
}

class HadithMetaLine extends StatelessWidget {
  const HadithMetaLine({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = context.l10n;

    return RichText(
      text: TextSpan(
        style: theme.typography.sm.copyWith(
          color: theme.colors.secondaryForeground,
        ),
        children: [
          TextSpan(
            text: l10n.hadithFieldLabel(label),
            style: theme.typography.sm.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}

class HadithDetailsAvailabilityRow extends StatelessWidget {
  const HadithDetailsAvailabilityRow({required this.hadith, super.key});

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
        HadithInfoMiniChip(
          icon: FLucideIcons.link,
          text: l10n.hadithTakhrij,
        ),
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
  const HadithInfoMiniChip({required this.icon, required this.text, super.key});

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
            style: theme.typography.xs.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
        ],
      ),
      ),
    );
  }
}

/// Badge showing the hadith grading (hukm).
class HadithHukmBadge extends StatelessWidget {
  /// Creates a [HadithHukmBadge].
  const HadithHukmBadge({required this.hukm, super.key});

  /// The grading text.
  final String hukm;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final lower = hukm.toLowerCase();

    final color = switch (lower) {
      _ when lower.contains('صحيح') => colors.primary,
      _ when lower.contains('حسن') => Color.lerp(
        colors.primary,
        colors.mutedForeground,
        0.35,
      )!,
      _ => Color.lerp(colors.primary, colors.mutedForeground, 0.75)!,
    };

    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: theme.radii.md,
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        hukm,
        style: theme.typography.sm.copyWith(color: color),
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      ),
    );
  }
}
