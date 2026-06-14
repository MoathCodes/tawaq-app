/// Split-pane extent math shared by Hadith, Quran study, and Fortress layouts.
library;

import 'dart:math' as math;

import 'package:forui/forui.dart' show FResizable;

import 'package:forui/widgets/resizable.dart' show FResizable;

/// Minimum width for study / filter side panels.
const kStudyPanelMinExtent = 320.0;

/// Minimum width for primary content panes (results, mushaf area).
const kMainPaneMinExtent = 480.0;

/// Minimum width reserved for the mushaf reading pane in study mode.
const kMushafPaneMinExtent = 400.0;

/// Slack required between pane minimums and [totalWidth] so [FResizable] can
/// initialize (Forui asserts `extent.min < extent.max` per region).
const kResizableSplitSlack = 1.0;

/// Resolved initial extents for a two-pane horizontal split.
class SplitExtents {
  /// Creates resolved split extents.
  const SplitExtents({
    required this.sideExtent,
    required this.mainExtent,
  });

  /// Width allocated to the side (study / filter) pane.
  final double sideExtent;

  /// Width allocated to the main content pane.
  final double mainExtent;
}

/// Resolves side and main pane widths so their sum never exceeds [totalWidth].
///
/// Clamps a persisted [sideWidth] against [sideMin], [mainMin], and optional
/// caps. Unlike naive `(totalWidth - sideWidth).clamp(mainMin, …)` math, this
/// never inflates the main pane past the space left by the side pane.
SplitExtents resolveSplitExtents({
  required double totalWidth,
  required double sideWidth,
  required double sideMin,
  required double mainMin,
  double? mainMax,
  double? sideMax,
}) {
  if (totalWidth <= 0) {
    return const SplitExtents(sideExtent: 0, mainExtent: 0);
  }

  final minimumTotal = sideMin + mainMin;
  if (totalWidth < minimumTotal) {
    final sideExtent = totalWidth * sideMin / minimumTotal;
    return SplitExtents(
      sideExtent: sideExtent,
      mainExtent: totalWidth - sideExtent,
    );
  }

  final maxSide = totalWidth - mainMin;
  var sideExtent = sideWidth.clamp(sideMin, maxSide);
  if (sideMax != null) {
    sideExtent = math.min(sideExtent, sideMax);
  }

  var mainExtent = totalWidth - sideExtent;
  if (mainMax != null && mainExtent > mainMax) {
    mainExtent = mainMax;
    sideExtent = (totalWidth - mainExtent).clamp(sideMin, maxSide);
    if (sideMax != null) {
      sideExtent = math.min(sideExtent, sideMax);
    }
    mainExtent = totalWidth - sideExtent;
  }

  return SplitExtents(
    sideExtent: sideExtent,
    mainExtent: mainExtent,
  );
}

/// Normalized extents and minimums safe to pass to [FResizable].
typedef ResizableSplitLayout = ({
  double sideExtent,
  double mainExtent,
  double sideMin,
  double mainMin,
});

/// Adjusts [sideMin]/[mainMin] so Forui's resizable regions satisfy
/// `extent.min < extent.max`, keeping [sideExtent]/[mainExtent] when possible.
///
/// This is needed when a narrow container makes the clamped minimum widths sum
/// to the full available width (e.g. side 280 + main 271 = 551).
ResizableSplitLayout normalizeSplitExtentsForResizable({
  required double totalWidth,
  required double sideExtent,
  required double mainExtent,
  required double sideMin,
  required double mainMin,
}) {
  if (totalWidth <= 0) {
    return (sideExtent: 0, mainExtent: 0, sideMin: 0, mainMin: 0);
  }

  var normalizedSideMin = sideMin;
  var normalizedMainMin = mainMin;
  final minTotal = normalizedSideMin + normalizedMainMin;
  final maxMinTotal = math.max(0, totalWidth - kResizableSplitSlack);

  if (minTotal > maxMinTotal && minTotal > 0) {
    final scale = maxMinTotal / minTotal;
    normalizedSideMin *= scale;
    normalizedMainMin *= scale;
  }

  var normalizedSideExtent = sideExtent;
  var normalizedMainExtent = mainExtent;

  if (normalizedSideExtent < normalizedSideMin ||
      normalizedMainExtent < normalizedMainMin) {
    final extents = resolveSplitExtents(
      totalWidth: totalWidth,
      sideWidth: normalizedSideExtent,
      sideMin: normalizedSideMin,
      mainMin: normalizedMainMin,
    );
    normalizedSideExtent = extents.sideExtent;
    normalizedMainExtent = extents.mainExtent;
  } else if ((normalizedSideExtent + normalizedMainExtent - totalWidth).abs() >
      0.5) {
    normalizedMainExtent = totalWidth - normalizedSideExtent;
    if (normalizedMainExtent < normalizedMainMin) {
      normalizedMainExtent = normalizedMainMin;
      normalizedSideExtent = totalWidth - normalizedMainExtent;
    }
    if (normalizedSideExtent < normalizedSideMin) {
      normalizedSideExtent = normalizedSideMin;
      normalizedMainExtent = totalWidth - normalizedSideExtent;
    }
  }

  return (
    sideExtent: normalizedSideExtent,
    mainExtent: normalizedMainExtent,
    sideMin: normalizedSideMin,
    mainMin: normalizedMainMin,
  );
}
