import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/layout/persisted_horizontal_split_pane.dart';
import 'package:tawaq/core/layout/responsive.dart';
import 'package:tawaq/core/layout/split_pane_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/shortcuts/use_register_app_search_focus.dart';
import 'package:tawaq/core/widgets/animation_entry.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/core/widgets/f_skeletonizer.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_category.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_locale_extensions.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_screen_state.dart';
import 'package:tawaq/feature/muslim_fortress/domain/services/fortress_service.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/fortress_category_ui.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/provider/muslim_fortress_provider.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/browse/fortress_browse_sidebar.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/browse/fortress_category_detail.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/browse/muslim_fortress_welcome_pane.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/reading/fortress_focus_reading.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/search/fortress_search_results.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/theme/theme.dart';

/// Muslim Fortress screen — sidebar browse, welcome home, and focus reading.
class MuslimFortressScreen extends HookConsumerWidget {
  /// Creates a Muslim Fortress screen.
  const MuslimFortressScreen({super.key});

  static const _sidebarMinExtent = 280.0;
  static const _mainPaneMinExtent = 480.0;
  static const _stackedSidebarMaxHeight = 360.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final l10n = context.l10n;
    final chaptersAsync = ref.watch(muslimFortressChaptersProvider);
    final screenState = ref.watch(fortressUiStateProvider);
    final favoriteChapterIds = screenState.favoriteChapterIds;
    final isFavoritesTab =
        screenState.sidebarTab == FortressSidebarTab.favorites;
    final selectedCategory = ref.watch(fortressSelectedCategoryProvider);
    final isFocusMode = ref.watch(fortressIsFocusModeProvider);
    final animatedSidebarChapterIds = useRef(<int>{});
    final searchController = useTextEditingController();
    useListenable(searchController);
    final searchFocusNode = useFocusNode();
    final focusSearch = useCallback(
      searchFocusNode.requestFocus,
      [searchFocusNode],
    );

    useRegisterAppSearchFocus(focusSearch, enabled: !isFocusMode);
    final sidebarQuery = searchController.text.toLowerCase();
    final globalSearchQuery = ref.watch(muslimFortressSearchQueryProvider);
    final isGlobalSearch = globalSearchQuery.length >= 2;

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

    useEffect(() {
      if (!chaptersAsync.hasValue) return null;

      unawaited(() async {
        final service = await ref.read(fortressServiceProvider.future);
        ref
            .read(fortressScreenSettingsProvider.notifier)
            .ensureDefaultBookmarks(service.defaultBookmarkChapterIds());
      }());

      return null;
    }, [chaptersAsync.hasValue]);

    final allCategories = chaptersAsync.when(
      data: (value) => value,
      loading: () => fortressCategoryPlaceholders(l10n: l10n),
      error: (_, _) => const <FortressCategory>[],
    );

    final sourceCategories = isFavoritesTab
        ? allCategories
              .where((c) => favoriteChapterIds.contains(c.chapterId))
              .toList()
        : allCategories;

    final filteredCategories = sourceCategories.where((category) {
      if (sidebarQuery.isEmpty) return true;
      return category.title.toLowerCase().contains(sidebarQuery) ||
          fortressRecurrenceLabel(
            category.recurrence,
            l10n,
          ).toLowerCase().contains(sidebarQuery);
    }).toList();

    if (isFocusMode && selectedCategory != null) {
      return const Directionality(
        textDirection: TextDirection.rtl,
        child: FortressFocusReadingView(),
      );
    }

    if (chaptersAsync.hasError) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: theme.colors.background,
          body: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  FLucideIcons.circleAlert,
                  size: 48,
                  color: theme.colors.error,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.fortressLoadError,
                  style: theme.typography.lg.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '$chaptersAsync.error',
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                FButton(
                  onPress: () => ref.invalidate(muslimFortressChaptersProvider),
                  child: Text(l10n.fortressRetry),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget buildSidebar() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.muslimFortress,
            style: theme.typography.xl2.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
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
                const SizedBox(height: AppSpacing.lg),
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
                      label: Text(l10n.fortressAllChapters),
                      child: const SizedBox.shrink(),
                    ),
                    FTabEntry(
                      label: Text(l10n.fortressFavorites),
                      child: const SizedBox.shrink(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: filteredCategories.isEmpty
                ? FortressEmptySidePanelState(isFavoritesTab: isFavoritesTab)
                : ListView.separated(
                    itemCount: filteredCategories.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final category = filteredCategories[index];

                      final tile = FortressCategoryListTile(
                        category: category,
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
    }

    Widget buildMainPane() {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: isGlobalSearch
            ? FortressSearchResultsPane(
                key: ValueKey(globalSearchQuery),
              )
            : selectedCategory == null
            ? const MuslimFortressWelcomePane(key: ValueKey('welcome'))
            : FortressCategoryDetailView(
                key: ValueKey(selectedCategory.chapterId),
              ),
      );
    }

    return LayoutBuilder(
      builder: (context, viewport) {
        final contentHeight = viewport.maxHeight.isFinite
            ? viewport.maxHeight - AppSpacing.md * 2
            : MediaQuery.sizeOf(context).height - AppSpacing.md * 2;
        final isNarrow = isLessThan(context, FBreakpoint.md);

        return FSkeletonizer(
          enabled: chaptersAsync.isLoading,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                height: contentHeight,
                child: isNarrow
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: buildMainPane()),
                          const SizedBox(height: AppSpacing.md),
                          SizedBox(
                            height: _stackedSidebarMaxHeight.clamp(
                              0,
                              contentHeight * 0.45,
                            ),
                            child: buildSidebar(),
                          ),
                        ],
                      )
                    : _FortressDesktopSplitLayout(
                        mainPane: buildMainPane(),
                        sidebar: buildSidebar(),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Resolved side/main pane widths for the fortress split layout.
({
  double sideExtent,
  double mainExtent,
  double sideMin,
  double mainMin,
  double sideMax,
})
_resolveFortressSplitExtents({
  required double totalWidth,
  required double sideWidth,
}) {
  const sideMinTarget = MuslimFortressScreen._sidebarMinExtent;
  const mainMinTarget = MuslimFortressScreen._mainPaneMinExtent;

  if (totalWidth <= 0) {
    return (
      sideExtent: 0,
      mainExtent: 0,
      sideMin: 0,
      mainMin: 0,
      sideMax: 0,
    );
  }

  final sideMin = sideMinTarget.clamp(0.0, totalWidth);
  final mainMin = mainMinTarget.clamp(0.0, totalWidth - sideMin);
  final sideMax = (totalWidth * 0.45).clamp(sideMin, totalWidth - mainMin);

  final extents = resolveSplitExtents(
    totalWidth: totalWidth,
    sideWidth: sideWidth,
    sideMin: sideMin,
    mainMin: mainMin,
    sideMax: sideMax,
  );

  return (
    sideExtent: extents.sideExtent,
    mainExtent: extents.mainExtent,
    sideMin: sideMin,
    mainMin: mainMin,
    sideMax: sideMax,
  );
}

class _FortressDesktopSplitLayout extends ConsumerWidget {
  const _FortressDesktopSplitLayout({
    required this.mainPane,
    required this.sidebar,
  });

  final Widget mainPane;
  final Widget sidebar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sidePanelWidth = ref.watch(
      fortressScreenSettingsProvider.select(
        (v) => v.asData?.value.sidePanelWidth ?? 300,
      ),
    );

    return PersistedHorizontalSplitPane(
      sidePanelWidth: sidePanelWidth,
      sideRegionIndex: 1,
      resolve: ({required totalWidth, required sideWidth}) {
        final resolved = _resolveFortressSplitExtents(
          totalWidth: totalWidth,
          sideWidth: sideWidth,
        );
        return (
          sideExtent: resolved.sideExtent,
          mainExtent: resolved.mainExtent,
          sideMin: resolved.sideMin,
          mainMin: resolved.mainMin,
        );
      },
      onSidePanelWidthChanged: (width) => ref
          .read(fortressScreenSettingsProvider.notifier)
          .setSidePanelWidth(width),
      style: const .delta(
        thumbStyle: .delta(
          decoration: .boxDelta(
            border: .fromBorderSide(
              .new(color: Colors.transparent),
            ),
          ),
        ),
      ),
      mainPane: Padding(
        padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: mainPane,
        ),
      ),
      sidePane: Padding(
        padding: const EdgeInsetsDirectional.only(start: AppSpacing.sm),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: sidebar,
        ),
      ),
    );
  }
}
