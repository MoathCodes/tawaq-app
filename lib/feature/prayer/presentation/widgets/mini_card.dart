import 'package:flumpose/flumpose.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:forui/forui.dart';

class MiniCard extends StatelessWidget {
  const MiniCard({
    required this.label, required this.child, super.key,
    this.width = 120,
    this.height = 90,
    this.spacing = 8,
    this.padding = const EdgeInsets.all(8),
  });
  final String label;
  final double width;
  final double height;
  final double spacing;
  final EdgeInsets padding;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final typography = theme.typography;

    return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: typography.xs,
            ).bold(),
            child,
          ],
        )
        .decorateWithPadding(
          padding: padding,
          builder: (d) => d.circular(8).color(theme.colors.background),
        )
        .width(width == 0 ? 20 : width.w)
        .height(height == 0 ? 20 : height.h);
  }
}
