import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/hooks/hooks.dart';
import 'package:tawaq/core/layout/collapsible_horizontal_split_pane.dart';
import 'package:tawaq/core/layout/responsive_horizontal_split.dart';
import 'package:tawaq/core/layout/side_panel_ui_state.dart';
import 'package:tawaq/core/layout/split_pane_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/core/widgets/f_skeletonizer.dart';
import 'package:tawaq/feature/muslim_fortress/data/repository/fortress_repository.dart';
import 'package:tawaq/feature/muslim_fortress/domain/fortress_models.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/fortress_category_ui.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/provider/fortress_screen_settings_provider.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/provider/muslim_fortress_provider.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/browse/fortress_browse_sidebar.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/browse/fortress_category_detail.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/browse/muslim_fortress_welcome_pane.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/reading/fortress_focus_reading.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/search/fortress_search_results.dart';
import 'package:tawaq/theme/theme.dart';

/// Muslim Fortress screen — sidebar browse, welcome home, and focus reading.
class MuslimFortressScreen extends ConsumerWidget {
  /// Creates a Muslim Fortress screen.
  const MuslimFortressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final l10n = context.l10n;
    final repositoryAsync = ref.watch(fortressRepositoryProvider);
    final isFocusMode = ref.watch(
      fortressScreenControllerProvider.select((s) => s.isFocusMode),
    );

    final allCategories = repositoryAsync.when(
      data: (repository) => repository.loadChapters(),
      loading: () => fortressCategoryPlaceholders(l10n: l10n),
      error: (_, _) => const <FortressCategory>[],
    );

    if (isFocusMode) {
      return const Directionality(
        textDirection: TextDirection.rtl,
        child: FortressFocusReadingView(),
      );
    }

    if (repositoryAsync.hasError) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: FScaffold(
          child: Padding(
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
                  style: theme.typography.body.lg.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${repositoryAsync.error}',
                  style: theme.typography.body.sm.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                FButton(
                  onPress: () => ref.invalidate(fortressRepositoryProvider),
                  child: Text(l10n.fortressRetry),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final collapsed = ref.watch(
      fortressScreenSettingsProvider.select(
        (v) =>
            v.asData?.value.sidePanelCollapsed ?? SidePanelDefaults.collapsed,
      ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        collapsed ? 0 : AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: LayoutBuilder(
        builder: (context, viewport) {
          return ResponsiveHorizontalSplitGate(
            sideMin: kStudyPanelMinExtent,
            mainMin: kMainPaneMinExtent,
            builder: (context, useSplit) {
              final contentHeight = viewport.maxHeight.isFinite
                  ? viewport.maxHeight - AppSpacing.md * 2
                  : MediaQuery.sizeOf(context).height - AppSpacing.md * 2;

              return FSkeletonizer(
                enabled: repositoryAsync.isLoading,
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: SizedBox(
                    height: contentHeight,
                    child: useSplit
                        ? _FortressDesktopSplitLayout(
                            mainPane: const _FortressBrowseMainPane(),
                            sidebar: FortressBrowseSidebar(
                              categories: allCategories,
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 2,
                                child: FortressBrowseSidebar(
                                  categories: allCategories,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              const Expanded(
                                flex: 3,
                                child: _FortressBrowseMainPane(),
                              ),
                            ],
                          ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Owns selection/global-search watches so the screen only tracks focus + repo.
class _FortressBrowseMainPane extends HookConsumerWidget {
  const _FortressBrowseMainPane();

  static const _globalSearchDebounce = Duration(milliseconds: 300);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final l10n = context.l10n;
    final selectedCategory = ref.watch(
      fortressScreenControllerProvider.select((s) => s.selectedCategory),
    );
    final committedQuery = ref.watch(
      fortressScreenControllerProvider.select((s) => s.query),
    );
    final isGlobalSearch =
        committedQuery.length >= fortressSearchMinQueryLength;

    final searchController = useTextEditingController(text: committedQuery);
    useListenable(searchController);
    useEffect(() {
      if (searchController.text != committedQuery) {
        searchController.text = committedQuery;
      }
      return null;
    }, [committedQuery]);

    final debouncedCommit = useDebouncedCallback(
      () => ref
          .read(fortressScreenControllerProvider.notifier)
          .setQuery(searchController.text),
      duration: _globalSearchDebounce,
    );
    useEffect(() {
      debouncedCommit();
      return null;
    }, [searchController.text]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NonSelectable(
          child: Row(
            spacing: AppSpacing.sm,
            children: [
              Expanded(
                child: FTextField(
                  hint: l10n.fortressSearchHint,
                  control: FTextFieldControl.managed(
                    controller: searchController,
                  ),
                  prefixBuilder: (context, style, variants) =>
                      const Icon(FLucideIcons.search),
                ),
              ),
              if (committedQuery.isNotEmpty)
                FButton.icon(
                  variant: FButtonVariant.ghost,
                  onPress: () {
                    debouncedCommit.cancel();
                    searchController.clear();
                    ref
                        .read(fortressScreenControllerProvider.notifier)
                        .clearGlobalSearch();
                  },
                  child: const Icon(FLucideIcons.x, size: 16),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: AnimatedSwitcher(
            duration: theme.durations.normal,
            child: isGlobalSearch
                ? const FortressSearchResultsPane()
                : selectedCategory == null
                ? const MuslimFortressWelcomePane(key: ValueKey('welcome'))
                : FortressCategoryDetailView(
                    key: ValueKey(selectedCategory.chapterId),
                  ),
          ),
        ),
      ],
    );
  }
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
    final sidePanelRatio = ref.watch(
      fortressScreenSettingsProvider.select(
        (v) =>
            v.asData?.value.sidePanelRatio ?? SidePanelDefaults.fortressRatio,
      ),
    );
    final collapsed = ref.watch(
      fortressScreenSettingsProvider.select(
        (v) =>
            v.asData?.value.sidePanelCollapsed ?? SidePanelDefaults.collapsed,
      ),
    );
    final l10n = context.l10n;

    return CollapsibleHorizontalSplitPane.feature(
      sidePanelRatio: sidePanelRatio,
      sideOnStart: false,
      floatingButtonOffset: (
        top: -12,
        left: 0,
        right: 0,
      ),
      collapsed: collapsed,
      onCollapsedChanged: (value) => ref
          .read(fortressScreenSettingsProvider.notifier)
          .setSidePanelCollapsed(collapsed: value),
      expandSemanticLabel: l10n.expandPanel,
      collapseSemanticLabel: l10n.collapsePanel,
      sideMaxFraction: 0.45,
      onSidePanelRatioChanged: (ratio) => ref
          .read(fortressScreenSettingsProvider.notifier)
          .setSidePanelRatio(ratio),
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
