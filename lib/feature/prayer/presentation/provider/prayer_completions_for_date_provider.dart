import 'package:adhan_dart/adhan_dart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/feature/prayer/data/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/domain/completion_dedup.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_data_providers.dart';
import 'package:tawaq/feature/settings/data/models/prayer_settings_model.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';

part 'prayer_completions_for_date_provider.g.dart';

/// Normalizes [day] to a naive calendar date.
DateTime normalizeCompletionDay(DateTime day) {
  return DateTime(day.year, day.month, day.day);
}

/// Deduped completion rows for a calendar day in the prayer timezone.
@riverpod
Future<List<PrayerCompletion>> prayerCompletionsForDate(
  Ref ref,
  DateTime day,
) {
  final normalized = normalizeCompletionDay(day);
  ref.watch(prayerSettingsProvider);
  return ref
      .read(prayerServiceProvider)
      .getPrayerCompletionForDate(normalized);
}

/// Canonical status for [prayer] on today's calendar day.
@riverpod
Future<CompletionStatus> prayerTodayStatus(Ref ref, Prayer prayer) async {
  ref.watch(prayerCalendarDayKeyProvider);
  final today = normalizeCompletionDay(ref.read(currentLocationTimeProvider));
  final location =
      ref.read(prayerSettingsProvider).value?.location ??
      PrayerSettings.defaultSettings().location;
  final completions = await ref.watch(
    prayerCompletionsForDateProvider(today).future,
  );
  return mapPrayerStatuses(completions, location, today)[prayer] ??
      CompletionStatus.none;
}

/// Invalidates cached completions for [day].
void invalidatePrayerCompletionsForDate(Ref ref, DateTime day) {
  ref.invalidate(prayerCompletionsForDateProvider(normalizeCompletionDay(day)));
}
