import 'dart:async';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/layout/collapsible_horizontal_split_pane.dart';
import 'package:tawaq/core/layout/lazy_tab_content.dart';
import 'package:tawaq/core/layout/responsive_horizontal_split.dart';
import 'package:tawaq/core/layout/split_pane_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/shortcuts/shortcuts.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_persisted_settings.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_screen_settings_provider.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/detail/hadith_detail_pane.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/filters/hadith_filter_form.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/hadith_results_column.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/hadith_search_column.dart';
import 'package:tawaq/theme/theme.dart';

/// Main Hadith search and exploration page.
class HadithPage extends HookConsumerWidget {
  /// Creates the Hadith page widget.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenController = ref.read(hadithSessionControllerProvider.notifier);

    return AppShortcutScope(
      autofocus: true,
      shortcuts: {
        AppShortcut.hadithResultNext,
        AppShortcut.hadithResultPrev,
      },
      handlers: {
        AppShortcut.hadithResultNext: () =>
            unawaited(screenController.selectAdjacentResult(1)),
        AppShortcut.hadithResultPrev: () =>
            unawaited(screenController.selectAdjacentResult(-1)),
      },
      child: const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: _HadithResponsiveBody(),
      ),
    );
  }
}

class _HadithResponsiveBody extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResponsiveHorizontalSplitGate(
      sideMin: kStudyPanelMinExtent,
      mainMin: kMainPaneMinExtent,
      builder: (context, useSplitLayout) => _HadithSplitGateBody(
        useSplitLayout: useSplitLayout,
      ),
    );
  }
}

class _HadithSplitGateBody extends ConsumerWidget {
  const new({required this.useSplitLayout});

  final bool useSplitLayout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Do not persist collapse from viewport shrink alone — that would
    // permanently hide the side panel after a narrow window.
    return useSplitLayout
        ? _HadithSplitLayout(useSplitLayout: useSplitLayout)
        : _HadithMainColumn(useSplitLayout: useSplitLayout);
  }
}

class _HadithMainColumn extends StatelessWidget {
  const new({required this.useSplitLayout});

  final bool useSplitLayout;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HadithSearchColumn(useSplitLayout: useSplitLayout),
        const SizedBox(height: AppSpacing.lg),
        Expanded(child: HadithResultsColumn(useSplitLayout: useSplitLayout)),
      ],
    );
  }
}

class _HadithSplitLayout extends ConsumerWidget {
  const new({required this.useSplitLayout});

  final bool useSplitLayout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(hadithScreenSettingsProvider).asData?.value ??
        HadithPersistedSettings.initial();
    final textDirection = Directionality.of(context);
    final l10n = context.l10n;

    return CollapsibleHorizontalSplitPane.feature(
      sidePanelRatio: settings.sidePanelRatio,
      collapsed: settings.sidePanelCollapsed,
      collapsePlacement: CollapsePlacement.none,
      onCollapsedChanged: (value) => ref
          .read(hadithScreenSettingsProvider.notifier)
          .setSidePanelCollapsed(collapsed: value),
      expandSemanticLabel: l10n.expandPanel,
      collapseSemanticLabel: l10n.collapsePanel,
      sideMaxFraction: 0.5,
      onSidePanelRatioChanged: (ratio) => ref
          .read(hadithScreenSettingsProvider.notifier)
          .setSidePanelRatio(ratio),
      sidePane: Padding(
        padding: EdgeInsetsDirectional.only(
          end: settings.sidePanelCollapsed ? 0 : AppSpacing.sm,
        ),
        child: Directionality(
          textDirection: textDirection,
          child: _HadithSidePanel(
            onCollapse: () => ref
                .read(hadithScreenSettingsProvider.notifier)
                .setSidePanelCollapsed(collapsed: true),
            collapseSemanticLabel: l10n.collapsePanel,
          ),
        ),
      ),
      mainPane: Padding(
        padding: const EdgeInsetsDirectional.only(start: AppSpacing.sm),
        child: Directionality(
          textDirection: textDirection,
          child: _HadithMainColumn(useSplitLayout: useSplitLayout),
        ),
      ),
    );
  }
}

class _HadithSidePanel extends ConsumerWidget {
  const new({
    required this.onCollapse,
    required this.collapseSemanticLabel,
  });

  final VoidCallback onCollapse;
  final String collapseSemanticLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSearchMode = ref.watch(
      hadithSessionControllerProvider.select((s) => s.isSearchMode),
    );
    final selectedHadith = ref.watch(selectedHadithProvider);
    final settings =
        ref.watch(hadithScreenSettingsProvider).asData?.value ??
        HadithPersistedSettings.initial();
    final theme = context.theme;
    final l10n = context.l10n;

    var tabIndex = isSearchMode
        ? settings.activeTab.index
        : HadithPanelTab.details.index;
    if (tabIndex < 0) {
      tabIndex = 0;
    } else if (isSearchMode && tabIndex >= HadithPanelTab.values.length) {
      tabIndex = HadithPanelTab.values.length - 1;
    }

    final tabs = <FTabEntry>[
      FTabEntry(
        label: Text(l10n.hadithDetailsTab),
        child: selectedHadith == null
            ? Center(
                child: Text(
                  l10n.hadithNoDetailsSelected,
                  textAlign: TextAlign.center,
                  style: theme.typography.body.md.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
              )
            : HadithSelectedDetailsPane(hadith: selectedHadith),
      ),
      if (isSearchMode)
        FTabEntry(
          label: Text(l10n.hadithFilterTab),
          child: LazyPanelContent.indexed(
            selectedIndex: tabIndex,
            index: HadithPanelTab.filters.index,
            builder: () => const HadithFilterPanel(),
          ),
        ),
    ];

    if (!isSearchMode) {
      tabIndex = HadithPanelTab.details.index;
    } else if (tabIndex >= tabs.length) {
      tabIndex = tabs.length - 1;
    }

    return FSidebar.raw(
      style: .delta(
        decoration: .boxDelta(
          border: .all(color: Colors.transparent),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: _SidePanelCollapseHandle(
              semanticLabel: collapseSemanticLabel,
              onPress: onCollapse,
            ),
          ),
          Expanded(
            child: FTabs(
              key: ValueKey('hadith-side-tabs-${tabs.length}'),
              expands: true,
              control: FTabControl.lifted(
                index: tabIndex,
                onChange: (index) {
                  if (!isSearchMode && index != HadithPanelTab.details.index) {
                    return;
                  }

                  ref
                      .read(hadithScreenSettingsProvider.notifier)
                      .setActiveTab(HadithPanelTab.values[index]);
                },
              ),
              children: tabs,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidePanelCollapseHandle extends StatelessWidget {
  const new({
    required this.semanticLabel,
    required this.onPress,
  });

  final String semanticLabel;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.secondary.withValues(alpha: 0.9),
          shape: BoxShape.circle,
        ),
        child: FButton.icon(
          variant: .ghost,
          size: .sm,
          semanticsLabel: semanticLabel,
          onPress: onPress,
          child: const Icon(FLucideIcons.panelLeftClose, size: 18),
        ),
      ),
    );
  }
}
