import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/utils/text_extensions.dart';

class MiniCard extends StatelessWidget {
  final String label;
  final double width;
  final double height;
  final double spacing;
  final EdgeInsetsGeometry padding;

  final Widget child;
  const MiniCard(
      {super.key,
      required this.label,
      required this.child,
      this.width = 120,
      this.height = 90,
      this.spacing = 8,
      this.padding = const EdgeInsets.all(8)});

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final typography = theme.typography;
    return Container(
      padding: padding,
      width: width == 0 ? null : width.w,
      height: height == 0 ? null : height.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: theme.colors.background,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: typography.xs,
          ).bold,
          child,
        ],
      ),
    );
  }
}
