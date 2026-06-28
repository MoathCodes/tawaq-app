import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/layout/collapsible_horizontal_split_pane.dart';
import 'package:tawaq/core/layout/split_pane_constraints.dart';
import 'package:tawaq/theme/theme.dart';

/// Horizontal split for Hadith, Quran study, and Fortress layouts.
///
/// This widget assumes the container already satisfies [canUseHorizontalSplit].
class FeatureSplitPane extends StatelessWidget {
  /// Creates a feature split pane.
  const FeatureSplitPane({
    required this.sidePanelRatio,
    required this.collapsed,
    required this.onCollapsedChanged,
    required this.onSidePanelRatioChanged,
    required this.sidePane,
    required this.mainPane,
    required this.expandSemanticLabel,
    required this.collapseSemanticLabel,
    this.sideOnStart = true,
    this.sideMin = kStudyPanelMinExtent,
    this.mainMin = kMainPaneMinExtent,
    this.sideMaxFraction,
    this.sideMaxPixels,
    this.spacer = 0,
    this.collapsePlacement = CollapsePlacement.overlay,
    this.floatingButtonOffset = const (top: 0, left: 0, right: 0),
    this.style,
    super.key,
  });

  /// Persisted side-pane width ratio (0..1).
  final double sidePanelRatio;

  /// Whether the side pane is collapsed.
  final bool collapsed;

  /// Called when the user toggles collapsed state.
  final ValueChanged<bool> onCollapsedChanged;

  /// Called when the user finishes resizing the side pane.
  final ValueChanged<double> onSidePanelRatioChanged;

  /// Side (study / filter / browse) pane content.
  final Widget sidePane;

  /// Main content pane.
  final Widget mainPane;

  /// Accessibility label for expanding the side pane.
  final String expandSemanticLabel;

  /// Accessibility label for collapsing the side pane.
  final String collapseSemanticLabel;

  /// When true, the side pane sits at the layout start (left in LTR).
  final bool sideOnStart;

  /// Minimum width for the side pane.
  final double sideMin;

  /// Minimum width for the main pane.
  final double mainMin;

  /// Optional maximum side width as a fraction of the container.
  final double? sideMaxFraction;

  /// Optional maximum side width in logical pixels.
  final double? sideMaxPixels;

  /// Space subtracted from total width before resolving extents.
  final double spacer;

  /// Where the collapse affordance is rendered.
  final CollapsePlacement collapsePlacement;

  /// Offset tweak for the overlay collapse button.
  final ({double top, double left, double right}) floatingButtonOffset;

  /// Optional divider style override.
  final FResizableDividerStyleDelta? style;

  int get _sideRegionIndex => sideOnStart ? 0 : 1;

  @override
  Widget build(BuildContext context) {
    return CollapsibleHorizontalSplitPane(
      sidePanelRatio: sidePanelRatio,
      sideRegionIndex: _sideRegionIndex,
      collapsed: collapsed,
      onCollapsedChanged: onCollapsedChanged,
      expandSemanticLabel: expandSemanticLabel,
      collapseSemanticLabel: collapseSemanticLabel,
      collapsePlacement: collapsePlacement,
      floatingButtonOffset: floatingButtonOffset,
      style: style ?? splitPaneDividerStyle(context),
      resolve: ({required totalWidth, required sideWidth}) =>
          resolveFeatureSplitExtents(
            totalWidth: totalWidth,
            sideWidth: sideWidth,
            sideMin: sideMin,
            mainMin: mainMin,
            sideMaxFraction: sideMaxFraction,
            sideMaxPixels: sideMaxPixels,
            spacer: spacer,
          ),
      onSidePanelRatioChanged: onSidePanelRatioChanged,
      sidePane: sidePane,
      mainPane: mainPane,
    );
  }
}
