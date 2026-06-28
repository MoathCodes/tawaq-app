import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/theme/theme.dart';

/// Shared horizontal progress bar for prayer analytics metrics.
class AnalysisMetricBar extends StatelessWidget {
  const AnalysisMetricBar({
    required this.value,
    required this.color,
    required this.backgroundColor,
    this.minHeight = 8,
    super.key,
  });

  final double value;
  final Color color;
  final Color backgroundColor;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final radius = context.theme.radii.full;
    final fillFactor = value.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: minHeight,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: backgroundColor),
            FractionallySizedBox(
              widthFactor: fillFactor,
              alignment: AlignmentDirectional.centerStart,
              child: ColoredBox(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
