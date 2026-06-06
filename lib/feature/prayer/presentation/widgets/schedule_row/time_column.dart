import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/theme/theme.dart';

/// Displays a time column with label (e.g., "ADHAN" / "IQAMAH") and time value.
class TimeColumn extends StatelessWidget {
  /// Creates a [TimeColumn].
  const TimeColumn({
    required this.label,
    required this.time,
    required this.theme,
    required this.colors,
    super.key,
  });

  /// The label above the time (e.g., "ADHAN").
  final String label;

  /// The formatted time value.
  final String time;

  /// Theme data for typography.
  final FThemeData theme;

  /// Theme colors for styling.
  final FColors colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label (ADHAN / IQAMAH)
        Text(
          label,
          style: theme.typography.xs.copyWith(
            color: colors.mutedForeground,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        // Time value
        Text(
          time,
          style: theme.typography.sm.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.foreground,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
