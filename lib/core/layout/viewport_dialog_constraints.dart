/// Viewport-aware [BoxConstraints] for dialogs and sheets.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// Builds [BoxConstraints] that respect the current viewport size.
///
/// [preferredWidth] and [preferredHeight] are upper-bounded by
/// [maxWidthFraction] / [maxHeightFraction] of the viewport. [minWidth] is
/// clamped so it never exceeds the computed maximum width.
BoxConstraints dialogConstraints(
  BuildContext context, {
  double? preferredWidth,
  double? preferredHeight,
  double? minWidth,
  double maxWidthFraction = 0.9,
  double maxHeightFraction = 0.85,
}) {
  final size = MediaQuery.sizeOf(context);
  final viewportMaxWidth = size.width * maxWidthFraction;
  final viewportMaxHeight = size.height * maxHeightFraction;

  final resolvedMaxWidth = preferredWidth != null
      ? math.min(preferredWidth, viewportMaxWidth)
      : viewportMaxWidth;
  final resolvedMaxHeight = preferredHeight != null
      ? math.min(preferredHeight, viewportMaxHeight)
      : viewportMaxHeight;

  final resolvedMinWidth = minWidth != null
      ? math.min(minWidth, resolvedMaxWidth)
      : 0.0;

  return BoxConstraints(
    minWidth: resolvedMinWidth,
    maxWidth: resolvedMaxWidth,
    maxHeight: resolvedMaxHeight,
  );
}

/// Viewport-aware [FPortalConstraints] for select/popover dropdowns.
///
/// Uses [FAutoWidthPortalConstraints] so the menu width follows the trigger
/// field (Forui's default). Only [maxHeight] is clamped to the viewport —
/// fixed-width constraints make [FSelect.searchBuilder]'s search field expand
/// to the viewport max width, which stretches dropdowns on wide layouts.
FPortalConstraints selectPopoverPortalConstraints(
  BuildContext context, {
  double maxHeight = 300,
  double maxHeightFraction = 0.85,
}) {
  final viewportMaxHeight =
      MediaQuery.sizeOf(context).height * maxHeightFraction;

  return FAutoWidthPortalConstraints(
    maxHeight: math.min(maxHeight, viewportMaxHeight),
  );
}
