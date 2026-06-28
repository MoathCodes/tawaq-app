import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/layout/collapsible_horizontal_split_pane.dart';
import 'package:tawaq/core/layout/feature_split_pane.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/layout/hadith_main_column.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/layout/hadith_side_panel.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/theme/theme.dart';

/// Desktop Hadith layout with a collapsible side panel and main results column.
class HadithSplitLayout extends ConsumerWidget {
  /// Creates the split layout.
  const HadithSplitLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = ref.watch(hadithScreenUiProvider);
    final textDirection = Directionality.of(context);
    final l10n = context.l10n;

    return FeatureSplitPane(
      sidePanelRatio: ui.sidePanelRatio,
      collapsed: ui.sidePanelCollapsed,
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
          end: ui.sidePanelCollapsed ? 0 : AppSpacing.sm,
        ),
        child: Directionality(
          textDirection: textDirection,
          child: HadithSidePanel(
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
          child: const HadithMainColumn(),
        ),
      ),
    );
  }
}
