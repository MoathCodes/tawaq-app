import 'package:flutter/material.dart';

/// Theme extension for consistent animation durations.
///
/// Access via `context.theme.durations` after adding the convenience extension.
///
/// Example:
/// ```dart
/// AnimatedContainer(
///   duration: context.theme.durations.normal,
///   // ...
/// )
/// ```
class AppDurations extends ThemeExtension<AppDurations> {
  /// Creates an [AppDurations] instance with the given duration values.
  const AppDurations({
    required this.instant,
    required this.fast,
    required this.normal,
    required this.slow,
    required this.slower,
  });

  /// Default duration values.
  const AppDurations.standard()
    : instant = const Duration(milliseconds: 50),
      fast = const Duration(milliseconds: 150),
      normal = const Duration(milliseconds: 260),
      slow = const Duration(milliseconds: 400),
      slower = const Duration(milliseconds: 600);

  /// Instant/micro interaction: 50ms
  final Duration instant;

  /// Fast animation: 150ms
  final Duration fast;

  /// Normal animation: 260ms
  final Duration normal;

  /// Slow animation: 400ms
  final Duration slow;

  /// Slower animation: 600ms
  final Duration slower;

  @override
  AppDurations copyWith({
    Duration? instant,
    Duration? fast,
    Duration? normal,
    Duration? slow,
    Duration? slower,
  }) {
    return AppDurations(
      instant: instant ?? this.instant,
      fast: fast ?? this.fast,
      normal: normal ?? this.normal,
      slow: slow ?? this.slow,
      slower: slower ?? this.slower,
    );
  }

  @override
  AppDurations lerp(AppDurations? other, double t) {
    if (other == null) return this;
    // Durations don't interpolate smoothly, so we snap at 0.5
    return t < 0.5 ? this : other;
  }
}
