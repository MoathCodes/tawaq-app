import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/theme/durations.dart';
import 'package:tawaq/theme/radii.dart';
import 'package:tawaq/theme/tabs_styles.dart';

/// Convenience extension on [FThemeData] for accessing app design tokens.
///
/// Example:
/// ```dart
/// final radii = context.theme.radii;
/// final durations = context.theme.durations;
/// ```
extension AppTokensExtension on FThemeData {
  /// Access the [AppRadii] theme extension.
  AppRadii get radii => extension<AppRadii>();

  /// Access the [AppDurations] theme extension.
  AppDurations get durations => extension<AppDurations>();

  /// Access the [AppTabsStyles] theme extension.
  AppTabsStyles get tabs => extension<AppTabsStyles>();

  /// checks if the current theme is dark mode.
  bool get isDark => colors.brightness == .dark;
}

/// Shared transparent-thumb divider style for feature split panes.
FResizableDividerStyleDelta splitPaneDividerStyle(BuildContext context) {
  return const FResizableDividerStyleDelta.delta(
    thumbStyle: FResizableDividerThumbStyleDelta.delta(
      decoration: DecorationDelta.boxDelta(
        border: Border.fromBorderSide(BorderSide(color: Colors.transparent)),
      ),
    ),
  );
}
