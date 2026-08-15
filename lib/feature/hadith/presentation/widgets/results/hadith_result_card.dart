import 'dart:async';

import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/context_menu_action.dart';
import 'package:tawaq/core/widgets/custom_cards.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_identity.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/hadith_accessibility.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/hadith_meta_field.dart';
import 'package:tawaq/l10n/app_localizations.dart';
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
  factory HadithResultCard.embedded({
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
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final card = _HadithResultCardBody(
          hadith: hadith,
          maxWidth: constraints.maxWidth,
          isSelected: isSelectedValue,
          showMetadataAvailability: showMetadataAvailability,
          hadithMaxLines: hadithMaxLines,
          onPress: onSelectAction,
          semanticsLabel: rowLabel,
        );

        final wrapped = FContextMenu(
          menuBuilder: (context, controller, _) => [
            FItemGroup(
              children: [
                contextMenuAction(
                  controller: controller,
                  icon: FLucideIcons.bookOpenText,
                  label: l10n.menuOpen,
                  onPressed: onSelectAction,
                ),
                contextMenuAction(
                  controller: controller,
                  icon: FLucideIcons.copy,
                  label: l10n.menuCopyText,
                  onPressed: () => _copyHadith(context, l10n),
                ),
                if (showFavoriteAction && onToggleFavoriteAction != null)
                  contextMenuAction(
                    controller: controller,
                    icon: isFavoriteValue
                        ? FLucideIcons.bookmarkX
                        : FLucideIcons.bookmark,
                    label: isFavoriteValue
                        ? l10n.menuRemoveBookmark
                        : l10n.menuAddBookmark,
                    onPressed: onToggleFavoriteAction,
                  ),
              ],
            ),
          ],
          child: card,
        );

        if (favoriteButton == null) return wrapped;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: wrapped),
            favoriteButton,
          ],
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
    } on Object catch (error) {
      if (!context.mounted) return;
      showFToast(
        context: context,
        title: Text('${l10n.menuAddBookmark}: $error'),
      );
    }
  }

  void _copyHadith(BuildContext context, AppLocalizations l10n) {
    final buffer = StringBuffer()
      ..writeln(hadith.hadith.trim())
      ..writeln()
      ..writeln('${l10n.hadithNarrator}: ${hadith.rawi}')
      ..writeln('${l10n.hadithMuhaddith}: ${hadith.mohdith}')
      ..write(
        '${l10n.hadithSource}: '
        '${l10n.hadithSourceCitation(hadith.book, hadith.numberOrPage)}',
      );
    unawaited(Clipboard.setData(ClipboardData(text: buffer.toString())));
    showFToast(context: context, title: Text(l10n.hadithCopied));
  }
}

class _HadithResultCardBody extends StatelessWidget {
  const _HadithResultCardBody({
    required this.hadith,
    required this.maxWidth,
    required this.isSelected,
    required this.showMetadataAvailability,
    required this.hadithMaxLines,
    required this.onPress,
    required this.semanticsLabel,
  });

  final DetailedHadith hadith;
  final double maxWidth;
  final bool isSelected;
  final bool showMetadataAvailability;
  final int hadithMaxLines;
  final VoidCallback onPress;
  final String semanticsLabel;

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

    return HoverCard(
      onPress: onPress,
      semanticsLabel: semanticsLabel,
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
                maxLines: effectiveMaxLines,
                overflow: TextOverflow.ellipsis,
                textAlign: textAlign,
                style: theme.typography.body.lg.copyWith(height: 1.9),
              ),
            ),
          ),
          ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
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

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          constraints: BoxConstraints(maxWidth: constraints.maxWidth),
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
            style: theme.typography.body.sm.copyWith(color: color),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        );
      },
    );
  }
}
