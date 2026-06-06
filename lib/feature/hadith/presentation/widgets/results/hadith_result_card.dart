import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/custom_cards.dart';
import 'package:tawaq/core/widgets/mouse_click.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/hadith_accessibility.dart';
import 'package:tawaq/theme/theme.dart';

class HadithResultCard extends StatelessWidget {
  const HadithResultCard({required this.hadith, required this.isFavorite, required this.isSelected, super.key,
    this.onToggleFavorite,
    this.onSelect,
    this.showMetadataAvailability = true,
    this.showFavoriteAction = true,
    this.hadithMaxLines = 4,
  });

  final DetailedHadith hadith;
  final bool isFavorite;
  final bool isSelected;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onSelect;
  final bool showMetadataAvailability;
  final bool showFavoriteAction;
  final int hadithMaxLines;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final l10n = context.l10n;

    final favoriteButton = showFavoriteAction && onToggleFavorite != null
        ? FButton.icon(
            variant: FButtonVariant.ghost,
            semanticsLabel: hadithFavoriteToggleSemanticsLabel(
              isFavorite: isFavorite,
              l10n: l10n,
            ),
            onPress: onToggleFavorite,
            child: HadithDecorExcludeSemantics(
              child: Icon(
                isFavorite ? FLucideIcons.bookmarkCheck : FLucideIcons.bookmark,
                color: isFavorite ? colors.primary : colors.mutedForeground,
              ),
            ),
          )
        : null;

    final card = HoverCard(
      enableHoverEffect: onSelect != null,
      backgroundColor: colors.background,
      borderColor: isSelected
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
                maxLines: hadithMaxLines,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.justify,
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
          Row(
            children: [
              HadithDecorExcludeSemantics(child: HadithHukmBadge(hukm: hadith.hukm)),
              if (showMetadataAvailability) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: HadithDecorExcludeSemantics(
                    child: HadithDetailsAvailabilityRow(hadith: hadith),
                  ),
                ),
              ] else if (favoriteButton != null)
                const Spacer(),
            ],
          ),
        ],
      ),
    );

    final onCardSelect = onSelect;
    final rowBody = onCardSelect == null
        ? card
        : MouseClick(onClick: onCardSelect, child: card);

    final row = HadithResultRowSemantics(
      label: hadithResultRowSemanticsLabel(
        hadith,
        l10n,
        isFavorite: isFavorite,
        isSelected: isSelected,
      ),
      button: onCardSelect != null,
      child: rowBody,
    );

    if (favoriteButton == null) {
      return row;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: row),
        favoriteButton,
      ],
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
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: AppSpacing.xs,
        children: chips,
      ),
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

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Container(
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
          maxLines: 1,
        ),
      ),
    );
  }
}
