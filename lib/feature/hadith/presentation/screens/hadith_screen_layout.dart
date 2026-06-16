part of 'hadith_screen.dart';

/// Resolved side/main pane widths for the hadith split layout.
({
  double sideExtent,
  double mainExtent,
  double sideMin,
  double mainMin,
  double sideMax,
}) _resolveHadithSplitExtents({
  required double totalWidth,
  required double sideWidth,
}) {
  if (totalWidth <= 0) {
    return (
      sideExtent: 0,
      mainExtent: 0,
      sideMin: 0,
      mainMin: 0,
      sideMax: 0,
    );
  }

  final sideMin = kStudyPanelMinExtent.clamp(0.0, totalWidth);
  final mainMin = kMainPaneMinExtent.clamp(0.0, totalWidth - sideMin);
  final sideMax = (totalWidth * 0.5).clamp(sideMin, totalWidth - mainMin);

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

class _DesktopSplitLayout extends ConsumerWidget {
  const _DesktopSplitLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sidePanelWidth = ref.watch(hadithSidePanelWidthProvider);
    final textDirection = Directionality.of(context);

    return PersistedHorizontalSplitPane(
      sidePanelWidth: sidePanelWidth,
      sideRegionIndex: 0,
      resolve: ({required totalWidth, required sideWidth}) {
        final resolved = _resolveHadithSplitExtents(
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
          .read(hadithScreenControllerProvider.notifier)
          .setSidePanelWidth(width),
      style: const .delta(
        thumbStyle: .delta(
          decoration: .boxDelta(
            border: .fromBorderSide(.new(color: Colors.transparent)),
          ),
        ),
      ),
      sidePane: Padding(
        padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
        child: Directionality(
          textDirection: textDirection,
          child: const _SidePanel(),
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

class _SidePanel extends ConsumerWidget {
  const _SidePanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedHadith = ref.watch(
      hadithSelectorProvider.select((value) => value.value),
    );
    final activeTabValue = ref.watch(hadithActiveTabProvider);
    final isSearchMode = ref.watch(hadithIsSearchModeProvider);
    final theme = context.theme;
    final l10n = context.l10n;

    final tabs = <FTabEntry>[
      FTabEntry(
        label: Text(l10n.hadithDetailsTab),
        child: selectedHadith == null
            ? Center(
                child: Text(
                  l10n.hadithNoDetailsSelected,
                  textAlign: TextAlign.center,
                  style: theme.typography.md.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
              )
            : HadithSelectedDetailsPane(hadith: selectedHadith),
      ),
      if (isSearchMode)
        FTabEntry(
          label: Text(l10n.hadithFilterTab),
          child: const _FilterPanel(),
        ),
    ];

    var tabIndex = isSearchMode
        ? activeTabValue.index
        : HadithPanelTab.details.index;
    if (tabIndex < 0) {
      tabIndex = 0;
    } else if (tabIndex >= tabs.length) {
      tabIndex = tabs.length - 1;
    }

    return FSidebar.raw(
      style: .delta(
        decoration: .boxDelta(
          border: .all(color: Colors.transparent),
        ),
      ),
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
    );
  }
}
