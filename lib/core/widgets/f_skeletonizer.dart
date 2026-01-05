import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// A Forui-themed wrapper around the Skeletonizer widget.
///
/// This widget provides a themed skeleton loading experience that integrates
/// seamlessly with the Forui design system, using FColors for consistent
/// skeleton appearance across the application.
///
/// ## Usage Examples:
///
/// ### Basic usage:
/// ```dart
/// FSkeletonizer(
///   enabled: isLoading,
///   child: MyWidget(),
/// )
/// ```
///
/// ### With custom effect:
/// ```dart
/// FSkeletonizer.shimmer(
///   enabled: isLoading,
///   duration: Duration(milliseconds: 800),
///   child: MyWidget(),
/// )
/// ```
///
/// ### Pulse effect:
/// ```dart
/// FSkeletonizer.pulse(
///   enabled: isLoading,
///   child: MyWidget(),
/// )
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
  ///
  /// When false, the original [child] is displayed without any skeleton effect.
  final bool enabled;

  /// The skeleton effect to apply.
  ///
  /// If null, a default shimmer effect using Forui colors will be created.
  final PaintingEffect? effect;

  /// Whether to ignore container widgets when applying the skeleton effect.
  ///
  /// When true, containers (like Container, Card, etc.) won't be skeletonized.
  final bool ignoreContainers;

  /// Whether to ignore pointer events on the skeletonized widget.
  ///
  /// When true, the skeleton widget won't respond to touch events.
  final bool ignorePointers;

  /// Whether to justify multi-line text in skeleton mode.
  ///
  /// When true, multi-line text will be justified for a more realistic skeleton appearance.
  final bool justifyMultiLineText;

  /// The border radius for text bone elements.
  ///
  /// If null, a default border radius will be used.
  final BorderRadiusGeometry? textBoneBorderRadius;

  /// The color to use for container elements in skeleton mode.
  ///
  /// If null, the Forui theme's muted color will be used.
  final Color? containersColor;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }

    final theme = FTheme.of(context);
    final colors = theme.colors;

    // Create a default shimmer effect if none provided
    final skeletonizerEffect =
        effect ?? ShimmerEffect(baseColor: colors.secondary);

    return Skeletonizer(
      enabled: enabled,
      effect: skeletonizerEffect,
      ignoreContainers: ignoreContainers,
      ignorePointers: ignorePointers,
      justifyMultiLineText: justifyMultiLineText,
      containersColor: containersColor ?? colors.muted,
      child: child,
    );
  }

  /// Creates an FSkeletonizer with a fade-like effect using Forui colors.
  static Widget fade({
    required Widget child,
    Key? key,
    bool enabled = true,
    bool ignoreContainers = false,
    bool ignorePointers = true,
    bool justifyMultiLineText = true,
    BorderRadiusGeometry? textBoneBorderRadius,
    Color? containersColor,
    Duration duration = const Duration(milliseconds: 800),
  }) {
    return Builder(
      builder: (context) {
        final colors = FTheme.of(context).colors;

        return FSkeletonizer(
          key: key,
          enabled: enabled,
          effect: ShimmerEffect(
            baseColor: colors.muted,
            highlightColor: colors.mutedForeground.withValues(alpha: 0.1),
            duration: duration,
          ),
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

  /// Creates an FSkeletonizer with a pulse effect using Forui colors.
  static Widget pulse({
    required Widget child,
    Key? key,
    bool enabled = true,
    bool ignoreContainers = false,
    bool ignorePointers = true,
    bool justifyMultiLineText = true,
    BorderRadiusGeometry? textBoneBorderRadius,
    Color? containersColor,
    Duration duration = const Duration(milliseconds: 1000),
  }) {
    return Builder(
      builder: (context) {
        final colors = FTheme.of(context).colors;

        return FSkeletonizer(
          key: key,
          enabled: enabled,
          effect: PulseEffect(
            from: colors.muted,
            to: colors.mutedForeground.withValues(alpha: 0.2),
            duration: duration,
          ),
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

  /// Creates an FSkeletonizer with a custom shimmer effect using Forui colors.
  static Widget shimmer({
    required Widget child,
    Key? key,
    bool enabled = true,
    bool ignoreContainers = false,
    bool ignorePointers = true,
    bool justifyMultiLineText = true,
    BorderRadiusGeometry? textBoneBorderRadius,
    Color? containersColor,
    Duration duration = const Duration(milliseconds: 1200),
    Color? baseColor,
    Color? highlightColor,
  }) {
    return Builder(
      builder: (context) {
        final colors = FTheme.of(context).colors;

        return FSkeletonizer(
          key: key,
          enabled: enabled,
          effect: ShimmerEffect(
            baseColor: baseColor ?? colors.muted,
            highlightColor:
                highlightColor ?? colors.mutedForeground.withValues(alpha: 0.3),
            duration: duration,
          ),
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
}
