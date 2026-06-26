import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/layout/collapsible_horizontal_split_pane.dart';
import 'package:tawaq/core/layout/side_panel_ui_state.dart';
import 'package:tawaq/core/layout/split_extent_resolver.dart';
import 'package:tawaq/core/layout/split_pane_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/f_skeletonizer.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_category.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final l10n = context.l10n;
    final chaptersAsync = ref.watch(muslimFortressChaptersProvider);
    final selectedCategory = ref.watch(fortressSelectedCategoryProvider);
    final isFocusMode = ref.watch(fortressIsFocusModeProvider);
    final globalSearchQuery = ref.watch(muslimFortressSearchQueryProvider);
    final isGlobalSearch = globalSearchQuery.length >= 2;

    useEffect(() {
      if (!chaptersAsync.hasValue) return null;

      var cancelled = false;
      unawaited(() async {
        final service = await ref.read(fortressServiceProvider.future);
        if (cancelled) return;
        ref
            .read(fortressScreenSettingsProvider.notifier)
            .ensureDefaultBookmarks(service.defaultBookmarkChapterIds());
      }());

      return () => cancelled = true;
    }, [chaptersAsync.hasValue]);

    final allCategories = chaptersAsync.when(
      data: (value) => value,
      loading: () => fortressCategoryPlaceholders(l10n: l10n),
      error: (_, _) => const <FortressCategory>[],
    );

    if (isFocusMode && selectedCategory != null) {
      return const Directionality(
        textDirection: TextDirection.rtl,
        child: FortressFocusReadingView(),
      );
    }

    if (chaptersAsync.hasError) {
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
                  '$chaptersAsync.error',
                  style: theme.typography.body.sm.copyWith(
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
      return FortressBrowseSidebar(categories: allCategories);
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
          final contentHeight = viewport.maxHeight.isFinite
              ? viewport.maxHeight - AppSpacing.md * 2
              : MediaQuery.sizeOf(context).height - AppSpacing.md * 2;
          final useSplit = canUseHorizontalSplit(
            containerWidth: viewport.maxWidth,
            sideMin: kStudyPanelMinExtent,
            mainMin: kMainPaneMinExtent,
          );

          return FSkeletonizer(
            enabled: chaptersAsync.isLoading,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: SizedBox(
                height: contentHeight,
                child: useSplit
                    ? _FortressDesktopSplitLayout(
                        mainPane: buildMainPane(),
                        sidebar: buildSidebar(),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 2,
                            child: buildSidebar(),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Expanded(
                            flex: 3,
                            child: buildMainPane(),
                          ),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
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

    return CollapsibleHorizontalSplitPane(
      sidePanelRatio: sidePanelRatio,
      floatingButtonOffset: (
        top: -12,
        left: 0,
        right: 0,
      ),
      sideRegionIndex: 1,
      collapsed: collapsed,
      onCollapsedChanged: (value) => ref
          .read(fortressScreenSettingsProvider.notifier)
          .setSidePanelCollapsed(collapsed: value),
      expandSemanticLabel: l10n.expandPanel,
      collapseSemanticLabel: l10n.collapsePanel,
      resolve: ({required totalWidth, required sideWidth}) =>
          resolveFeatureSplitExtents(
            totalWidth: totalWidth,
            sideWidth: sideWidth,
            sideMin: kStudyPanelMinExtent,
            mainMin: kMainPaneMinExtent,
            sideMaxFraction: 0.45,
          ),
      onSidePanelRatioChanged: (ratio) => ref
          .read(fortressScreenSettingsProvider.notifier)
          .setSidePanelRatio(ratio),
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
