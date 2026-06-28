import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/layout/lazy_tab_content.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_persisted_settings.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/detail/hadith_detail_pane.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/filters/hadith_filter_panel.dart';
import 'package:tawaq/theme/theme.dart';

/// Collapsible side panel with details and filter tabs.
class HadithSidePanel extends ConsumerWidget {
  /// Creates the side panel.
  const HadithSidePanel({
    required this.onCollapse,
    required this.collapseSemanticLabel,
    super.key,
  });

  /// Called when the user collapses the panel from its header affordance.
  final VoidCallback onCollapse;

  /// Accessibility label for the collapse button.
  final String collapseSemanticLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedHadith = ref.watch(
      hadithScreenUiProvider.select((ui) => ui.selectedHadith),
    );
    final ui = ref.watch(hadithScreenUiProvider);
    final theme = context.theme;
    final l10n = context.l10n;

    var tabIndex = ui.isSearchMode
        ? ui.activeTab.index
        : HadithPanelTab.details.index;
    if (tabIndex < 0) {
      tabIndex = 0;
    } else if (ui.isSearchMode && tabIndex >= HadithPanelTab.values.length) {
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
      if (ui.isSearchMode)
        FTabEntry(
          label: Text(l10n.hadithFilterTab),
          child: LazyIndexedContent(
            selectedIndex: tabIndex,
            index: HadithPanelTab.filters.index,
            builder: () => const HadithFilterPanel(),
          ),
        ),
    ];

    if (!ui.isSearchMode) {
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
                  if (!ui.isSearchMode &&
                      index != HadithPanelTab.details.index) {
                    return;
                  }

                  ref
                      .read(hadithSessionControllerProvider.notifier)
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
