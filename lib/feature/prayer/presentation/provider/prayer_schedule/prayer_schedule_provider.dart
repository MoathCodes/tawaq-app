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
import 'package:tawaq/feature/prayer/presentation/provider/prayer_calendar_utils.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_completions_for_date_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_data_providers.dart';
import 'package:tawaq/feature/settings/data/models/prayer_settings_model.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_effective_settings_provider.dart';
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
  // Recompute at most once per minute (prayer boundaries are minute-resolution)
  // instead of on every 1 Hz snapshot emission; the snapshot is read
  // non-reactively since the bundle is stable within the day.
  ref.watch(currentMinuteBucketProvider);
  final day = ref.read(prayerDayProvider).value;
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

  // Depend on the day key (changes only at midnight), not the 1 Hz clock
  // snapshot — otherwise this provider re-runs every second and emits a fresh
  // (non-equal) list, rebuilding the whole schedule. Live relative-time labels
  // are handled by leaf widgets watching currentLocationTimeProvider.
  final todayKey = ref.watch(prayerCalendarDayKeyProvider);
  final targetDate = forDate != null
      ? DateTime(forDate.year, forDate.month, forDate.day)
      : todayKey != 0
      ? dateFromCalendarDayKey(todayKey)
      : null;
  if (targetDate == null) return [];

  final completionDay = normalizeCompletionDay(forDate ?? targetDate);
  final times = ref.watch(prayerTimesForDateProvider(targetDate));
  if (times == null) return [];

  return _buildRows(
    formatter: formatter,
    times: times,
    targetDate: targetDate,
    settings: settings,
    completionDay: completionDay,
  );
}

/// Per-row completion status with `.select()` so only the changed prayer
/// rebuilds its schedule row.
@riverpod
CompletionStatus schedulePrayerStatus(
  Ref ref,
  Prayer prayer,
  DateTime completionDay,
) {
  final normalized = normalizeCompletionDay(completionDay);
  final location = ref.watch(prayerTimeInputsProvider)?.location;
  if (location == null) return CompletionStatus.none;

  final completionsAsync = ref.watch(
    prayerCompletionsForDateProvider(normalized),
  );
  if (!completionsAsync.hasValue) return CompletionStatus.none;
  return mapPrayerStatuses(
        completionsAsync.value!,
        location,
        normalized,
      )[prayer] ??
      CompletionStatus.none;
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
