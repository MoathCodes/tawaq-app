import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/custom_cards.dart';
import 'package:tawaq/feature/muslim_fortress/data/repository/fortress_repository.dart';
import 'package:tawaq/feature/muslim_fortress/domain/fortress_models.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_screen_state.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/fortress_layout.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/provider/fortress_screen_settings_provider.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/provider/muslim_fortress_provider.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/fortress_a11y.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/theme.dart';

String _fortressCategoryMetaLine(
  FortressCategory category,
  AppLocalizations l10n,
) {
  return [
    fortressRecurrenceLabel(category.recurrence, l10n),
    l10n.fortressSupplicationCount(category.supplicationCount),
  ].join(' · ');
}

/// Home pane when no chapter is selected (time-based picks + bookmarks).
class MuslimFortressWelcomePane extends ConsumerWidget {
  /// Creates a welcome pane.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final repositoryAsync = ref.watch(fortressRepositoryProvider);
    final allCategories =
        repositoryAsync.asData?.value.loadChapters() ??
        const <FortressCategory>[];
    final recommendedCategories = ref.watch(
      fortressRecommendedCategoriesProvider,
    );
    final favoriteChapterIds = ref.watch(
      fortressScreenSettingsProvider.select(
        (v) => v.asData?.value.favoriteChapterIds ?? const [],
      ),
    );

    final categoriesByChapterId = {
      for (final category in allCategories) category.chapterId: category,
    };
    final bookmarkCategories = [
      for (final chapterId in favoriteChapterIds)
        if (categoriesByChapterId[chapterId] != null)
          categoriesByChapterId[chapterId]!,
    ];

    final favoritesPreview = bookmarkCategories.take(4).toList();
    final favoritesOverflow =
        bookmarkCategories.length - favoritesPreview.length;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kFortressReadingMaxWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _WelcomeHeader(),
              const SizedBox(height: AppSpacing.xxl),
              FTileGroup(
                label: Text(l10n.fortressRecommendedNow),
                description: repositoryAsync.hasValue &&
                        recommendedCategories.isEmpty
                    ? Text(
                        l10n.fortressNoRecommendations,
                        style: context.theme.typography.body.sm.copyWith(
                          color: context.theme.colors.mutedForeground,
                        ),
                      )
                    : null,
                children: _fortressCategoryTiles(
                  context,
                  ref,
                  categories: recommendedCategories,
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
                        style: context.theme.typography.body.sm.copyWith(
                          color: context.theme.colors.mutedForeground,
                        ),
                      )
                    : null,
                children: _fortressCategoryTiles(
                  context,
                  ref,
                  categories: favoritesPreview,
                  prefixForIndex: (_) => FLucideIcons.bookmark,
                ),
              ),
              if (favoritesOverflow > 0) ...[
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FButton(
                    variant: .ghost,
                    onPress: () => ref
                        .read(fortressScreenSettingsProvider.notifier)
                        .setSidebarTab(FortressSidebarTab.favorites),
                    child: Text(
                      l10n.fortressMoreFavoriteChapters(favoritesOverflow),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final l10n = context.l10n;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StaticCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          borderRadius: theme.radii.md,
          backgroundColor: colors.primary.withValues(alpha: 0.12),
          borderColor: Colors.transparent,
          child: Icon(
            FLucideIcons.shieldHalf,
            color: colors.primary,
            size: theme.typography.body.xl2.fontSize,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.fortressWelcomeTitle,
                style: theme.typography.body.xl2.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.fortressWelcomeSubtitle,
                style: theme.typography.body.md.copyWith(
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
  BuildContext context,
  WidgetRef ref, {
  required List<FortressCategory> categories,
  required IconData Function(int index) prefixForIndex,
}) {
  final l10n = context.l10n;
  final theme = context.theme;

  return [
    for (var i = 0; i < categories.length; i++)
      FTileMixin.tile(
        prefix: Icon(
          prefixForIndex(i),
          size: theme.typography.body.md.fontSize,
          color: theme.colors.primary,
        ),
        title: Text(
          categories[i].title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _fortressCategoryMetaLine(categories[i], l10n),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        suffix: Icon(
          FLucideIcons.chevronRight,
          size: theme.typography.body.sm.fontSize,
          color: theme.colors.mutedForeground,
        ),
        semanticsLabel: FortressA11y.categoryCardLabel(
          l10n,
          title: categories[i].title,
          recurrence: fortressRecurrenceLabel(categories[i].recurrence, l10n),
          supplicationCount: categories[i].supplicationCount,
        ),
        onPress: () => ref
            .read(fortressScreenControllerProvider.notifier)
            .selectCategory(categories[i]),
      ),
  ];
}
