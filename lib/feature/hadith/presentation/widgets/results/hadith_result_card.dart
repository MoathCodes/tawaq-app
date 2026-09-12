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
        final card = _HadithResultCardBody(
          hadith: hadith,
          resultOrdinal: resultOrdinal,
          maxWidth: constraints.maxWidth,
          isSelected: isSelectedValue,
          showMetadataAvailability: showMetadataAvailability,
          hadithMaxLines: hadithMaxLines,
          onPress: onSelectAction,
        );

        List<FItemGroupMixin> menuItems(FPopoverController controller) => [
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
        ];

        final wrapped = FContextMenu(
          menuBuilder: (context, controller, _) => menuItems(controller),
          child: card,
        );

        final moreActionsButton = FPopoverMenu(
          menuBuilder: (context, controller, _) => menuItems(controller),
          builder: (context, controller, _) => FButton.icon(
            variant: .ghost,
            semanticsLabel: l10n.hadithMoreActions,
            onPress: controller.toggle,
            child: const Icon(FLucideIcons.ellipsis),
          ),
        );

        final selectable = Semantics(
          container: true,
          label: rowLabel,
          button: true,
          selected: isSelectedValue,
          onTap: onSelectAction,
          child: wrapped,
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: selectable),
            ?favoriteButton,
            moreActionsButton,
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
  const new({
    required this.hadith,
    required this.resultOrdinal,
    required this.maxWidth,
    required this.isSelected,
    required this.showMetadataAvailability,
    required this.hadithMaxLines,
    required this.onPress,
  });

  final DetailedHadith hadith;
  final int? resultOrdinal;
  final double maxWidth;
  final bool isSelected;
  final bool showMetadataAvailability;
  final int hadithMaxLines;
  final VoidCallback onPress;

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

    final card = HoverCard(
      onPress: onPress,
      backgroundColor: isSelected
          ? colors.secondary.withValues(alpha: 0.28)
          : colors.background,
      borderColor: isSelected
          ? colors.primary
          : colors.border.withValues(alpha: 0.6),
      activeBorderColor: colors.primary,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.sm,
        children: [
          if (resultOrdinal != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.sm,
              children: [
                Expanded(
                  child: Text(
                    l10n.hadithResultIdentity(resultOrdinal!),
                    style: theme.typography.body.sm.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    l10n.hadithSourceCitation(
                      hadith.book,
                      hadith.numberOrPage,
                    ),
                    textAlign: TextAlign.end,
                    softWrap: true,
                    style: theme.typography.body.sm.copyWith(
                      color: colors.mutedForeground,
                    ),
                  ),
                ),
              ],
            ),
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
          // Keep the source judgment independent from secondary affordances;
          // a long judgment must remain fully readable and wrap naturally.
          HadithDecorExcludeSemantics(
            child: HadithHukmBadge(hukm: hadith.hukm),
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
          if (showMetadataAvailability)
            HadithDecorExcludeSemantics(
              child: HadithDetailsAvailabilityRow(hadith: hadith),
            ),
        ],
      ),
    );

    if (!isSelected) return card;

    return Stack(
      children: [
        card,
        PositionedDirectional(
          start: 0,
          top: 8,
          bottom: 8,
          child: Container(
            width: 3,
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: theme.radii.sm,
            ),
          ),
        ),
      ],
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

/// Badge showing the hadith grading (hukm).
class HadithHukmBadge extends StatelessWidget {
  /// Creates a [HadithHukmBadge].
  const new({required this.hukm, super.key});

  /// The grading text.
  final String hukm;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final judgment = hukm.trim();

    if (judgment.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          constraints: BoxConstraints(maxWidth: constraints.maxWidth),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: theme.radii.md,
            border: Border.all(color: colors.border),
          ),
          child: Text(
            hukm,
            style: theme.typography.body.sm.copyWith(
              color: colors.foreground,
              fontWeight: FontWeight.w600,
            ),
            softWrap: true,
          ),
        );
      },
    );
  }
}
