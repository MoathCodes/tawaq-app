import 'package:flutter/material.dart';
import 'package:hasanat/theme/spacing.dart';

class IconLabel extends StatelessWidget {
  const IconLabel({required this.label, required this.icon, super.key});
  final String label;
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
