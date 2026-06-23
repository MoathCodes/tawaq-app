import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/layout/responsive.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/shortcuts/shortcuts.dart';
import 'package:tawaq/core/widgets/animation_entry.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/core/widgets/empty_state_panel.dart';
import 'package:tawaq/core/widgets/mouse_click.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_category.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_locale_extensions.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_screen_state.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/provider/muslim_fortress_provider.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/fortress_a11y.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/theme/theme.dart';

/// Sidebar browse panel: local filter, favorites tab, and chapter list.
class FortressBrowseSidebar extends HookConsumerWidget {
  /// Creates the fortress browse sidebar.
  const FortressBrowseSidebar({
    required this.categories,
    super.key,
  });

  /// All categories (or loading placeholders) to browse.
  final List<FortressCategory> categories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final l10n = context.l10n;
    final searchController = useTextEditingController();
    useListenable(searchController);
    final searchFocusNode = useFocusNode();
    final animatedSidebarChapterIds = useRef(<int>{});
    final focusSearch = useCallback(
      searchFocusNode.requestFocus,
      [searchFocusNode],
    );
    useRegisterAppSearchFocus(focusSearch);
    final favoriteChapterIds = ref.watch(
      fortressUiStateProvider.select((state) => state.favoriteChapterIds),
    );
    final isFavoritesTab = ref.watch(
      fortressUiStateProvider.select(
        (s) => s.sidebarTab == FortressSidebarTab.favorites,
      ),
    );
    final globalSearchQuery = ref.watch(muslimFortressSearchQueryProvider);

    useEffect(() {
      final timer = Timer(const Duration(milliseconds: 300), () {
        ref
            .read(muslimFortressSearchQueryProvider.notifier)
            .setQuery(searchController.text);
      });
      return timer.cancel;
    }, [searchController.text]);

    useEffect(() {
      if (searchController.text != globalSearchQuery) {
        searchController.text = globalSearchQuery;
      }
      return null;
    }, [globalSearchQuery]);

    final sidebarQuery = searchController.text.toLowerCase();
    final sourceCategories = isFavoritesTab
        ? categories
              .where((c) => favoriteChapterIds.contains(c.chapterId))
              .toList()
        : categories;

    final filteredCategories = sourceCategories.where((category) {
      if (sidebarQuery.isEmpty) return true;
      return category.title.toLowerCase().contains(sidebarQuery) ||
          fortressRecurrenceLabel(
            category.recurrence,
            l10n,
          ).toLowerCase().contains(sidebarQuery);
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final iconOnlyTabs = !isContainerAtLeast(
          context,
          constraints,
          FBreakpoint.sm,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.muslimFortress,
              style: (compact
                      ? theme.typography.body.lg
                      : theme.typography.body.xl2)
                  .copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
            NonSelectable(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FTextField(
                    focusNode: searchFocusNode,
                    hint: l10n.fortressSearchHint,
                    control: FTextFieldControl.managed(
                      controller: searchController,
                    ),
                    prefixBuilder: (context, style, variants) =>
                        const Icon(FLucideIcons.search),
                  ),
                  SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
                  FTabs(
                    control: .lifted(
                      index: isFavoritesTab ? 1 : 0,
                      onChange: (index) => ref
                          .read(fortressScreenSettingsProvider.notifier)
                          .setSidebarTab(
                            index == 1 ? .favorites : .allChapters,
                          ),
                    ),
                    children: [
                      FTabEntry(
                        label: iconOnlyTabs
                            ? const Icon(FLucideIcons.bookOpenText, size: 18)
                            : Text(l10n.fortressAllChapters),
                        child: const SizedBox.shrink(),
                      ),
                      FTabEntry(
                        label: iconOnlyTabs
                            ? const Icon(FLucideIcons.bookmark, size: 18)
                            : Text(l10n.fortressFavorites),
                        child: const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
            Expanded(
              child: filteredCategories.isEmpty
                  ? FortressEmptySidePanelState(isFavoritesTab: isFavoritesTab)
                  : ListView.separated(
                      itemCount: filteredCategories.length,
                      separatorBuilder: (context, index) => SizedBox(
                        height: compact ? AppSpacing.xs : AppSpacing.sm,
                      ),
                      itemBuilder: (context, index) {
                        final category = filteredCategories[index];

                        final tile = FortressCategoryListTile(
                          category: category,
                          compact: compact,
                        );

                        if (animatedSidebarChapterIds.value.contains(
                          category.chapterId,
                        )) {
                          return tile;
                        }

                        return AnimationEntry(
                          key: ValueKey(category.chapterId),
                          animateOnce: true,
                          delay: Duration(milliseconds: 100 + (index * 20)),
                          onEntranceComplete: () {
                            animatedSidebarChapterIds.value = {
                              ...animatedSidebarChapterIds.value,
                              category.chapterId,
                            };
                          },
                          child: tile,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// Category list tile for the fortress browse sidebar.
class FortressCategoryListTile extends ConsumerWidget {
  /// Creates a category list tile.
  const FortressCategoryListTile({
    required this.category,
    this.compact = false,
    super.key,
  });

  /// Category shown in this tile.
  final FortressCategory category;

  /// Denser layout for narrow sidebars.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final chapterId = category.chapterId;
    final isSelected = ref.watch(
      fortressSelectedCategoryProvider.select(
        (selected) => selected?.chapterId == chapterId,
      ),
    );
    final favoriteChapterIds = ref.watch(
      fortressUiStateProvider.select((state) => state.favoriteChapterIds),
    );
    final isFavorite = favoriteChapterIds.contains(chapterId);

    final bgColor = isSelected
        ? theme.colors.primary.withAlpha(20)
        : Colors.transparent;
    final borderColor = isSelected
        ? theme.colors.primary
        : theme.colors.border.withAlpha(80);

    final l10n = context.l10n;

    return MouseClick(
      onClick: () => ref
          .read(fortressScreenControllerProvider.notifier)
          .selectCategory(category),
      semanticsLabel: category.title,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppSpacing.sm : AppSpacing.md,
          vertical: compact ? AppSpacing.sm : AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: theme.radii.md,
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: FortressExcludeDecorative(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.title,
                      style: theme.typography.body.md.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? theme.colors.primary
                            : theme.colors.foreground,
                      ),
                      maxLines: compact ? 2 : null,
                      overflow: compact ? TextOverflow.ellipsis : null,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fortressRecurrenceLabel(category.recurrence, l10n),
                      style: theme.typography.body.sm.copyWith(
                        color: isSelected
                            ? theme.colors.primary.withAlpha(150)
                            : theme.colors.mutedForeground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!compact) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.fortressSupplicationCount(
                          category.supplicationCount,
                        ),
                        style: theme.typography.body.xs.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            MouseClick(
              onClick: () => ref
                  .read(fortressScreenSettingsProvider.notifier)
                  .toggleFavorite(chapterId),
              semanticsLabel: l10n.fortressFavorites,
              child: FortressExcludeDecorative(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: Icon(
                    isFavorite
                        ? FLucideIcons.bookmarkCheck
                        : FLucideIcons.bookmark,
                    size: 18,
                    color: isFavorite
                        ? theme.colors.primary
                        : theme.colors.mutedForeground,
                    fill: isFavorite ? 1.0 : 0.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FortressEmptySidePanelState extends StatelessWidget {
  /// Creates an empty sidebar placeholder.
  const FortressEmptySidePanelState({required this.isFavoritesTab, super.key});

  /// Whether the favorites tab is active (vs local search filter).
  final bool isFavoritesTab;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return EmptyStatePanel(
      icon: isFavoritesTab ? FLucideIcons.bookmark : FLucideIcons.searchX,
      title: isFavoritesTab
          ? l10n.fortressEmptyFavoritesTitle
          : l10n.fortressEmptySearchTitle,
      hint: isFavoritesTab
          ? l10n.fortressEmptyFavoritesHint
          : l10n.fortressEmptySearchHint,
      semanticsLabel: FortressA11y.sidebarEmptyLabel(
        l10n,
        favorites: isFavoritesTab,
      ),
    );
  }
}
