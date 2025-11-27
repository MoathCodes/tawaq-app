import 'package:flumpose/flumpose.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:forui/forui.dart';

class MiniCard extends StatelessWidget {
  final String label;
  final double? height;
  final double? width;
  final double spacing;
  final EdgeInsets padding;
  final Widget child;

  const MiniCard({
    required this.label,
    required this.child,
    super.key,
    this.height,
    this.width,
    this.spacing = 4,
    this.padding = const .all(8),
  });

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final typography = theme.typography;

    return SizedBox(
      height: height ?? 80.h,
      width: width ?? 110.w,
      child:
          Column(
            mainAxisAlignment: .spaceEvenly,
            children: [
              Text(label, textAlign: .center, style: typography.xs).bold(),
              child,
            ],
          ).decorateWithPadding(
            padding: padding,
            builder: (d) => d.circular(8).color(theme.colors.background),
          ),
    );
  }
}
