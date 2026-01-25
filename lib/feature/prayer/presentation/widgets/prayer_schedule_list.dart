import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/utils/date_formatter.dart';
import 'package:hasanat/core/widgets/f_skeletonizer.dart';
import 'package:hasanat/feature/prayer/data/models/prayer_completion.dart';
import 'package:hasanat/feature/prayer/domain/services/prayer_service.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_completion_provider.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_data_providers.dart';
import 'package:hasanat/feature/prayer/presentation/widgets/schedule_prayer_row.dart';
import 'package:hasanat/theme/theme.dart';

/// Today's prayer schedule with expandable status selectors.
class PrayerScheduleList extends ConsumerWidget {
  /// Creates a [PrayerScheduleList] instance.
  const PrayerScheduleList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FTheme.of(context);
    final service = ref.watch(prayerServiceProvider);
    final prayerTimes = ref.watch(currentPrayerTimesProvider());
    final now = ref.watch(currentLocationTimeProvider);
    final formatter = ref.watch(timeFormatterProvider);

    final completions = ref.watch(prayerCompletionProvider);
    final completionMap = completions.maybeWhen(
      data: (list) => {for (final c in list) c.prayer: c},
      orElse: () => <Prayer, PrayerCompletion>{},
    );

    final currentPrayer = service.currentPrayer(prayerTimes);
    final today = DateTime(now.year, now.month, now.day);

    // List of prayers to display
    const prayers = [
      Prayer.fajr,
      Prayer.sunrise,
      Prayer.dhuhr,
      Prayer.asr,
      Prayer.maghrib,
      Prayer.isha,
      Prayer.fajrAfter, // Midnight
      Prayer.ishaBefore, // Last Third
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.todaysSchedule,
                  style: theme.typography.lg.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  context.l10n.selectPrayerToLog,
                  style: theme.typography.sm.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Prayer rows
          completions.when(
            data: (_) => Column(
              children: prayers.map((prayer) {
                final time = prayerTimes.timeForPrayer(prayer);
                final isActive = prayer == currentPrayer;
                final completion = completionMap[prayer];
                final status = completion?.status ?? CompletionStatus.none;

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: SchedulePrayerRow(
                    prayer: prayer,
                    adhanTime: formatter.format(time),
                    prayerTime: time,
                    isActive: isActive,
                    isCompleted: status != CompletionStatus.none,
                    currentStatus: status,
                    completionTime: today,
                  ),
                );
              }).toList(),
            ),
            loading: () => FSkeletonizer(
              child: Column(
                children: List.generate(
                  8,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: theme.colors.secondary,
                        borderRadius: context.theme.radii.md,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            error: (e, _) => FAlert(
              title: Text(context.l10n.errorOccurredWhile('Loading schedule')),
              subtitle: Text(e.toString()),
            ),
          ),
        ],
      ),
    );
  }
}
