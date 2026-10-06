import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/layout/collapsible_horizontal_split_pane.dart';
import 'package:tawaq/core/layout/side_panel_ui_state.dart';
import 'package:tawaq/core/layout/split_pane_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';
import 'package:tawaq/feature/quran/presentation/hooks/quran_ayah_selection.dart';
import 'package:tawaq/feature/quran/presentation/widgets/study/study_panel.dart';
import 'package:tawaq/theme/theme.dart';

const _kResizableSpacer = 20.0;
const _kStudyPanelMaxExtent = 480.0;

/// Both panes need useful height as well as readable width.
bool quranStudyUsesSplit(BoxConstraints constraints) =>
    constraints.maxHeight >= 480 &&
    canUseHorizontalSplit(
      containerWidth: constraints.maxWidth - 2 * AppSpacing.lg,
      sideMin: kStudyPanelMinExtent,
      mainMin: kMushafPaneMinExtent,
      spacer: _kResizableSpacer,
    );

/// Study mode layout for the Quran reader with a side panel.
class StudyModeLayout extends ConsumerWidget {
  /// Creates a [StudyModeLayout] instance.
  const new({required this.mushaf, super.key});

  /// The shared mushaf reading pane.
  final Widget mushaf;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textDirection = Directionality.of(context);
    final isRtl = textDirection == TextDirection.rtl;

    final panel = RepaintBoundary(
      child: Directionality(
        textDirection: textDirection,
        child: const StudyPanel(),
      ),
    );

    final content = Center(child: mushaf);

    final sidePanelRatio = ref.watch(
      quranScreenSettingsProvider.select(
        (v) => v.value?.sidePanelRatio ?? SidePanelDefaults.quranRatio,
      ),
    );
    final collapsed = ref.watch(
      quranScreenSettingsProvider.select(
        (v) => v.value?.sidePanelCollapsed ?? SidePanelDefaults.collapsed,
      ),
    );
    final hasSelection = ref.watch(quranSelectedAyahIdProvider) != null;
    final effectivelyCollapsed = collapsed || !hasSelection;
    final l10n = context.l10n;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!quranStudyUsesSplit(constraints)) return content;
        return Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            effectivelyCollapsed ? 0 : AppSpacing.lg,
            0,
            AppSpacing.lg,
            0,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return CollapsibleHorizontalSplitPane.feature(
                sidePanelRatio: sidePanelRatio,
                collapsed: effectivelyCollapsed,
                sideOnStart: !isRtl,
                mainMin: kMushafPaneMinExtent,
                sideMaxFraction: 0.45,
                sideMaxPixels: _kStudyPanelMaxExtent,
                spacer: _kResizableSpacer,
                expandSemanticLabel: l10n.expandPanel,
                collapseSemanticLabel: l10n.collapsePanel,
                onCollapsedChanged: (value) {
                  if (value) {
                    ref
                        .read(quranScreenSettingsProvider.notifier)
                        .setSidePanelCollapsed(collapsed: true);
                  } else {
                    unawaited(revealQuranStudy(ref));
                  }
                },
                onSidePanelRatioChanged: (ratio) => ref
                    .read(quranScreenSettingsProvider.notifier)
                    .setSidePanelRatio(ratio),
                sidePane: Padding(
                  padding: EdgeInsetsDirectional.only(
                    end: isRtl ? 0 : AppSpacing.sm,
                    start: isRtl ? AppSpacing.sm : 0,
                  ),
                  child: panel,
                ),
                mainPane: Padding(
                  padding: EdgeInsetsDirectional.only(
                    end: isRtl ? AppSpacing.sm : 0,
                    start: isRtl ? 0 : AppSpacing.sm,
                  ),
                  child: content,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
