import 'package:adhan_dart/adhan_dart.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/utils/prayer_extensions.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_schedule_row.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_settings.dart';
import 'package:tawaq/feature/prayer/domain/prayer_calendar.dart';
import 'package:tawaq/feature/prayer/domain/prayer_slots.dart';
import 'package:tawaq/feature/prayer/presentation/provider/date_formatter.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_day.dart';

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

/// Pre-built schedule rows for obligatory prayers on [dayKey] (`yyyymmdd`).
///
/// Call sites resolve “today” via [prayerCalendarDayKeyProvider] — there is no
/// null/today dual cache on this family.
@riverpod
List<PrayerScheduleRow> prayerSchedule(
  Ref ref,
  int dayKey,
) {
  final settings = ref.watch(effectivePrayerSettingsProvider);
  if (settings == null) return [];

  final formatter = ref.watch(timeFormatterProvider);
  final targetDate = dateFromCalendarDayKey(dayKey);
  final times = ref.watch(prayerDayBundleForDateProvider(targetDate))?.today;
  if (times == null) return [];

  return _buildRows(
    formatter: formatter,
    times: times,
    targetDate: targetDate,
    settings: settings,
  );
}

List<PrayerScheduleRow> _buildRows({
  required DateFormat formatter,
  required PrayerTimes times,
  required DateTime targetDate,
  required PrayerSettings settings,
}) {
  final location = settings.location;
  final completionDate = DateTime(
    targetDate.year,
    targetDate.month,
    targetDate.day,
  );

  final rows = <PrayerScheduleRow>[];
  for (final prayer in kObligatoryPrayers) {
    // Bundle times are already adjustment-baked by computePrayerDayBundle.
    final prayerTime = times.getTimesForPrayer(prayer, location);
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
