import 'package:flutter/material.dart';
import 'package:hasanat/theme/spacing.dart';

/// A widget that displays an icon with a label.
class IconLabel extends StatelessWidget {
  /// Creates an [IconLabel].
  const IconLabel({required this.label, required this.icon, super.key});

  /// The text label.
  final String label;

  /// The icon to display.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: AppSpacing.sm,
      mainAxisAlignment: .center,
      children: [
        Icon(icon),
        Text(label),
      ],
    );
  }
}
