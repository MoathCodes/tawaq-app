import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_completion_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_data_providers.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_schedule/prayer_schedule_provider.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/schedule_row/schedule_prayer_row.dart';
import 'package:tawaq/theme/theme.dart';

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

    final scheduleRows = ref.watch(
      prayerScheduleProvider(l10n, selectedDate.value),
    );

    // State to track the currently expanded prayer
    final expandedPrayer = useState<Prayer?>(null);

    final currentPrayer = ref.watch(scheduleCurrentPrayerProvider);

    // Expand the active prayer row once when it becomes available.
    useEffect(
      () {
        if (currentPrayer != null && expandedPrayer.value == null) {
          expandedPrayer.value = currentPrayer;
        }
        return null;
      },
      [currentPrayer],
    );

    // Determine if selected date is today
    final isToday =
        selectedDate.value.year == now.year &&
        selectedDate.value.month == now.month &&
        selectedDate.value.day == now.day;

    return Column(
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
                    Semantics(
                      header: true,
                      child: Text(
                        isToday
                            ? l10n.todaysSchedule
                            : dateFormat.format(selectedDate.value),
                        style: theme.typography.lg.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    ExcludeSemantics(
                      child: Text(
                        l10n.selectPrayerToLog,
                        style: theme.typography.sm.copyWith(
                          color: theme.colors.mutedForeground,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Week date selector - uses lifted control pattern
              Expanded(
                flex: 3,
                child: FLineCalendar(
                  control: FLineCalendarControl.lifted(
                    date: selectedDate.value,
                    onChange: (value) {
                      if (value == null) return;
                      unawaited(
                        Future<void>(() async {
                          await ref
                              .read(prayerCompletionProvider.notifier)
                              .setDate(value);
                          selectedDate.value = value;
                        }),
                      );
                    },
                  ),
                  scrollControl: FLineCalendarScrollControl.managed(
                    start: now.subtract(const Duration(days: 6)),
                    end: now,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Prayer rows with smooth animation on date change
        Column(
          key: ValueKey(selectedDate.value),
          children: scheduleRows
              .map(
                (row) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: SchedulePrayerRow(
                    row: row,
                    isToday: isToday,
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
      ],
    );
  }
}
