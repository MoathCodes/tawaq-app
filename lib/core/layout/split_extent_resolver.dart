import 'dart:math' as math;

import 'package:tawaq/core/layout/persisted_horizontal_split_pane.dart';
import 'package:tawaq/core/layout/split_pane_constraints.dart';

/// Resolves side/main pane extents for feature split layouts.
///
/// Applies optional [spacer] before computing against [totalWidth], then clamps
/// [sideWidth] using [sideMin], [mainMin], and optional side caps expressed as
/// [sideMaxFraction] and/or [sideMaxPixels].
ResolvedHorizontalSplit resolveFeatureSplitExtents({
  required double totalWidth,
  required double sideWidth,
  required double sideMin,
  required double mainMin,
  double? sideMaxFraction,
  double? sideMaxPixels,
  double spacer = 0,
}) {
  final available = (totalWidth - spacer).clamp(0.0, double.infinity);
  if (available <= 0) {
    return (sideExtent: 0, mainExtent: 0, sideMin: 0, mainMin: 0);
  }

  final resolvedSideMin = sideMin.clamp(0.0, available);
  final resolvedMainMin = mainMin.clamp(0.0, available - resolvedSideMin);

  double? sideMax;
  if (sideMaxFraction != null || sideMaxPixels != null) {
    var maxSide = available - resolvedMainMin;
    if (sideMaxFraction != null) {
      maxSide = math.min(maxSide, available * sideMaxFraction);
    }
    if (sideMaxPixels != null) {
      maxSide = math.min(maxSide, sideMaxPixels);
    }
    sideMax = maxSide.clamp(resolvedSideMin, available - resolvedMainMin);
  }

  final extents = resolveSplitExtents(
    totalWidth: available,
    sideWidth: sideWidth,
    sideMin: resolvedSideMin,
    mainMin: resolvedMainMin,
    sideMax: sideMax,
  );

  return (
    sideExtent: extents.sideExtent,
    mainExtent: extents.mainExtent,
    sideMin: resolvedSideMin,
    mainMin: resolvedMainMin,
  );
}
