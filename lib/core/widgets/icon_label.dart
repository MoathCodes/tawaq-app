import 'package:flutter/material.dart';
import 'package:tawaq/theme/spacing.dart';

/// A widget that displays an icon with a label.
class IconLabel extends StatelessWidget {
  /// Creates an [IconLabel].
  const IconLabel({
    required this.label,
    required this.icon,
    this.excludeIconSemantics = false,
    super.key,
  });

  /// The text label.
  final String label;

  /// The icon to display.
  final IconData icon;

  /// When true, hides the icon from assistive technologies (label is announced).
  final bool excludeIconSemantics;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(icon);
    return Row(
      spacing: AppSpacing.sm,
      mainAxisAlignment: .center,
      children: [
        if (excludeIconSemantics)
          ExcludeSemantics(child: iconWidget)
        else
          iconWidget,
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
