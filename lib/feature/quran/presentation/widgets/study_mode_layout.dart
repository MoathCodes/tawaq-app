import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/layout/collapsible_horizontal_split_pane.dart';
import 'package:tawaq/core/layout/responsive_horizontal_split.dart';
import 'package:tawaq/core/layout/side_panel_ui_state.dart';
import 'package:tawaq/core/layout/split_pane_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/study/study_panel.dart';
import 'package:tawaq/theme/theme.dart';

const _kResizableSpacer = 20.0;
const _kStudyPanelMaxExtent = 480.0;
const _kStackedStudyPanelMaxHeight = 360.0;

/// Study mode layout for the Quran reader with a side panel.
class StudyModeLayout extends ConsumerWidget {
  /// Creates a [StudyModeLayout] instance.
  const new({
    required this.mushaf,
    super.key,
  });

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
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        collapsed ? 0 : AppSpacing.lg,
        0,
        AppSpacing.lg,
        0,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : MediaQuery.sizeOf(context).height;

          return ResponsiveHorizontalSplitGate(
            sideMin: kStudyPanelMinExtent,
            mainMin: kMushafPaneMinExtent,
            spacer: _kResizableSpacer,
            builder: (context, useSplit) {
              if (!useSplit) {
                final studyHeight = _kStackedStudyPanelMaxHeight.clamp(
                  0.0,
                  totalHeight * 0.45,
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(
                          bottom: AppSpacing.sm,
                        ),
                        child: content,
                      ),
                    ),
                    SizedBox(
                      height: studyHeight,
                      child: panel,
                    ),
                  ],
                );
              }

              return _StudySplitAutoCollapse(
                containerWidth: constraints.maxWidth,
                collapsed: collapsed,
                child: CollapsibleHorizontalSplitPane.feature(
                  sidePanelRatio: sidePanelRatio,
                  collapsed: collapsed,
                  sideOnStart: !isRtl,
                  mainMin: kMushafPaneMinExtent,
                  sideMaxFraction: 0.45,
                  sideMaxPixels: _kStudyPanelMaxExtent,
                  spacer: _kResizableSpacer,
                  expandSemanticLabel: l10n.expandPanel,
                  collapseSemanticLabel: l10n.collapsePanel,
                  onCollapsedChanged: (value) => ref
                      .read(quranScreenSettingsProvider.notifier)
                      .setSidePanelCollapsed(collapsed: value),
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Collapses an expanded study side panel when the split area becomes tight.
class _StudySplitAutoCollapse extends HookConsumerWidget {
  const new({
    required this.containerWidth,
    required this.collapsed,
    required this.child,
  });

  final double containerWidth;
  final bool collapsed;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      if (collapsed) return null;
      final tightWidth = minSplitContainerWidth(
        sideMin: kStudyPanelMinExtent,
        mainMin: kMushafPaneMinExtent,
        spacer: _kResizableSpacer,
      );
      if (containerWidth < tightWidth + 64) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          ref
              .read(quranScreenSettingsProvider.notifier)
              .setSidePanelCollapsed(collapsed: true);
        });
      }
      return null;
    }, [containerWidth, collapsed]);

    return child;
  }
}
