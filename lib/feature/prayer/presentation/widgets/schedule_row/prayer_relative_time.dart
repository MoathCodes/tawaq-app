import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/prayer/data/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/domain/use_cases/compute_prayer_relative_time.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_data_providers.dart';

/// Live relative-time label; rebuilds on the clock tick without rebuilding rows.
class PrayerRelativeTimeSubtitle extends ConsumerWidget {
  /// Creates a relative-time subtitle.
  const PrayerRelativeTimeSubtitle({
    required this.prayerTime,
    required this.status,
    required this.isToday,
    required this.isCurrentPrayer,
    super.key,
  });

  /// Prayer instant used for relative-time math.
  final DateTime prayerTime;

  /// Logged completion status for this prayer.
  final CompletionStatus status;

  /// Whether the schedule row is for today (live clock) vs a past day.
  final bool isToday;

  /// Whether this row is the active obligatory prayer.
  final bool isCurrentPrayer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FTheme.of(context);
    final colors = theme.colors;
    final l10n = context.l10n;

    final now = isToday
        ? ref.watch(currentLocationTimeProvider)
        : DateTime(prayerTime.year, prayerTime.month, prayerTime.day);

    final subtitle = computePrayerRelativeTime(
      prayerTime: prayerTime,
      now: now,
      isCurrentPrayer: isCurrentPrayer,
      status: status,
      l10n: l10n,
    );

    if (subtitle == null) {
      return const SizedBox.shrink();
    }

    return Text(
      subtitle,
      style: theme.typography.sm.copyWith(
        color: isCurrentPrayer ? colors.primary : colors.mutedForeground,
      ),
    );
  }
}
