import 'package:flutter/material.dart';

/// Theme extension for consistent border radius values.
///
/// Access via `context.theme.radii` after adding the convenience extension.
///
/// Example:
/// ```dart
/// Container(
///   decoration: BoxDecoration(
///     borderRadius: context.theme.radii.md,
///   ),
/// )
/// ```
class AppRadii extends ThemeExtension<AppRadii> {
  /// Creates an [AppRadii] instance with the given border radius values.
  const new({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.full,
  });

  /// Default radii values.
  const new standard()
    : xs = const BorderRadius.all(Radius.circular(2)),
      sm = const BorderRadius.all(Radius.circular(4)),
      md = const BorderRadius.all(Radius.circular(8)),
      lg = const BorderRadius.all(Radius.circular(12)),
      xl = const BorderRadius.all(Radius.circular(16)),
      full = const BorderRadius.all(Radius.circular(9999));

  /// Extra small radius: 2px
  final BorderRadius xs;

  /// Small radius: 4px
  final BorderRadius sm;

  /// Medium radius: 8px
  final BorderRadius md;

  /// Large radius: 12px
  final BorderRadius lg;

  /// Extra large radius: 16px
  final BorderRadius xl;

  /// Full/pill radius: 9999px
  final BorderRadius full;

  @override
  AppRadii copyWith({
    BorderRadius? xs,
    BorderRadius? sm,
    BorderRadius? md,
    BorderRadius? lg,
    BorderRadius? xl,
    BorderRadius? full,
  }) {
    return AppRadii(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      full: full ?? this.full,
    );
  }

  @override
  AppRadii lerp(AppRadii? other, double t) {
    if (other == null) return this;
    return AppRadii(
      xs: BorderRadius.lerp(xs, other.xs, t)!,
      sm: BorderRadius.lerp(sm, other.sm, t)!,
      md: BorderRadius.lerp(md, other.md, t)!,
      lg: BorderRadius.lerp(lg, other.lg, t)!,
      xl: BorderRadius.lerp(xl, other.xl, t)!,
      full: BorderRadius.lerp(full, other.full, t)!,
    );
  }
}
