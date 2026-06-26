import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/layout/responsive.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/utils/hijri_format.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_calendar_utils.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_data_providers.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_schedule/prayer_schedule_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_schedule/schedule_selected_date_provider.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/schedule_row/schedule_prayer_row.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/schedule_row/sunnah_times_card.dart';
import 'package:tawaq/theme/theme.dart';

/// Today's prayer schedule with inline status selectors.
/// Users can navigate back up to a week to view and edit prayer statuses.
class PrayerScheduleList extends ConsumerWidget {
  /// Creates a [PrayerScheduleList] instance.
  const PrayerScheduleList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = FTheme.of(context);
    final l10n = context.l10n;
    final selectedDate = ref.watch(scheduleSelectedDateProvider);
    final todayKey = ref.watch(prayerCalendarDayKeyProvider);
    final todayDate = todayKey != 0
        ? dateFromCalendarDayKey(todayKey)
        : (ref.watch(currentLocationTimeProvider) ??
              DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
              ));
    final selectedKey = calendarDayKeyFromDate(selectedDate);

    final scheduleRows = ref.watch(
      prayerScheduleProvider(selectedDate),
    );

    final isToday = todayKey != 0 && selectedKey == todayKey;
    final currentPrayer = isToday
        ? ref.watch(scheduleCurrentPrayerProvider)
        : null;

    // Built in the build phase (not inside LayoutBuilder.builder) so this work
    // does not run during the layout pass on every relayout.
    final titleColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            isToday
                ? l10n.todaysSchedule
                : HijriFormat.formatDate(
                    selectedDate,
                    l10n.localeName,
                  ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.typography.body.lg.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        ExcludeSemantics(
          child: Text(
            l10n.logPrayerStatus,
            style: theme.typography.body.sm.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
        ),
      ],
    );

    final calendar = FLineCalendar(
      control: FLineCalendarControl.lifted(
        date: selectedDate,
        onChange: (value) {
          if (value == null) return;
          ref.read(scheduleSelectedDateProvider.notifier).select(value);
        },
      ),
      scrollControl: FLineCalendarScrollControl.managed(
        start: todayDate.subtract(const Duration(days: 6)),
        end: todayDate,
      ),
      builder: (context, data, _) => _HijriLineCalendarItem(
        data: data,
        languageCode: l10n.localeName,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stackHeader = !isContainerAtLeast(
                context,
                constraints,
                FBreakpoint.lg,
              );

              if (stackHeader) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpacing.md,
                  children: [
                    titleColumn,
                    calendar,
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(flex: 2, child: titleColumn),
                  Expanded(child: calendar),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const SunnahTimesCard(),
        const SizedBox(height: AppSpacing.lg),
        Column(
          key: ValueKey(selectedDate),
          spacing: AppSpacing.md,
          children: scheduleRows
              .map(
                (row) => SchedulePrayerRow(
                  row: row,
                  isToday: isToday,
                  currentPrayer: currentPrayer,
                ),
              )
              .toList(),
        ).animate().fadeIn(duration: 200.ms),
      ],
    );
  }
}

class _HijriLineCalendarItem extends StatelessWidget {
  const _HijriLineCalendarItem({
    required this.data,
    required this.languageCode,
  });

  final FLineCalendarItemData data;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final weekday = HijriFormat.shortWeekday(data.date, languageCode);
    final day = HijriFormat.dayOfMonth(data.date, languageCode);
    final semanticsLabel = HijriFormat.accessibilityLabel(
      data.date,
      languageCode,
    );

    return Semantics(
      label: semanticsLabel,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: data.style.decoration.resolve(data.variants),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: data.style.contentEdgeSpacing,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  spacing: data.style.contentSpacing,
                  children: [
                    DefaultTextStyle.merge(
                      style: data.style.weekdayTextStyle.resolve(data.variants),
                      child: Text(weekday),
                    ),
                    DefaultTextStyle.merge(
                      style: data.style.dateTextStyle.resolve(data.variants),
                      child: Text(day),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (data.variants.contains(FLineCalendarItemVariant.today))
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                height: 4,
                width: 4,
                decoration: BoxDecoration(
                  color: data.style.todayIndicatorColor.resolve(data.variants),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
