import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/layout/persisted_horizontal_split_pane.dart';
import 'package:tawaq/core/layout/split_pane_constraints.dart';
import 'package:tawaq/theme/theme.dart';

/// Width of the slim peek tab shown in place of a collapsed side pane.
const double _kPeekTabWidth = 22;

/// Height of the peek tab pill.
const double _kPeekTabHeight = 72;

/// Inset of the overlaid collapse button from the pane's top inner corner.
const double _kCollapseButtonInset = AppSpacing.md;

/// Where the collapse affordance is rendered for an expanded side pane.
enum CollapsePlacement {
  /// Overlays a compact collapse button on the side pane's divider edge.
  overlay,

  /// No built-in collapse button — the side pane supplies its own (e.g. header).
  none,
}

/// A [PersistedHorizontalSplitPane] that can collapse its side pane along the
/// horizontal axis.
///
/// When expanded it renders the resizable split with a compact collapse button
/// overlaid on the side pane's top inner (divider-side) corner, so it reads as
/// part of the pane's own header chrome instead of a separate strip. Collapsing
/// animates the side content out with [FCollapsible] (horizontal) and leaves a
/// slim, vertically-centred peek tab to bring it back. Both affordances are
/// mirrored for the physical side the pane lives on (via [sideRegionIndex]).
class CollapsibleHorizontalSplitPane extends StatelessWidget {
  /// Creates a collapsible horizontal split pane.
  const CollapsibleHorizontalSplitPane({
    required this.sidePanelRatio,
    required this.resolve,
    required this.onSidePanelRatioChanged,
    required this.collapsed,
    required this.onCollapsedChanged,
    required this.sidePane,
    required this.mainPane,
    required this.sideRegionIndex,
    required this.expandSemanticLabel,
    required this.collapseSemanticLabel,
    this.collapsePlacement = CollapsePlacement.overlay,
    this.style,
    this.floatingButtonOffset = const (top: 0, left: 0, right: 0),
    super.key,
  });

  /// See [PersistedHorizontalSplitPane.sidePanelRatio].
  final double sidePanelRatio;

  /// See [PersistedHorizontalSplitPane.resolve].
  final ResolvedHorizontalSplit Function({
    required double totalWidth,
    required double sideWidth,
  })
  resolve;

  /// See [PersistedHorizontalSplitPane.onSidePanelRatioChanged].
  final ValueChanged<double> onSidePanelRatioChanged;

  /// Whether the side pane is currently collapsed.
  final bool collapsed;

  /// Called with the desired collapsed state when the user toggles the handle.
  final ValueChanged<bool> onCollapsedChanged;

  /// See [PersistedHorizontalSplitPane.sidePane].
  final Widget sidePane;

  /// See [PersistedHorizontalSplitPane.mainPane].
  final Widget mainPane;

  /// See [PersistedHorizontalSplitPane.sideRegionIndex].
  final int sideRegionIndex;

  /// Accessibility label for the expand affordance.
  final String expandSemanticLabel;

  /// Accessibility label for the collapse affordance.
  final String collapseSemanticLabel;

  /// Placement of the collapse affordance when the side pane is expanded.
  final CollapsePlacement collapsePlacement;

  /// See [PersistedHorizontalSplitPane.style].
  final FResizableDividerStyleDelta? style;

  /// Offsets to edit the position of the floating button when the panel isn't
  /// collapsed.
  final ({double top, double left, double right}) floatingButtonOffset;

  /// Feature split layout (Hadith, Quran study, Fortress).
  ///
  /// Assumes the container already satisfies [canUseHorizontalSplit].
  factory CollapsibleHorizontalSplitPane.feature({
    required double sidePanelRatio,
    required bool collapsed,
    required ValueChanged<bool> onCollapsedChanged,
    required ValueChanged<double> onSidePanelRatioChanged,
    required Widget sidePane,
    required Widget mainPane,
    required String expandSemanticLabel,
    required String collapseSemanticLabel,
    bool sideOnStart = true,
    double sideMin = kStudyPanelMinExtent,
    double mainMin = kMainPaneMinExtent,
    double? sideMaxFraction,
    double? sideMaxPixels,
    double spacer = 0,
    CollapsePlacement collapsePlacement = CollapsePlacement.overlay,
    ({double top, double left, double right}) floatingButtonOffset =
        const (top: 0, left: 0, right: 0),
    FResizableDividerStyleDelta? style,
    Key? key,
  }) {
    final sideRegionIndex = sideOnStart ? 0 : 1;
    return CollapsibleHorizontalSplitPane(
      key: key,
      sidePanelRatio: sidePanelRatio,
      sideRegionIndex: sideRegionIndex,
      collapsed: collapsed,
      onCollapsedChanged: onCollapsedChanged,
      expandSemanticLabel: expandSemanticLabel,
      collapseSemanticLabel: collapseSemanticLabel,
      collapsePlacement: collapsePlacement,
      floatingButtonOffset: floatingButtonOffset,
      style: style,
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

  /// Whether the side pane sits on the physical left edge.
  bool get _sideOnLeft => sideRegionIndex == 0;

  bool get _showOverlayCollapse => collapsePlacement == CollapsePlacement.overlay;

  Widget _wrapSidePane(Widget side) {
    if (!_showOverlayCollapse) return side;
    return _sideWithCollapseButton(side);
  }

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

  /// Overlays the compact collapse button on the side pane's top inner corner
  /// (the divider edge) so it sits within the pane's own header chrome without
  /// reserving a separate strip or overlapping start-aligned header content.
  Widget _sideWithCollapseButton(Widget side) {
    return Stack(
      children: [
        Positioned.fill(child: side),
        Positioned(
          top: _kCollapseButtonInset + floatingButtonOffset.top,
          left: _sideOnLeft
              ? null
              : _kCollapseButtonInset + floatingButtonOffset.left,
          right: _sideOnLeft
              ? _kCollapseButtonInset + floatingButtonOffset.right
              : null,
          child: _CollapseHandle(
            icon: _sideOnLeft
                ? FLucideIcons.panelLeftClose
                : FLucideIcons.panelRightClose,
            semanticLabel: collapseSemanticLabel,
            sideOnLeft: _sideOnLeft,
            onPress: () => onCollapsedChanged(true),
          ),
        ),
      ],
    );
  }

  Widget _buildExpanded(BuildContext context) {
    return PersistedHorizontalSplitPane(
      sidePanelRatio: sidePanelRatio,
      resolve: resolve,
      onSidePanelRatioChanged: onSidePanelRatioChanged,
      sidePane: _wrapSidePane(sidePane),
      mainPane: mainPane,
      sideRegionIndex: sideRegionIndex,
      style: style ?? splitPaneDividerStyle(context),
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
        child: _wrapSidePane(sidePane),
      ),
    );

    final children = _sideOnLeft
        ? [sideContent, Expanded(child: mainPane)]
        : [Expanded(child: mainPane), sideContent];

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(children: children),
    );
  }

  Widget _buildCollapsed(BuildContext context) {
    final tab = _PeekTab(
      icon: _sideOnLeft
          ? FLucideIcons.panelLeftOpen
          : FLucideIcons.panelRightOpen,
      semanticLabel: expandSemanticLabel,
      // Round the corners that face the main content (the inner edge).
      innerOnLeft: !_sideOnLeft,
      onPress: () => onCollapsedChanged(false),
    );

    final children = _sideOnLeft
        ? [tab, Expanded(child: mainPane)]
        : [Expanded(child: mainPane), tab];

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(children: children),
    );
  }
}

/// Compact, clearly-visible collapse button overlaid on the pane header chrome.
class _CollapseHandle extends StatelessWidget {
  const _CollapseHandle({
    required this.icon,
    required this.semanticLabel,
    required this.sideOnLeft,
    required this.onPress,
  });

  final IconData icon;
  final String semanticLabel;
  final bool sideOnLeft;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return FTooltip(
      tipBuilder: (_, _) => Text(semanticLabel),
      childAnchor: sideOnLeft ? Alignment.centerRight : Alignment.centerLeft,
      tipAnchor: sideOnLeft ? Alignment.centerLeft : Alignment.centerRight,
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
          child: Icon(icon, size: 18),
        ),
      ),
    );
  }
}

/// Slim, vertically-centred tab that peeks from the edge when the side pane is
/// collapsed; tapping it re-expands the pane.
class _PeekTab extends StatelessWidget {
  const _PeekTab({
    required this.icon,
    required this.semanticLabel,
    required this.innerOnLeft,
    required this.onPress,
  });

  final IconData icon;
  final String semanticLabel;

  /// Whether the content-facing (inner) edge is on the left, which determines
  /// the corners that are rounded.
  final bool innerOnLeft;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    const radius = Radius.circular(8);
    final borderRadius = innerOnLeft
        ? const BorderRadius.only(topLeft: radius, bottomLeft: radius)
        : const BorderRadius.only(topRight: radius, bottomRight: radius);

    return SizedBox(
      width: _kPeekTabWidth,
      child: Align(
        child: FTooltip(
          tipBuilder: (_, _) => Text(semanticLabel),
          childAnchor: innerOnLeft
              ? Alignment.centerLeft
              : Alignment.centerRight,
          tipAnchor: innerOnLeft ? Alignment.centerRight : Alignment.centerLeft,
          child: FTappable(
            semanticsLabel: semanticLabel,
            onPress: onPress,
            builder: (context, variants, _) {
              final active =
                  variants.contains(FTappableVariant.hovered) ||
                  variants.contains(FTappableVariant.pressed);
              return Container(
                width: _kPeekTabWidth,
                height: _kPeekTabHeight,
                decoration: BoxDecoration(
                  color: active ? colors.secondary : colors.muted,
                  border: Border.all(color: colors.border),
                  borderRadius: borderRadius,
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
      ),
    );
  }
}
