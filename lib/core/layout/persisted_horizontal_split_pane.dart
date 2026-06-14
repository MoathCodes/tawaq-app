import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/layout/split_pane_constraints.dart';

/// Resolved layout extents for [PersistedHorizontalSplitPane].
typedef ResolvedHorizontalSplit = ({
  double sideExtent,
  double mainExtent,
  double sideMin,
  double mainMin,
});

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
    required this.sidePanelWidth,
    required this.resolve,
    required this.onSidePanelWidthChanged,
    required this.sidePane,
    required this.mainPane,
    required this.sideRegionIndex,
    this.style,
    super.key,
  });

  /// Persisted width of the side pane, in logical pixels.
  final double sidePanelWidth;

  /// Resolves extents and minimums for the current container width.
  final ResolvedHorizontalSplit Function({
    required double totalWidth,
    required double sideWidth,
  })
  resolve;

  /// Called when the user finishes resizing the split.
  final ValueChanged<double> onSidePanelWidthChanged;

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
  double? _cachedSideExtent;
  double? _cachedMainExtent;
  double? _cachedSideMin;
  double? _cachedMainMin;
  int? _cachedSideRegionIndex;
  double? _cachedTotalWidth;
  bool _dragging = false;

  void _syncRegionsIfNeeded({
    required double totalWidth,
    required double sideExtent,
    required double mainExtent,
    required double sideMin,
    required double mainMin,
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
        _cachedSideExtent == sideExtent &&
        _cachedMainExtent == mainExtent &&
        _cachedSideMin == sideMin &&
        _cachedMainMin == mainMin &&
        _cachedSideRegionIndex == widget.sideRegionIndex) {
      return;
    }

    _cachedSideExtent = sideExtent;
    _cachedMainExtent = mainExtent;
    _cachedSideMin = sideMin;
    _cachedMainMin = mainMin;
    _cachedSideRegionIndex = widget.sideRegionIndex;

    final sideRegion = FResizableRegion.region(
      key: const ValueKey('persisted-split-side'),
      initialExtent: sideExtent,
      minExtent: sideMin,
      builder: (_, _, _) => widget.sidePane,
    );
    final mainRegion = FResizableRegion.region(
      key: const ValueKey('persisted-split-main'),
      initialExtent: mainExtent,
      minExtent: mainMin,
      builder: (_, _, _) => widget.mainPane,
    );

    _regions = widget.sideRegionIndex == 0
        ? [sideRegion, mainRegion]
        : [mainRegion, sideRegion];
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final resolved = widget.resolve(
          totalWidth: totalWidth,
          sideWidth: widget.sidePanelWidth,
        );
        final layout = normalizeSplitExtentsForResizable(
          totalWidth: totalWidth,
          sideExtent: resolved.sideExtent,
          mainExtent: resolved.mainExtent,
          sideMin: resolved.sideMin,
          mainMin: resolved.mainMin,
        );

        if (layout.sideExtent <= 0 || layout.mainExtent <= 0) {
          return const SizedBox.shrink();
        }

        _syncRegionsIfNeeded(
          totalWidth: totalWidth,
          sideExtent: layout.sideExtent,
          mainExtent: layout.mainExtent,
          sideMin: layout.sideMin,
          mainMin: layout.mainMin,
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
                widget.onSidePanelWidthChanged(normalized.sideExtent);
              },
            ),
            children: _regions!,
          ),
        );
      },
    );
  }
}
