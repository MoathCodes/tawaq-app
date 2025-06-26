import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

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
      this.width = 140,
      this.height = 80,
      this.spacing = 8,
      this.padding = const EdgeInsets.all(8)});

  @override
  Widget build(BuildContext context) {
    return OutlinedContainer(
      width: width.w,
      height: height.h,
      borderColor:
          Theme.of(context).colorScheme.secondaryForeground.withAlpha(55),
      padding: padding,
      child: Column(
          spacing: spacing,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [Text(label).muted.small.bold, child]),
    );
  }
}
