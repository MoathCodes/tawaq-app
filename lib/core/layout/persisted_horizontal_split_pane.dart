import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/layout/split_pane_constraints.dart';

export 'package:tawaq/core/layout/split_pane_constraints.dart'
    show ResolvedHorizontalSplit;

/// A horizontal [FResizable] split whose regions stay stable across parent
/// rebuilds.
///
/// [FResizable] resets pane sizes whenever its [FResizableRegion] children are
/// recreated. Feature screens rebuild often (live clocks, async data, etc.),
/// so this widget caches region instances and only recreates them when the
/// persisted width or container constraints actually change — not while the
/// user is dragging.
class PersistedHorizontalSplitPane extends StatefulWidget {
  /// Creates a persisted horizontal split pane.
  const PersistedHorizontalSplitPane({
    required this.sidePanelRatio,
    required this.resolve,
    required this.onSidePanelRatioChanged,
    required this.sidePane,
    required this.mainPane,
    required this.sideRegionIndex,
    this.style,
    super.key,
  });

  /// Persisted width of the side pane as a fraction of the total width (0..1).
  ///
  /// The pane keeps this share of the container as it resizes, capped by the
  /// `sideMax` returned from [resolve]; beyond the cap the main pane absorbs the
  /// extra space.
  final double sidePanelRatio;

  /// Resolves extents and minimums for the current container width.
  ///
  /// [sideWidth] is the desired side width in logical pixels, derived from
  /// [sidePanelRatio] and the live container width.
  final ResolvedHorizontalSplit Function({
    required double totalWidth,
    required double sideWidth,
  })
  resolve;

  /// Called with the new side-pane ratio (0..1) when the user finishes resizing.
  final ValueChanged<double> onSidePanelRatioChanged;

  /// Content shown in the side (study / filter / browse) pane.
  final Widget sidePane;

  /// Content shown in the main pane.
  final Widget mainPane;

  /// Index of [sidePane] among [FResizable] children (`0` or `1`).
  final int sideRegionIndex;

  /// Optional divider style. Defaults to the theme context style.
  final FResizableDividerStyleDelta? style;

  @override
  State<PersistedHorizontalSplitPane> createState() =>
      _PersistedHorizontalSplitPaneState();
}

class _PersistedHorizontalSplitPaneState
    extends State<PersistedHorizontalSplitPane> {
  List<FResizableRegion>? _regions;
  int? _cachedSideFlex;
  int? _cachedMainFlex;
  int? _cachedSideMinFlex;
  int? _cachedMainMinFlex;
  int? _cachedSideRegionIndex;
  double? _cachedTotalWidth;
  bool _dragging = false;
  Widget? _cachedSidePane;
  Widget? _cachedMainPane;

  // The region widgets are cached (see [_syncRegionsIfNeeded]) so [FResizable]
  // keeps stable extents across the frequent parent rebuilds. Because those
  // cached regions are reference-identical, Flutter would otherwise skip
  // rebuilding their subtrees and freeze the pane contents. Injecting the live
  // panes through notifiers lets the pane subtrees rebuild on their own when
  // the content changes, without recreating the regions (which resets extents).
  final ValueNotifier<Widget> _sidePaneNotifier = ValueNotifier(
    const SizedBox.shrink(),
  );
  final ValueNotifier<Widget> _mainPaneNotifier = ValueNotifier(
    const SizedBox.shrink(),
  );

  @override
  void dispose() {
    _sidePaneNotifier.dispose();
    _mainPaneNotifier.dispose();
    super.dispose();
  }

  void _syncRegionsIfNeeded({
    required double totalWidth,
    required int sideFlex,
    required int mainFlex,
    required int sideMinFlex,
    required int mainMinFlex,
  }) {
    final totalWidthChanged =
        _cachedTotalWidth != null && _cachedTotalWidth != totalWidth;
    if (_dragging) {
      if (!totalWidthChanged) {
        return;
      }
      _dragging = false;
    }
    _cachedTotalWidth = totalWidth;

    if (_regions != null &&
        _cachedSideFlex == sideFlex &&
        _cachedMainFlex == mainFlex &&
        _cachedSideMinFlex == sideMinFlex &&
        _cachedMainMinFlex == mainMinFlex &&
        _cachedSideRegionIndex == widget.sideRegionIndex) {
      return;
    }

    _cachedSideFlex = sideFlex;
    _cachedMainFlex = mainFlex;
    _cachedSideMinFlex = sideMinFlex;
    _cachedMainMinFlex = mainMinFlex;
    _cachedSideRegionIndex = widget.sideRegionIndex;

    final sideRegion = FResizableRegion.flex(
      key: const ValueKey('persisted-split-side'),
      flex: sideFlex,
      minFlex: sideMinFlex,
      builder: (_, _, _) => ValueListenableBuilder<Widget>(
        valueListenable: _sidePaneNotifier,
        builder: (_, pane, _) => pane,
      ),
    );
    final mainRegion = FResizableRegion.flex(
      key: const ValueKey('persisted-split-main'),
      flex: mainFlex,
      minFlex: mainMinFlex,
      builder: (_, _, _) => ValueListenableBuilder<Widget>(
        valueListenable: _mainPaneNotifier,
        builder: (_, pane, _) => pane,
      ),
    );

    _regions = widget.sideRegionIndex == 0
        ? [sideRegion, mainRegion]
        : [mainRegion, sideRegion];
  }

  bool _paneChanged(Widget? cached, Widget next) {
    return !identical(cached, next) || cached?.key != next.key;
  }

  void _syncPaneNotifiers() {
    if (_paneChanged(_cachedSidePane, widget.sidePane)) {
      _cachedSidePane = widget.sidePane;
      _sidePaneNotifier.value = widget.sidePane;
    }
    if (_paneChanged(_cachedMainPane, widget.mainPane)) {
      _cachedMainPane = widget.mainPane;
      _mainPaneNotifier.value = widget.mainPane;
    }
  }

  @override
  Widget build(BuildContext context) {
    _syncPaneNotifiers();

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final desiredSideWidth = widget.sidePanelRatio * totalWidth;
        final resolved = widget.resolve(
          totalWidth: totalWidth,
          sideWidth: desiredSideWidth,
        );
        final layout = normalizeSplitExtentsForResizable(
          totalWidth: totalWidth,
          sideExtent: resolved.sideExtent,
          mainExtent: resolved.mainExtent,
          sideMin: resolved.sideMin,
          mainMin: resolved.mainMin,
        );

        if (layout.sideExtent <= 0 || layout.mainExtent <= 0) {
          return widget.mainPane;
        }

        // Flex regions distribute the available width as flex / totalFlex, so
        // rounded pixel extents reproduce the capped proportions. Recreating
        // regions when these change re-applies the cap on window resize.
        final sideFlex = math.max(1, layout.sideExtent.round());
        final mainFlex = math.max(1, layout.mainExtent.round());
        final sideMinFlex = layout.sideMin.round().clamp(1, sideFlex);
        final mainMinFlex = layout.mainMin.round().clamp(1, mainFlex);

        _syncRegionsIfNeeded(
          totalWidth: totalWidth,
          sideFlex: sideFlex,
          mainFlex: mainFlex,
          sideMinFlex: sideMinFlex,
          mainMinFlex: mainMinFlex,
        );

        return Directionality(
          textDirection: TextDirection.ltr,
          child: FResizable(
            axis: Axis.horizontal,
            style: widget.style ?? const FResizableDividerStyleDelta.context(),
            control: FResizableControl.managed(
              onResizeUpdate: (_) {
                if (!_dragging) {
                  setState(() => _dragging = true);
                }
              },
              onResizeEnd: (value) {
                final sideData = value[widget.sideRegionIndex];
                final reResolved = widget.resolve(
                  totalWidth: totalWidth,
                  sideWidth: sideData.extent.current,
                );
                final normalized = normalizeSplitExtentsForResizable(
                  totalWidth: totalWidth,
                  sideExtent: reResolved.sideExtent,
                  mainExtent: reResolved.mainExtent,
                  sideMin: reResolved.sideMin,
                  mainMin: reResolved.mainMin,
                );
                setState(() => _dragging = false);
                final ratio = totalWidth > 0
                    ? (normalized.sideExtent / totalWidth).clamp(0.0, 1.0)
                    : widget.sidePanelRatio;
                widget.onSidePanelRatioChanged(ratio);
              },
            ),
            children: _regions!,
          ),
        );
      },
    );
  }
}
