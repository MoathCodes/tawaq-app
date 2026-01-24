import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/theme/theme.dart';

/// A small card widget with a label and a child.
class MiniCard extends StatelessWidget {
  /// Creates a [MiniCard] instance.
  const MiniCard({
    required this.label,
    required this.child,
    super.key,
    this.height,
    this.width,
    this.spacing = AppSpacing.xs,
    this.padding = const EdgeInsets.all(AppSpacing.sm),
  });

  /// The label displayed at the top of the card.
  final String label;

  /// The height of the card.
  final double? height;

  /// The width of the card.
  final double? width;

  /// The spacing between the label and the child.
  final double spacing;

  /// The padding inside the card.
  final EdgeInsets padding;

  /// The child widget displayed below the label.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final colors = theme.colors;
    final typography = theme.typography;

    return SizedBox(
      height: height ?? 70.h,
      width: width ?? 100.w,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: colors.background,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          spacing: spacing,
          children: [
            // Label - muted and smaller for visual hierarchy
            Text(
              label,
              textAlign: TextAlign.center,
              style: typography.xs.copyWith(
                fontWeight: FontWeight.w500,
                color: colors.mutedForeground,
              ),
            ),
            // Value - larger and prominent
            DefaultTextStyle.merge(
              style: typography.base.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.foreground,
              ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
