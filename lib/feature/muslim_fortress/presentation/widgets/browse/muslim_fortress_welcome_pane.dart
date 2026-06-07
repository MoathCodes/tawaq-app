import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/custom_cards.dart';
import 'package:tawaq/core/widgets/mouse_click.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_category.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_locale_extensions.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/fortress_a11y.dart';
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

  ///
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final l10n = context.l10n;
    final categories = bookmarkCategories.take(4).toList();
    final numLeft = bookmarkCategories.length - 4;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StaticCard(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.fortressWelcomeTitle,
                  style: theme.typography.xl3.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.fortressWelcomeSubtitle,
                  style: theme.typography.md.copyWith(
                    color: colors.mutedForeground,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            l10n.fortressRecommendedNow,
            style: theme.typography.lg.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.md),
          if (recommendedCategories.isEmpty)
            _SectionEmptyHint(message: l10n.fortressNoRecommendations)
          else
            _CategoryCardGrid(
              categories: recommendedCategories,
              onSelectCategory: onSelectCategory,
            ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            l10n.fortressFavorites,
            style: theme.typography.lg.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.md),
          if (categories.isEmpty)
            _SectionEmptyHint(message: l10n.fortressNoFavoriteChapters)
          else ...[
            _CategoryCardGrid(
              categories: categories,
              onSelectCategory: onSelectCategory,
            ),
            const SizedBox(
              height: AppSpacing.md,
            ),
            FButton(
              variant: .ghost,
              onPress: onViewAll,
              child: Text(
                "إضافةً إلى ${numLeft} أبواب أخرى...",
                style: theme.typography.sm.copyWith(
                  color: colors.mutedForeground,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionEmptyHint extends StatelessWidget {
  const _SectionEmptyHint({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Text(
        message,
        style: theme.typography.sm.copyWith(
          color: theme.colors.mutedForeground,
        ),
      ),
    );
  }
}

class _CategoryCardGrid extends StatelessWidget {
  const _CategoryCardGrid({
    required this.categories,
    required this.onSelectCategory,
  });

  final List<FortressCategory> categories;
  final ValueChanged<FortressCategory> onSelectCategory;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = switch (constraints.maxWidth) {
          > 900 => 4,
          > 520 => 2,
          _ => 1,
        };
        final width =
            (constraints.maxWidth - AppSpacing.md * (columns - 1)) / columns;

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final category in categories)
              SizedBox(
                width: width,
                child: _FortressCategoryCard(
                  category: category,
                  onTap: () => onSelectCategory(category),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FortressCategoryCard extends StatelessWidget {
  const _FortressCategoryCard({
    required this.category,
    required this.onTap,
  });

  final FortressCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final l10n = context.l10n;
    final meta = [
      fortressRecurrenceLabel(category.recurrence, l10n),
      l10n.fortressSupplicationCount(category.supplicationCount),
    ].join(' · ');

    return MouseClick(
      onClick: onTap,
      semanticsLabel: FortressA11y.categoryCardLabel(
        l10n,
        title: category.title,
        recurrence: fortressRecurrenceLabel(category.recurrence, l10n),
        supplicationCount: category.supplicationCount,
      ),
      child: HoverCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              category.title,
              style: theme.typography.md.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              meta,
              style: theme.typography.xs.copyWith(
                color: colors.mutedForeground,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
