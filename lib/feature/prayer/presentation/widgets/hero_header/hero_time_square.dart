import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/utils/scaled_screen_util.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/prayer_semantics.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/theme/theme.dart';

/// Displays a time value with an optional label (e.g., "ADHAN" / "IQAMAH")
/// inside the hero header.
class HeroTimeSquare extends ConsumerWidget {
  /// Creates a [HeroTimeSquare].
  const HeroTimeSquare({required this.time, required this.label, super.key});

  /// The formatted time string to display.
  final String time;

  /// The label above the time (e.g., "ADHAN"). Null hides the label.
  final String? label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appScale = ref.watch(appTextScaleFactorProvider);
    final theme = FTheme.of(context);
    return Semantics(
      label: PrayerSemantics.heroTimeSquare(time: time, caption: label),
      readOnly: true,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
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
                style: theme.typography.xs.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            const SizedBox(height: 6),
            Text(
              time,
              style: TextStyle(
                color: Colors.white,
                fontSize: scaledSp(24, appScale),
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
