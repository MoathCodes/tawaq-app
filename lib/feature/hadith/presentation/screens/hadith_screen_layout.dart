part of 'hadith_screen.dart';

class _DesktopSplitLayout extends ConsumerWidget {
  const _DesktopSplitLayout();

  static const _minSidePanelWidth = 320.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sidePanelWidth = ref.watch(hadithSidePanelWidthProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final mainPaneWidth = (constraints.maxWidth - sidePanelWidth).clamp(
          480.0,
          1200.0,
        );

        return Directionality(
          textDirection: TextDirection.ltr,
          child: FResizable(
            axis: Axis.horizontal,
            style: const .delta(
              thumbStyle: .delta(
                decoration: .boxDelta(
                  border: .fromBorderSide(.new(color: Colors.transparent)),
                ),
              ),
            ),
            control: .managed(
              onResizeEnd: (value) {
                ref
                    .read(hadithScreenControllerProvider.notifier)
                    .setSidePanelWidth(
                      value[0].extent.current,
                    );
              },
            ),
            children: [
              FResizableRegion.region(
                initialExtent: sidePanelWidth,
                minExtent: _minSidePanelWidth,
                builder: (_, _, _) => Padding(
                  padding: const EdgeInsetsDirectional.only(
                    end: AppSpacing.sm,
                  ),
                  child: Directionality(
                    textDirection: Directionality.of(context),
                    child: const SizedBox.expand(
                      child: _SidePanel(),
                    ),
                  ),
                ),
              ),
              FResizableRegion.region(
                initialExtent: mainPaneWidth,
                minExtent: 480,
                builder: (_, _, _) => Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: AppSpacing.sm,
                  ),
                  child: Directionality(
                    textDirection: Directionality.of(context),
                    child: const Column(
                      children: [
                        _SearchHeader(
                          desktop: true,
                          groupId: HadithPage._filterPopoverGroupId,
                        ),
                        SizedBox(height: AppSpacing.lg),
                        Expanded(
                          child: _ResultsList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
