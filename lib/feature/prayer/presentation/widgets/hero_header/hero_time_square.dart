import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/prayer_semantics.dart';
import 'package:tawaq/theme/theme.dart';

/// Visual density for [HeroTimeSquare] inside the hero header.
enum HeroTimeSquareDensity {
  /// Full padding and typography for wide hero cards.
  normal,

  /// Reduced padding for horizontal layouts (~540–1024 px).
  compact,

  /// Tightest layout for very narrow cards.
  ultraCompact,
}

/// Displays a time value with an optional label (e.g., "ADHAN" / "IQAMAH")
/// inside the hero header.
class HeroTimeSquare extends StatelessWidget {
  /// Creates a [HeroTimeSquare].
  const HeroTimeSquare({
    required this.time,
    required this.label,
    this.density = HeroTimeSquareDensity.normal,
    super.key,
  });

  /// The formatted time string to display.
  final String time;

  /// The label above the time (e.g., "ADHAN"). Null hides the label.
  final String? label;

  /// Layout density; derived from the hero card's allocated width.
  final HeroTimeSquareDensity density;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final (horizontal, vertical, labelStyle, timeStyle, minWidth) = switch (
      density
    ) {
      HeroTimeSquareDensity.normal => (
        AppSpacing.xl,
        AppSpacing.lg,
        theme.typography.sm,
        theme.typography.xl2,
        112.0,
      ),
      HeroTimeSquareDensity.compact => (
        AppSpacing.lg,
        AppSpacing.md,
        theme.typography.xs,
        theme.typography.xl,
        96.0,
      ),
      HeroTimeSquareDensity.ultraCompact => (
        AppSpacing.sm,
        AppSpacing.xs,
        theme.typography.xs,
        theme.typography.lg,
        80.0,
      ),
    };

    return Semantics(
      label: PrayerSemantics.heroTimeSquare(time: time, caption: label),
      readOnly: true,
      excludeSemantics: true,
      child: Container(
        constraints: BoxConstraints(minWidth: minWidth),
        padding: EdgeInsets.symmetric(
          horizontal: horizontal,
          vertical: vertical,
        ),
        decoration: BoxDecoration(
          color: theme.colors.background.withValues(alpha: 0.2),
          borderRadius: theme.radii.md,
          border: Border.all(
            color: theme.colors.border.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label != null)
              Text(
                label!.toUpperCase(),
                style: labelStyle.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            if (label != null) const SizedBox(height: AppSpacing.xs),
            Text(
              time,
              style: timeStyle.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
