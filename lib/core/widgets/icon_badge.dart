import 'package:flutter/material.dart';
import 'package:forui/widgets/badge.dart';

class IconBadge extends StatelessWidget {
  final Widget label;
  final Widget icon;
  final double spacing;
  final FBaseBadgeStyle Function(FBadgeStyle)? style;
  const IconBadge({
    super.key,
    required this.label,
    this.style,
    required this.icon,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return FBadge(
        style: style ?? FBadgeStyle.primary(),
        child: Row(
          spacing: spacing,
          children: [
            icon,
            label,
          ],
        ));
  }
}
