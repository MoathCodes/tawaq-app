import 'package:adhan_dart/adhan_dart.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/utils/date_formatter.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_schedule_row.dart';
import 'package:tawaq/core/utils/prayer_extensions.dart';
import 'package:tawaq/feature/prayer/domain/services/adhan_time_utils.dart';
import 'package:tawaq/feature/prayer/domain/prayer_calendar.dart';
import 'package:tawaq/feature/prayer/domain/prayer_slots.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_completions_for_date_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_day.dart';
import 'package:tawaq/feature/settings/data/models/prayer_settings_model.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';

part 'prayer_schedule_provider.g.dart';

/// Current obligatory prayer for the live schedule.
@riverpod
Prayer? scheduleCurrentPrayer(Ref ref) {
  ref.watch(currentMinuteBucketProvider);
  final day = ref.read(prayerDayProvider).value;
  if (day == null) return null;
  return getCurrentPrayer(
    currentTime: day.now,
    location: day.location,
    timeline: day.timeline,
  );
}

/// Pre-built schedule rows for obligatory prayers on a day.
@riverpod
List<PrayerScheduleRow> prayerSchedule(
  Ref ref, [
  DateTime? forDate,
]) {
  final settings = ref.watch(prayerSettingsProvider).value;
  if (settings == null) return [];

  final formatter = ref.watch(timeFormatterProvider);

  final todayKey = ref.watch(prayerCalendarDayKeyProvider);
  final targetDate = forDate != null
      ? DateTime(forDate.year, forDate.month, forDate.day)
      : todayKey != 0
      ? dateFromCalendarDayKey(todayKey)
      : null;
  if (targetDate == null) return [];

  final completionDay = normalizeCompletionDay(forDate ?? targetDate);
  final times = ref.watch(prayerDayBundleForDateProvider(targetDate))?.today;
  if (times == null) return [];

  return _buildRows(
    formatter: formatter,
    times: times,
    targetDate: targetDate,
    settings: settings,
    completionDay: completionDay,
  );
}

List<PrayerScheduleRow> _buildRows({
  required DateFormat formatter,
  required PrayerTimes times,
  required DateTime targetDate,
  required PrayerSettings settings,
  required DateTime completionDay,
}) {
  final location = settings.location;
  final completionDate = DateTime(
    targetDate.year,
    targetDate.month,
    targetDate.day,
  );

  final rows = <PrayerScheduleRow>[];
  for (final prayer in kObligatoryPrayers) {
    final prayerTime = applyAdhanAdjustment(
      prayerTime: times.getTimesForPrayer(prayer, location),
      prayer: prayer,
      adjustments: settings.adhanAdjustments,
    );
    rows.add(
      PrayerScheduleRow(
        prayer: prayer,
        prayerTime: prayerTime,
        formattedAdhanTime: formatter.format(prayerTime),
        formattedIqamahTime: _formatIqamah(
          formatter: formatter,
          prayerTime: prayerTime,
          iqamahMinutes: settings.iqamahSettings[prayer] ?? 0,
        ),
        completionDate: completionDate,
      ),
    );
  }
  return rows;
}

String? _formatIqamah({
  required DateFormat formatter,
  required DateTime prayerTime,
  required int iqamahMinutes,
}) {
  if (iqamahMinutes <= 0) return null;
  return formatter.format(prayerTime.add(Duration(minutes: iqamahMinutes)));
}
