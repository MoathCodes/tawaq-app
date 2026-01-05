/// Semantic spacing tokens for consistent spacing throughout the app.
///
/// Use these values with `context.edgeInsets()`, `context.verticalSpace()`,
/// and `context.horizontalSpace()` from flutter_screenutil_plus.
///
/// Example:
/// ```dart
/// Padding(
///   padding: context.edgeInsets(all: AppSpacing.lg),
///   child: Column(
///     children: [
///       Text('Hello'),
///       context.verticalSpace(AppSpacing.md),
///       Text('World'),
///     ],
///   ),
/// )
/// ```
library;

/// Spacing tokens for the application.
///
/// These are raw double values intended to be used with flutter_screenutil_plus
/// context extensions which handle responsive scaling automatically.
abstract final class AppSpacing {
  /// Extra small spacing: 4.0
  static const double xs = 4;

  /// Small spacing: 8.0
  static const double sm = 8;

  /// Medium spacing: 12.0
  static const double md = 12;

  /// Large spacing: 16.0
  static const double lg = 16;

  /// Extra large spacing: 24.0
  static const double xl = 24;

  /// Extra extra large spacing: 32.0
  static const double xxl = 32;

  /// Triple extra large spacing: 48.0
  static const double xxxl = 48;
}
