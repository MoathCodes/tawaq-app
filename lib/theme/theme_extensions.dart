import 'package:forui/forui.dart';
import 'package:hasanat/theme/durations.dart';
import 'package:hasanat/theme/radii.dart';

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
}
