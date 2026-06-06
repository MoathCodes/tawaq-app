import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/utils/scaled_screen_util.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/theme/theme.dart';

/// Pill-shaped widget showing the Hijri date.
class HijriDatePill extends ConsumerWidget {
  /// Creates a [HijriDatePill].
  const HijriDatePill({required this.hijriDate, super.key});

  /// The async Hijri date string to display.
  final AsyncValue<String> hijriDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appScale = ref.watch(appTextScaleFactorProvider);
    final theme = FTheme.of(context);
    final l10n = context.l10n;
    final dateLabel = switch (hijriDate) {
      AsyncData<String>(:final value) => value,
      _ => l10n.loading,
    };

    return Semantics(
      label: dateLabel,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: theme.colors.background.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Icon(
                FLucideIcons.calendar,
                color: Colors.white.withValues(alpha: 0.8),
                size: scaledSp(14, appScale),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              dateLabel,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: scaledSp(12, appScale),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
