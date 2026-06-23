/// Forui-native responsive helpers replacing `flutter_screenutil_plus` queries.
library;

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// Named Forui breakpoint tiers (Tailwind defaults: sm 640, md 768, …).
enum FBreakpoint {
  /// Small — viewport width ≥ 640 logical px.
  sm,

  /// Medium — viewport width ≥ 768 logical px.
  md,

  /// Large — viewport width ≥ 1024 logical px.
  lg,

  /// Extra large — viewport width ≥ 1280 logical px.
  xl,

  /// 2XL — viewport width ≥ 1536 logical px.
  xl2,
}

/// Resolves the pixel threshold for a breakpoint tier.
extension FBreakpointThreshold on FBreakpoint {
  /// Minimum viewport width (inclusive) for this tier.
  double threshold(FBreakpoints breakpoints) => switch (this) {
    FBreakpoint.sm => breakpoints.sm,
    FBreakpoint.md => breakpoints.md,
    FBreakpoint.lg => breakpoints.lg,
    FBreakpoint.xl => breakpoints.xl,
    FBreakpoint.xl2 => breakpoints.xl2,
  };
}

/// Current viewport width in logical pixels.
double contentWidth(BuildContext context) =>
    MediaQuery.sizeOf(context).width;

/// Whether the viewport is at least [tier] wide.
bool isAtLeast(BuildContext context, FBreakpoint tier) {
  final width = contentWidth(context);
  final breakpoints = context.theme.breakpoints;
  return width >= tier.threshold(breakpoints);
}

/// Whether the viewport is narrower than [tier].
bool isLessThan(BuildContext context, FBreakpoint tier) =>
    !isAtLeast(context, tier);

/// Whether an allocated layout width (e.g. inside [LayoutBuilder]) is at least
/// [tier] wide.
bool isContainerAtLeast(
  BuildContext context,
  BoxConstraints constraints,
  FBreakpoint tier,
) {
  final breakpoints = context.theme.breakpoints;
  return constraints.maxWidth >= tier.threshold(breakpoints);
}

T _pickResponsiveValue<T>(List<T?> tiers) {
  for (final tier in tiers) {
    if (tier != null) return tier;
  }
  throw StateError('responsiveValue requires at least one tier value');
}

/// Picks a value for the current viewport using Forui breakpoint tiers.
///
/// Values cascade from larger tiers down (e.g. [lg] falls back to [md] then
/// [sm]). Viewports below 640px use [belowSm].
T responsiveValue<T>(
  BuildContext context, {
  T? belowSm,
  T? sm,
  T? md,
  T? lg,
  T? xl,
  T? xl2,
}) {
  final width = contentWidth(context);
  final breakpoints = context.theme.breakpoints;

  if (width >= breakpoints.xl2) {
    return _pickResponsiveValue([xl2, xl, lg, md, sm, belowSm]);
  }
  if (width >= breakpoints.xl) {
    return _pickResponsiveValue([xl, lg, md, sm, belowSm]);
  }
  if (width >= breakpoints.lg) {
    return _pickResponsiveValue([lg, md, sm, belowSm]);
  }
  if (width >= breakpoints.md) {
    return _pickResponsiveValue([md, sm, belowSm]);
  }
  if (width >= breakpoints.sm) {
    return _pickResponsiveValue([sm, belowSm]);
  }
  return _pickResponsiveValue([belowSm, sm, md, lg, xl, xl2]);
}

/// Picks a value for an allocated layout width using Forui breakpoint tiers.
///
/// Same cascade rules as [responsiveValue], but uses [width] instead of the
/// viewport — for split panes, sidebars, and other container-scoped layouts.
T responsiveValueForWidth<T>(
  BuildContext context,
  double width, {
  T? belowSm,
  T? sm,
  T? md,
  T? lg,
  T? xl,
  T? xl2,
}) {
  final breakpoints = context.theme.breakpoints;

  if (width >= breakpoints.xl2) {
    return _pickResponsiveValue([xl2, xl, lg, md, sm, belowSm]);
  }
  if (width >= breakpoints.xl) {
    return _pickResponsiveValue([xl, lg, md, sm, belowSm]);
  }
  if (width >= breakpoints.lg) {
    return _pickResponsiveValue([lg, md, sm, belowSm]);
  }
  if (width >= breakpoints.md) {
    return _pickResponsiveValue([md, sm, belowSm]);
  }
  if (width >= breakpoints.sm) {
    return _pickResponsiveValue([sm, belowSm]);
  }
  return _pickResponsiveValue([belowSm, sm, md, lg, xl, xl2]);
}

/// Column count for a container of [maxWidth].
int responsiveColumnCount(
  BuildContext context,
  double maxWidth, {
  required int maxColumns,
  int minColumns = 1,
}) {
  final breakpoints = context.theme.breakpoints;
  final min = minColumns.clamp(1, maxColumns);
  if (maxWidth < breakpoints.sm) return min;
  if (maxWidth < breakpoints.md) {
    final mid = maxColumns >= 2 ? 2 : min;
    return mid.clamp(min, maxColumns);
  }
  return maxColumns;
}
