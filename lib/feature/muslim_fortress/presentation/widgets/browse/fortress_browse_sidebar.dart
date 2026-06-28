import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/hooks/hooks.dart';
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
import 'package:tawaq/feature/muslim_fortress/presentation/fortress_category_ui.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/provider/muslim_fortress_provider.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/fortress_a11y.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/fortress_category_row.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/fortress_favorite_toggle.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/provider/fortress_screen_settings_provider.dart';
import 'package:tawaq/theme/theme.dart';

/// Sidebar browse panel: filter, favorites tab, and chapter list.
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
    final committedQuery = ref.watch(muslimFortressSearchQueryProvider);
    final searchController = useTextEditingController(text: committedQuery);
    useListenable(searchController);
    final searchFocusNode = useFocusNode();
    final focusSearch = useCallback(
      searchFocusNode.requestFocus,
      [searchFocusNode],
    );
    useRegisterAppSearchFocus(focusSearch);
    useEffect(() {
      if (searchController.text != committedQuery) {
        searchController.text = committedQuery;
      }
      return null;
    }, [committedQuery]);
    final debouncedCommit = useDebouncedCallback(
      () => ref
          .read(muslimFortressSearchQueryProvider.notifier)
          .setQuery(searchController.text),
      duration: const Duration(milliseconds: 300),
    );
    useEffect(() {
      debouncedCommit();
      return null;
    }, [searchController.text]);
    final animatedSidebarChapterIds = useRef(<int>{});
    final favoriteChapterIds = ref.watch(
      fortressScreenSettingsProvider.select(
        (v) => v.asData?.value.favoriteChapterIds ?? const [],
      ),
    );
    final isFavoritesTab = ref.watch(
      fortressScreenSettingsProvider.select(
        (v) =>
            (v.asData?.value.sidebarTab ?? FortressSidebarTab.allChapters) ==
            FortressSidebarTab.favorites,
      ),
    );

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
      fortressScreenControllerProvider.select(
        (s) => s.selectedCategory?.chapterId == chapterId,
      ),
    );

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
        child: FortressExcludeDecorative(
          child: FortressCategoryRow(
            category: category,
            l10n: l10n,
            compact: compact,
            selected: isSelected,
            icon: category.icon,
            trailing: FortressFavoriteToggle(chapterId: chapterId),
          ),
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
