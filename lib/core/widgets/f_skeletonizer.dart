import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Skeleton effect type for [FSkeletonizer].
enum SkeletonEffectType { shimmer, pulse, fade }

/// A Forui-themed wrapper around the Skeletonizer widget.
///
/// Provides a themed skeleton loading experience that integrates
/// seamlessly with the Forui design system.
///
/// ## Usage:
/// ```dart
/// FSkeletonizer(enabled: isLoading, child: MyWidget())
/// FSkeletonizer.withEffect(SkeletonEffectType.pulse, child: MyWidget())
/// ```
class FSkeletonizer extends StatelessWidget {
  /// Creates a Forui-themed skeleton loader.
  const FSkeletonizer({
    required this.child,
    super.key,
    this.enabled = true,
    this.effect,
    this.ignoreContainers = false,
    this.ignorePointers = true,
    this.justifyMultiLineText = true,
    this.textBoneBorderRadius,
    this.containersColor,
  });

  /// The widget to be skeletonized when [enabled] is true.
  final Widget child;

  /// Whether the skeleton effect is enabled.
  final bool enabled;

  /// The skeleton effect to apply.
  final PaintingEffect? effect;

  /// Whether to ignore container widgets when applying the skeleton effect.
  final bool ignoreContainers;

  /// Whether to ignore pointer events on the skeletonized widget.
  final bool ignorePointers;

  /// Whether to justify multi-line text in skeleton mode.
  final bool justifyMultiLineText;

  /// The border radius for text bone elements.
  final BorderRadiusGeometry? textBoneBorderRadius;

  /// The color to use for container elements in skeleton mode.
  final Color? containersColor;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    final colors = FTheme.of(context).colors;
    return Skeletonizer(
      enabled: enabled,
      effect: effect ?? ShimmerEffect(baseColor: colors.secondary),
      ignoreContainers: ignoreContainers,
      ignorePointers: ignorePointers,
      justifyMultiLineText: justifyMultiLineText,
      containersColor: containersColor ?? colors.muted,
      child: child,
    );
  }

  /// Creates an FSkeletonizer with a specific effect type.
  static Widget withEffect(
    SkeletonEffectType type, {
    required Widget child,
    Key? key,
    bool enabled = true,
    bool ignoreContainers = false,
    bool ignorePointers = true,
    bool justifyMultiLineText = true,
    BorderRadiusGeometry? textBoneBorderRadius,
    Color? containersColor,
    Duration? duration,
    Color? baseColor,
    Color? highlightColor,
  }) {
    return Builder(
      builder: (context) {
        final colors = FTheme.of(context).colors;
        final base = baseColor ?? colors.muted;
        final highlight = highlightColor ?? colors.mutedForeground;

        final effect = switch (type) {
          SkeletonEffectType.shimmer => ShimmerEffect(
            baseColor: base,
            highlightColor: highlight.withValues(alpha: 0.3),
            duration: duration ?? const Duration(milliseconds: 1200),
          ),
          SkeletonEffectType.pulse => PulseEffect(
            from: base,
            to: highlight.withValues(alpha: 0.2),
            duration: duration ?? const Duration(milliseconds: 1000),
          ),
          SkeletonEffectType.fade => ShimmerEffect(
            baseColor: base,
            highlightColor: highlight.withValues(alpha: 0.1),
            duration: duration ?? const Duration(milliseconds: 800),
          ),
        };

        return FSkeletonizer(
          key: key,
          enabled: enabled,
          effect: effect,
          ignoreContainers: ignoreContainers,
          ignorePointers: ignorePointers,
          justifyMultiLineText: justifyMultiLineText,
          textBoneBorderRadius: textBoneBorderRadius,
          containersColor: containersColor,
          child: child,
        );
      },
    );
  }

  /// Shorthand for shimmer effect.
  static Widget shimmer({
    required Widget child,
    Key? key,
    bool enabled = true,
  }) => withEffect(
    SkeletonEffectType.shimmer,
    child: child,
    key: key,
    enabled: enabled,
  );

  /// Shorthand for pulse effect.
  static Widget pulse({required Widget child, Key? key, bool enabled = true}) =>
      withEffect(
        SkeletonEffectType.pulse,
        child: child,
        key: key,
        enabled: enabled,
      );

  /// Shorthand for fade effect.
  static Widget fade({required Widget child, Key? key, bool enabled = true}) =>
      withEffect(
        SkeletonEffectType.fade,
        child: child,
        key: key,
        enabled: enabled,
      );
}
