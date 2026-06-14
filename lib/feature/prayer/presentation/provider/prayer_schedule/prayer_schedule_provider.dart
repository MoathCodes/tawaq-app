import 'package:adhan_dart/adhan_dart.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/utils/date_formatter.dart';
import 'package:tawaq/feature/prayer/data/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/domain/completion_dedup.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_schedule_row.dart';
import 'package:tawaq/feature/prayer/domain/prayer_extensions.dart';
import 'package:tawaq/feature/prayer/domain/services/adhan_time_utils.dart';
import 'package:tawaq/feature/prayer/domain/use_cases/compute_prayer_card_decision.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_completions_for_date_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_data_providers.dart';
import 'package:tawaq/feature/settings/data/models/prayer_settings_model.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/l10n/app_localizations.dart';

part 'prayer_schedule_provider.g.dart';

/// The list of obligatory prayers to display in the schedule.
const List<Prayer> _obligatoryPrayers = [
  Prayer.fajr,
  Prayer.dhuhr,
  Prayer.asr,
  Prayer.maghrib,
  Prayer.isha,
];

/// Current obligatory prayer for the live schedule.
///
/// Selects from [prayerDayProvider] so dependents rebuild only when the active
/// prayer changes, not on every 1 Hz clock tick.
@riverpod
Prayer? scheduleCurrentPrayer(Ref ref) {
  final day = ref.watch(prayerDayProvider).value;
  if (day == null) return null;
  return getCurrentPrayer(
    currentTime: day.now,
    location: day.location,
    todaysPrayerTimes: day.today,
    todaysSunnahTimes: day.todaySunnah,
    yesterdaysPrayerTimes: day.yesterday,
    yesterdaysSunnahTimes: day.yesterdaySunnah,
  );
}

/// Pre-built schedule rows for obligatory prayers on a day.
///
/// Stable row data (times, completions) without live relative-time labels.
/// Pass [forDate] for another day (up to one week back in the schedule UI).
@riverpod
List<PrayerScheduleRow> prayerSchedule(
  Ref ref,
  AppLocalizations l10n, [
  DateTime? forDate,
]) {
  final settings = ref.watch(prayerSettingsProvider).value;
  if (settings == null) return [];

  final formatter = ref.watch(timeFormatterProvider);
  final DateTime completionDay;
  if (forDate != null) {
    completionDay = normalizeCompletionDay(forDate);
  } else {
    ref.watch(prayerCalendarDayKeyProvider);
    completionDay = normalizeCompletionDay(
      ref.read(currentLocationTimeProvider),
    );
  }
  final completions =
      ref.watch(prayerCompletionsForDateProvider(completionDay)).value ?? [];
  final completionStatuses = mapPrayerStatuses(
    completions,
    settings.location,
    completionDay,
  );

  final targetDate = forDate != null
      ? DateTime(forDate.year, forDate.month, forDate.day)
      : null;

  final todayKey = ref.watch(prayerCalendarDayKeyProvider);

  if (targetDate != null) {
    final targetKey =
        targetDate.year * 10000 + targetDate.month * 100 + targetDate.day;
    if (targetKey != todayKey) {
      final times = ref.watch(prayerTimesForDateProvider(targetDate));
      return _buildRows(
        formatter: formatter,
        times: times,
        targetDate: targetDate,
        settings: settings,
        completionStatuses: completionStatuses,
      );
    }
  }

  // Stable deps only — live relative labels are in row widgets.
  ref.watch(prayerCalendarDayKeyProvider);
  final times = ref.watch(currentPrayerTimesProvider());
  final anchor = DateTime(times.fajr.year, times.fajr.month, times.fajr.day);

  return _buildRows(
    formatter: formatter,
    times: times,
    targetDate: anchor,
    settings: settings,
    completionStatuses: completionStatuses,
  );
}

List<PrayerScheduleRow> _buildRows({
  required DateFormat formatter,
  required PrayerTimes times,
  required DateTime targetDate,
  required PrayerSettings settings,
  required Map<Prayer, CompletionStatus> completionStatuses,
}) {
  final location = settings.location;
  final completionDate = DateTime(
    targetDate.year,
    targetDate.month,
    targetDate.day,
  );

  final rows = <PrayerScheduleRow>[];
  for (final prayer in _obligatoryPrayers) {
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
        completionStatus:
            completionStatuses[prayer] ?? CompletionStatus.none,
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

/// Whether [rowPrayer] is the highlighted row for [currentPrayer].
bool isScheduleRowCurrent({
  required Prayer rowPrayer,
  required Prayer currentPrayer,
}) {
  if (currentPrayer.isObligatory) {
    return rowPrayer == currentPrayer;
  }
  if (currentPrayer == Prayer.ishaBefore || currentPrayer == Prayer.fajrAfter) {
    return rowPrayer == Prayer.fajr;
  }
  return rowPrayer == Prayer.dhuhr;
}

/// Next obligatory prayer after [currentPrayer] in the schedule list.
Prayer? scheduleNextPrayer(Prayer currentPrayer) {
  final currentIdx = _obligatoryPrayers.indexWhere(
    (prayer) => isScheduleRowCurrent(
      rowPrayer: prayer,
      currentPrayer: currentPrayer,
    ),
  );
  if (currentIdx == -1 || currentIdx + 1 >= _obligatoryPrayers.length) {
    return null;
  }
  return _obligatoryPrayers[currentIdx + 1];
}
