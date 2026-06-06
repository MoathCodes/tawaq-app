import 'package:flutter/material.dart';
import 'package:forui/widgets/badge.dart';

/// A badge that displays an icon and a label.
class IconBadge extends StatelessWidget {
  /// Creates an icon badge.
  const IconBadge({
    required this.label,
    required this.icon,
    super.key,
    this.style,
    this.spacing = 8,
  });

  /// The text to display in the badge.
  final Widget label;

  /// The icon to display in the badge.
  final Widget icon;

  /// The spacing between the icon and the label.
  final double spacing;

  /// The style of the badge.
  final FBadgeStyleDelta? style;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: FBadge(
        style: style ?? const .context(),
        child: Row(
          spacing: spacing,
          children: [
            icon,
            label,
          ],
        ),
      ),
    );
  }
}
