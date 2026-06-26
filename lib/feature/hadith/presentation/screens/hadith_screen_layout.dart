part of 'hadith_screen.dart';

class _DesktopSplitLayout extends ConsumerWidget {
  const _DesktopSplitLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sidePanelRatio = ref.watch(hadithSidePanelRatioProvider);
    final collapsed = ref.watch(hadithSidePanelCollapsedProvider);
    final textDirection = Directionality.of(context);
    final l10n = context.l10n;

    return _HadithCollapsibleSplitLayout(
      sidePanelRatio: sidePanelRatio,
      collapsed: collapsed,
      onCollapsedChanged: (value) => ref
          .read(hadithScreenSettingsProvider.notifier)
          .setSidePanelCollapsed(collapsed: value),
      expandSemanticLabel: l10n.expandPanel,
      collapseSemanticLabel: l10n.collapsePanel,
      resolve: ({required totalWidth, required sideWidth}) =>
          resolveFeatureSplitExtents(
            totalWidth: totalWidth,
            sideWidth: sideWidth,
            sideMin: kStudyPanelMinExtent,
            mainMin: kMainPaneMinExtent,
            sideMaxFraction: 0.5,
          ),
      onSidePanelRatioChanged: (ratio) => ref
          .read(hadithScreenSettingsProvider.notifier)
          .setSidePanelRatio(ratio),
      style: const .delta(
        thumbStyle: .delta(
          decoration: .boxDelta(
            border: .fromBorderSide(.new(color: Colors.transparent)),
          ),
        ),
      ),
      sidePane: Padding(
        padding: EdgeInsetsDirectional.only(end: collapsed ? 0 : AppSpacing.sm),
        child: Directionality(
          textDirection: textDirection,
          child: _SidePanel(
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
          child: const Column(
            children: [
              _SearchHeader(),
              SizedBox(height: AppSpacing.lg),
              Expanded(child: _ResultsList()),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hadith split layout with the collapse affordance in the side-panel header
/// instead of overlaid on [FTabs] tab controls.
class _HadithCollapsibleSplitLayout extends StatelessWidget {
  const _HadithCollapsibleSplitLayout({
    required this.sidePanelRatio,
    required this.resolve,
    required this.onSidePanelRatioChanged,
    required this.collapsed,
    required this.onCollapsedChanged,
    required this.sidePane,
    required this.mainPane,
    required this.expandSemanticLabel,
    required this.collapseSemanticLabel,
    this.style,
  });

  static const _kPeekTabWidth = 22.0;
  static const _kPeekTabHeight = 72.0;

  final double sidePanelRatio;
  final ResolvedHorizontalSplit Function({
    required double totalWidth,
    required double sideWidth,
  })
  resolve;
  final ValueChanged<double> onSidePanelRatioChanged;
  final bool collapsed;
  final ValueChanged<bool> onCollapsedChanged;
  final Widget sidePane;
  final Widget mainPane;
  final String expandSemanticLabel;
  final String collapseSemanticLabel;
  final FResizableDividerStyleDelta? style;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          tween: Tween<double>(
            begin: collapsed ? 0 : 1,
            end: collapsed ? 0 : 1,
          ),
          builder: (context, t, _) {
            if (t >= 1) return _buildExpanded(context);
            if (t <= 0) return _buildCollapsed(context);
            return _buildCollapsing(context, totalWidth, t);
          },
        );
      },
    );
  }

  Widget _buildExpanded(BuildContext context) {
    return PersistedHorizontalSplitPane(
      sidePanelRatio: sidePanelRatio,
      resolve: resolve,
      onSidePanelRatioChanged: onSidePanelRatioChanged,
      sidePane: sidePane,
      mainPane: mainPane,
      sideRegionIndex: 0,
      style: style,
    );
  }

  Widget _buildCollapsing(BuildContext context, double totalWidth, double t) {
    final resolved = resolve(
      totalWidth: totalWidth,
      sideWidth: sidePanelRatio * totalWidth,
    );
    final sideContent = FCollapsible(
      axis: Axis.horizontal,
      value: t,
      child: SizedBox(
        width: resolved.sideExtent,
        child: sidePane,
      ),
    );

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        children: [
          sideContent,
          Expanded(child: mainPane),
        ],
      ),
    );
  }

  Widget _buildCollapsed(BuildContext context) {
    final tab = _HadithPeekTab(
      icon: FLucideIcons.panelLeftOpen,
      semanticLabel: expandSemanticLabel,
      onPress: () => onCollapsedChanged(false),
    );

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        children: [
          tab,
          Expanded(child: mainPane),
        ],
      ),
    );
  }
}

class _HadithPeekTab extends StatelessWidget {
  const _HadithPeekTab({
    required this.icon,
    required this.semanticLabel,
    required this.onPress,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    const radius = Radius.circular(8);

    return SizedBox(
      width: _HadithCollapsibleSplitLayout._kPeekTabWidth,
      child: Align(
        child: FTappable(
          semanticsLabel: semanticLabel,
          onPress: onPress,
          builder: (context, variants, _) {
            final active =
                variants.contains(FTappableVariant.hovered) ||
                variants.contains(FTappableVariant.pressed);
            return Container(
              width: _HadithCollapsibleSplitLayout._kPeekTabWidth,
              height: _HadithCollapsibleSplitLayout._kPeekTabHeight,
              decoration: BoxDecoration(
                color: active ? colors.secondary : colors.muted,
                border: Border.all(color: colors.border),
                borderRadius: const BorderRadius.only(
                  topRight: radius,
                  bottomRight: radius,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.barrier.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 16,
                color: active ? colors.foreground : colors.mutedForeground,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SidePanel extends ConsumerWidget {
  const _SidePanel({
    required this.onCollapse,
    required this.collapseSemanticLabel,
  });

  final VoidCallback onCollapse;
  final String collapseSemanticLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedHadith = ref.watch(
      hadithSelectorProvider.select((value) => value.value),
    );
    final activeTabValue = ref.watch(hadithActiveTabProvider);
    final isSearchMode = ref.watch(hadithIsSearchModeProvider);
    final theme = context.theme;
    final l10n = context.l10n;

    var tabIndex = isSearchMode
        ? activeTabValue.index
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
          child: LazyIndexedContent(
            selectedIndex: tabIndex,
            index: HadithPanelTab.filters.index,
            builder: () => const _FilterPanel(),
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
                      .read(hadithScreenControllerProvider.notifier)
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
  const _SidePanelCollapseHandle({
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
