/// Semantic spacing tokens for consistent spacing throughout the app.
///
/// Use with [EdgeInsets], [SizedBox], or Forui widget padding.
///
/// Example:
/// ```dart
/// Padding(
///   padding: const EdgeInsets.all(AppSpacing.lg),
///   child: Column(
///     children: [
///       Text('Hello'),
///       SizedBox(height: AppSpacing.md),
///       Text('World'),
///     ],
///   ),
/// )
/// ```
library;

import 'package:flutter/cupertino.dart' show EdgeInsets, SizedBox;
import 'package:flutter/material.dart' show EdgeInsets, SizedBox;
import 'package:flutter/widgets.dart' show EdgeInsets, SizedBox;

/// Spacing tokens for the application.
///
/// Fixed logical-pixel values; responsive layout uses Forui breakpoints
/// (`lib/core/layout/responsive.dart`) rather than scaled spacing.
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
