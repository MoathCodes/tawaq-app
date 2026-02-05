import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_completion_provider.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_data_providers.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_schedule/prayer_schedule_provider.dart';
import 'package:hasanat/feature/prayer/presentation/widgets/schedule_prayer_row.dart';
import 'package:hasanat/theme/theme.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

/// Today's prayer schedule with expandable status selectors.
/// Users can navigate back up to a week to view and edit prayer statuses.
class PrayerScheduleList extends HookConsumerWidget {
  /// Creates a [PrayerScheduleList] instance.
  const PrayerScheduleList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FTheme.of(context);
    final l10n = context.l10n;
    final now = ref.watch(currentLocationTimeProvider);
    final dateFormat = DateFormat.yMMMd(l10n.localeName);

    // Track the selected date (defaults to today) - this is the source of truth
    final selectedDate = useState<DateTime>(now);

    final scheduleAsync = ref.watch(
      prayerScheduleProvider(l10n, selectedDate.value),
    );

    // State to track the currently expanded prayer
    final expandedPrayer = useState<Prayer?>(null);

    // Update expanded prayer when we get data with a current prayer
    useEffect(
      () {
        scheduleAsync.whenData((rows) {
          final currentRow = rows.where((r) => r.isCurrentPrayer).firstOrNull;
          if (currentRow != null && expandedPrayer.value == null) {
            expandedPrayer.value = currentRow.prayer;
          }
        });
        return null;
      },
      [scheduleAsync],
    );

    // Determine if selected date is today
    final isToday =
        selectedDate.value.year == now.year &&
        selectedDate.value.month == now.month &&
        selectedDate.value.day == now.day;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with date navigation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isToday
                            ? l10n.todaysSchedule
                            : dateFormat.format(selectedDate.value),
                        style: theme.typography.lg.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.selectPrayerToLog,
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                // Week date selector - uses lifted control pattern
                Expanded(
                  flex: 2,
                  child: FLineCalendar(
                    control: FLineCalendarControl.lifted(
                      date: selectedDate.value,
                      onChange: (value) {
                        if (value != null) {
                          selectedDate.value = value;
                          unawaited(
                            ref
                                .read(prayerCompletionProvider.notifier)
                                .setDate(value),
                          );
                        }
                      },
                    ),
                    start: now.subtract(const Duration(days: 6)),
                    end: now,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Prayer rows with smooth animation on date change
          scheduleAsync.when(
            data: (rows) => Column(
              key: ValueKey(selectedDate.value),
              children: rows
                  .map(
                    (row) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: SchedulePrayerRow(
                        row: row,
                        isExpanded: expandedPrayer.value == row.prayer,
                        onToggle: () {
                          if (expandedPrayer.value == row.prayer) {
                            expandedPrayer.value = null;
                          } else {
                            expandedPrayer.value = row.prayer;
                          }
                        },
                      ),
                    ),
                  )
                  .toList(),
            ).animate().fadeIn(duration: 200.ms),
            // loading: () => FSkeletonizer(
            //   child: Column(
            //     children: List.generate(
            //       5,
            //       (i) => Padding(
            //         padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            //         child: Container(
            //           height: 80,
            //           decoration: BoxDecoration(
            //             color: theme.colors.secondary,
            //             borderRadius: context.theme.radii.md,
            //           ),
            //         ),
            //       ),
            //     ),
            //   ),
            // ),
            error: (e, _) => FAlert(
              title: Text(l10n.errorOccurredWhile('Loading schedule')),
              subtitle: Text(e.toString()),
            ),
            loading: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
