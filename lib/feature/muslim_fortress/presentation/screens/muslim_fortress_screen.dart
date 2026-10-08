import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/layout/collapsible_horizontal_split_pane.dart';
import 'package:tawaq/core/layout/responsive_horizontal_split.dart';
import 'package:tawaq/core/layout/side_panel_ui_state.dart';
import 'package:tawaq/core/layout/split_pane_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/shortcuts/shortcuts.dart';
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
import 'package:tawaq/theme/theme.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/study/fortress_dua_insights.dart';

/// Muslim Fortress screen — sidebar browse, welcome home, and focus reading.
class MuslimFortressScreen extends HookConsumerWidget {
  /// Creates a Muslim Fortress screen.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compactReading = useState(false);
    final sidebarKey = useMemoized(GlobalKey.new);
    final searchFocusNode = useFocusNode();
    final mainKey = useMemoized(GlobalKey.new);
    ref.listen(fortressScreenControllerProvider, (previous, next) {
      if (previous?.selectedChapterId != next.selectedChapterId &&
          next.selectedChapterId != null) {
        compactReading.value = true;
      }
    });
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

    useRegisterAppSearchFocus(
      useCallback(() {
        compactReading.value = false;
        ref
            .read(fortressScreenSettingsProvider.notifier)
            .setSidePanelCollapsed(collapsed: false);
        // An unattached node retains this request until the pane remounts.
        // A mounted field focuses immediately even if revealing it made no
        // state change (and therefore did not schedule another frame).
        searchFocusNode.requestFocus();
      }, [searchFocusNode]),
      enabled: !isFocusMode,
    );

    if (isFocusMode) {
      return const FortressFocusReadingView();
    }

    if (repositoryAsync.hasError) {
      return Directionality(
        textDirection: Directionality.of(context),
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
                  l10n.fortressEmptySearchHint,
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

    return FortressStudyHost(
      chapterId: ref.watch(
        fortressScreenControllerProvider.select(
          (state) => state.selectedChapterId,
        ),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          collapsed ? 0 : AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
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
                    textDirection: Directionality.of(context),
                    child: SizedBox(
                      height: contentHeight,
                      child: useSplit && contentHeight >= 480
                          ? _FortressDesktopSplitLayout(
                              mainPane: _FortressBrowseMainPane(key: mainKey),
                              sidebar: FortressBrowseSidebar(
                                key: sidebarKey,
                                categories: allCategories,
                                onCollapse: () => ref
                                    .read(
                                      fortressScreenSettingsProvider.notifier,
                                    )
                                    .setSidePanelCollapsed(collapsed: true),
                                searchFocusNode: searchFocusNode,
                              ),
                            )
                          : Stack(
                              children: [
                                Positioned.fill(
                                  child: Offstage(
                                    offstage: compactReading.value,
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: FortressBrowseSidebar(
                                            key: sidebarKey,
                                            categories: allCategories,
                                            onSelected: () =>
                                                compactReading.value = true,
                                            searchFocusNode: searchFocusNode,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: Offstage(
                                    offstage: !compactReading.value,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Align(
                                          alignment:
                                              AlignmentDirectional.centerStart,
                                          child: FButton(
                                            variant: .ghost,
                                            onPress: () =>
                                                compactReading.value = false,
                                            prefix: Icon(
                                              Directionality.of(context) ==
                                                      TextDirection.rtl
                                                  ? FLucideIcons.arrowRight
                                                  : FLucideIcons.arrowLeft,
                                            ),
                                            child: Text(
                                              l10n.fortressBackToCatalog,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: _FortressBrowseMainPane(
                                            key: mainKey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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
      ),
    );
  }
}

/// Owns chapter selection while browse/search stays in the sidebar.
class _FortressBrowseMainPane extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(fortressSelectedCategoryProvider);
    return AnimatedSwitcher(
      duration: context.theme.durations.normal,
      child: selectedCategory == null
          ? const MuslimFortressWelcomePane(key: ValueKey('welcome'))
          : FortressCategoryDetailView(
              key: ValueKey(selectedCategory.chapterId),
            ),
    );
  }
}

class _FortressDesktopSplitLayout extends ConsumerWidget {
  const new({required this.mainPane, required this.sidebar});

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
      sideOnStart: Directionality.of(context) == TextDirection.ltr,
      collapsePlacement: CollapsePlacement.none,
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
        padding: Directionality.of(context) == TextDirection.ltr
            ? const EdgeInsets.only(left: AppSpacing.lg)
            : const EdgeInsets.only(right: AppSpacing.lg),
        child: Directionality(
          textDirection: Directionality.of(context),
          child: mainPane,
        ),
      ),
      sidePane: Padding(
        padding: Directionality.of(context) == TextDirection.ltr
            ? const EdgeInsets.only(right: AppSpacing.lg)
            : const EdgeInsets.only(left: AppSpacing.lg),
        child: Directionality(
          textDirection: Directionality.of(context),
          child: sidebar,
        ),
      ),
    );
  }
}
