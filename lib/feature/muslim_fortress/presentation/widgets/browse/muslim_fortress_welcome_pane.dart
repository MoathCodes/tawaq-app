import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_category.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_locale_extensions.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/fortress_a11y.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/theme.dart';

/// Home pane when no chapter is selected (time-based picks + bookmarks).
class MuslimFortressWelcomePane extends StatelessWidget {
  /// Creates a welcome pane.
  const MuslimFortressWelcomePane({
    required this.recommendedCategories,
    required this.bookmarkCategories,
    required this.onSelectCategory,
    required this.onViewAll,
    super.key,
  });

  /// Time- or prayer-based chapter suggestions.
  final List<FortressCategory> recommendedCategories;

  /// User bookmarked chapters (by title string).
  final List<FortressCategory> bookmarkCategories;

  /// Opens the selected chapter in the main pane.
  final ValueChanged<FortressCategory> onSelectCategory;

  /// Switches the sidebar to the favorites tab.
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final favoritesPreview = bookmarkCategories.take(4).toList();
    final favoritesOverflow =
        bookmarkCategories.length - favoritesPreview.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _WelcomeHeader(),
          const SizedBox(height: AppSpacing.xxl),
          FTileGroup(
            label: Text(l10n.fortressRecommendedNow),
            description: recommendedCategories.isEmpty
                ? Text(
                    l10n.fortressNoRecommendations,
                    style: context.theme.typography.sm.copyWith(
                      color: context.theme.colors.mutedForeground,
                    ),
                  )
                : null,
            children: _fortressCategoryTiles(
              context,
              categories: recommendedCategories,
              onSelectCategory: onSelectCategory,
              prefixForIndex: (index) => index == 0
                  ? FLucideIcons.sparkles
                  : FLucideIcons.bookOpenText,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FTileGroup(
            label: Text(l10n.fortressFavorites),
            description: favoritesPreview.isEmpty
                ? Text(
                    l10n.fortressNoFavoriteChapters,
                    style: context.theme.typography.sm.copyWith(
                      color: context.theme.colors.mutedForeground,
                    ),
                  )
                : null,
            children: _fortressCategoryTiles(
              context,
              categories: favoritesPreview,
              onSelectCategory: onSelectCategory,
              prefixForIndex: (_) => FLucideIcons.bookmark,
            ),
          ),
          if (favoritesOverflow > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FButton(
                variant: .ghost,
                onPress: onViewAll,
                child: Text(
                  l10n.fortressMoreFavoriteChapters(favoritesOverflow),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader();

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final l10n = context.l10n;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.12),
            borderRadius: theme.radii.md,
          ),
          child: Icon(
            FLucideIcons.shieldHalf,
            color: colors.primary,
            size: theme.typography.xl2.fontSize,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.fortressWelcomeTitle,
                style: theme.typography.xl2.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.fortressWelcomeSubtitle,
                style: theme.typography.md.copyWith(
                  color: colors.mutedForeground,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

List<FTileMixin> _fortressCategoryTiles(
  BuildContext context, {
  required List<FortressCategory> categories,
  required ValueChanged<FortressCategory> onSelectCategory,
  required IconData Function(int index) prefixForIndex,
}) {
  final l10n = context.l10n;
  final theme = context.theme;

  return [
    for (var i = 0; i < categories.length; i++)
      FTileMixin.tile(
        prefix: Icon(
          prefixForIndex(i),
          size: theme.typography.md.fontSize,
          color: theme.colors.primary,
        ),
        title: Text(
          categories[i].title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _categoryMeta(categories[i], l10n),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        suffix: Icon(
          FLucideIcons.chevronRight,
          size: theme.typography.sm.fontSize,
          color: theme.colors.mutedForeground,
        ),
        semanticsLabel: FortressA11y.categoryCardLabel(
          l10n,
          title: categories[i].title,
          recurrence: fortressRecurrenceLabel(categories[i].recurrence, l10n),
          supplicationCount: categories[i].supplicationCount,
        ),
        onPress: () => onSelectCategory(categories[i]),
      ),
  ];
}

String _categoryMeta(FortressCategory category, AppLocalizations l10n) {
  return [
    fortressRecurrenceLabel(category.recurrence, l10n),
    l10n.fortressSupplicationCount(category.supplicationCount),
  ].join(' · ');
}
