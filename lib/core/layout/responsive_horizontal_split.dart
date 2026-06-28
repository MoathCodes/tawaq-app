import 'package:flutter/material.dart';
import 'package:tawaq/core/layout/split_pane_constraints.dart';

/// Builds split or stacked layouts based on [canUseHorizontalSplit].
///
/// Replaces duplicated gating in Hadith, Quran study, and Fortress screens.
class ResponsiveHorizontalSplitGate extends StatelessWidget {
  /// Creates a responsive horizontal split gate.
  const ResponsiveHorizontalSplitGate({
    required this.sideMin,
    required this.mainMin,
    required this.builder,
    this.spacer = 0,
    super.key,
  });

  /// Minimum width for the side pane.
  final double sideMin;

  /// Minimum width for the main pane.
  final double mainMin;

  /// Space subtracted from total width before gating (e.g. divider padding).
  final double spacer;

  /// Receives [useSplit] when the container can honor horizontal split mins.
  final Widget Function(BuildContext context, bool useSplit) builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useSplit = canUseHorizontalSplit(
          containerWidth: constraints.maxWidth,
          sideMin: sideMin,
          mainMin: mainMin,
          spacer: spacer,
        );
        return builder(context, useSplit);
      },
    );
  }
}
