import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/hooks/hooks.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/text/arabic_search_normalize.dart';
import 'package:tawaq/core/widgets/animation_entry.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/core/widgets/empty_state_panel.dart';
import 'package:tawaq/core/widgets/localized_search_clear_button.dart';
import 'package:tawaq/core/widgets/mouse_click.dart';
import 'package:tawaq/feature/muslim_fortress/data/repository/fortress_repository.dart';
import 'package:tawaq/feature/muslim_fortress/domain/fortress_models.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_screen_state.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/provider/fortress_screen_settings_provider.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/provider/muslim_fortress_provider.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/fortress_a11y.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/fortress_category_row.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/fortress_favorite_toggle.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/search/fortress_search_results.dart';
import 'package:tawaq/theme/theme.dart';

/// Sidebar catalog and the single search entry point for chapters and adhkar.
class FortressBrowseSidebar extends HookConsumerWidget {
  /// Creates the fortress browse sidebar.
  const new({
    required this.categories,
    this.onSelected,
    this.onCollapse,
    this.searchFocusNode,
    super.key,
  });

  /// All categories (or loading placeholders) to browse.
  final List<FortressCategory> categories;

  /// Opens the reading destination in compact layout.
  final VoidCallback? onSelected;

  /// Collapse action placed beside the sidebar title in wide layouts.
  final VoidCallback? onCollapse;

  /// Screen-owned focus node keeps search reachable while the pane is collapsed.
  final FocusNode? searchFocusNode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final l10n = context.l10n;
    final committedQuery = ref.watch(
      fortressScreenControllerProvider.select((s) => s.query),
    );
    final selectedChapterId = ref.watch(
      fortressScreenControllerProvider.select((s) => s.selectedChapterId),
    );
    final filterController = useTextEditingController(text: committedQuery);
    useListenable(filterController);
    final fallbackFocusNode = useFocusNode();
    final searchFocusNode = this.searchFocusNode ?? fallbackFocusNode;
    final commit = useDebouncedCallback(
      () => ref
          .read(fortressScreenControllerProvider.notifier)
          .setQuery(filterController.text),
      duration: const Duration(milliseconds: 300),
    );
    useEffect(() {
      if (filterController.text != committedQuery) {
        commit.cancel();
        filterController.value = TextEditingValue(
          text: committedQuery,
          selection: TextSelection.collapsed(offset: committedQuery.length),
        );
      }
      return null;
    }, [committedQuery, selectedChapterId]);
    useEffect(() {
      if (filterController.text.trim() != committedQuery) commit();
      return null;
    }, [filterController.text]);
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

    final sidebarQuery = filterController.text.trim();
    final categoriesById = {
      for (final category in categories) category.chapterId: category,
    };
    // Favorites tab follows persisted order (most recent first), not catalog order.
    final sourceCategories = isFavoritesTab
        ? [
            for (final id in favoriteChapterIds)
              if (categoriesById[id] != null) categoriesById[id]!,
          ]
        : categories;

    final filteredCategories = sourceCategories.where((category) {
      if (sidebarQuery.isEmpty) return true;
      return arabicSearchContains(category.title, sidebarQuery) ||
          arabicSearchContains(
            fortressRecurrenceLabel(category.recurrence, l10n),
            sidebarQuery,
          );
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.muslimFortress,
                    style:
                        (compact
                                ? theme.typography.body.lg
                                : theme.typography.body.xl2)
                            .copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (onCollapse != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  FButton.icon(
                    variant: .ghost,
                    size: .sm,
                    semanticsLabel: l10n.collapsePanel,
                    semanticsTooltip: l10n.collapsePanel,
                    onPress: onCollapse,
                    child: Icon(
                      Directionality.of(context) == TextDirection.rtl
                          ? FLucideIcons.panelRightClose
                          : FLucideIcons.panelLeftClose,
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
            NonSelectable(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FTextField(
                    focusNode: searchFocusNode,
                    hint: isFavoritesTab
                        ? l10n.fortressFilterChaptersHint
                        : l10n.fortressSearchHint,
                    textInputAction: TextInputAction.search,
                    onSubmit: (value) {
                      commit.cancel();
                      ref
                          .read(fortressScreenControllerProvider.notifier)
                          .setQuery(value);
                    },
                    control: FTextFieldControl.managed(
                      controller: filterController,
                    ),
                    clearIconBuilder: localizedSearchClearButton,
                    clearable: (value) => value.text.isNotEmpty,
                    prefixBuilder: (context, style, variants) => Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Icon(
                        FLucideIcons.search,
                        color: theme.colors.mutedForeground,
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
                  FTabs(
                    style: theme.tabs.compact.copyWith(minHeight: 32),
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
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: AppSpacing.sm,
                          children: [
                            const Icon(FLucideIcons.bookOpenText, size: 16),
                            Flexible(child: Text(l10n.fortressAllChapters)),
                          ],
                        ),
                        child: const SizedBox.shrink(),
                      ),
                      FTabEntry(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: AppSpacing.sm,
                          children: [
                            const Icon(FLucideIcons.bookmark, size: 16),
                            Flexible(child: Text(l10n.fortressFavorites)),
                          ],
                        ),
                        child: const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
            Expanded(
              child:
                  !isFavoritesTab &&
                      committedQuery.length >= fortressSearchMinQueryLength
                  ? FortressSearchResultsPane(onSelected: onSelected)
                  : filteredCategories.isEmpty
                  ? FortressEmptySidePanelState(
                      isFavoritesTab:
                          isFavoritesTab && sourceCategories.isEmpty,
                    )
                  : ListView.separated(
                      itemCount: filteredCategories.length,
                      separatorBuilder: (context, index) => SizedBox(
                        height: compact ? AppSpacing.xs : AppSpacing.sm,
                      ),
                      itemBuilder: (context, index) {
                        final category = filteredCategories[index];

                        final tile = FortressCategoryListTile(
                          category: category,
                          onSelected: onSelected,
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
  const new({
    required this.category,
    this.compact = false,
    this.onSelected,
    super.key,
  });

  /// Category shown in this tile.
  final FortressCategory category;

  /// Denser layout for narrow sidebars.
  final bool compact;
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final chapterId = category.chapterId;
    final isSelected = ref.watch(
      fortressScreenControllerProvider.select(
        (s) => s.selectedChapterId == chapterId,
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
      onClick: () {
        if (onSelected == null || !isSelected) {
          ref
              .read(fortressScreenControllerProvider.notifier)
              .selectCategory(category);
        }
        onSelected?.call();
      },
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
        child: ExcludeSemantics(
          child: FortressCategoryRow(
            category: category,
            l10n: l10n,
            compact: compact,
            selected: isSelected,
            trailing: FortressFavoriteToggle(chapterId: chapterId),
          ),
        ),
      ),
    );
  }
}

class FortressEmptySidePanelState extends StatelessWidget {
  /// Creates an empty sidebar placeholder.
  const new({required this.isFavoritesTab, super.key});

  /// Whether the favorites tab is active (vs local chapter filter).
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
