import 'package:adhan_dart/adhan_dart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/feature/prayer/data/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/domain/completion_dedup.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_data_providers.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_service_provider.dart';
import 'package:tawaq/feature/settings/presentation/provider/prayer_settings_provider.dart';

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
  final settings = ref.watch(effectivePrayerSettingsProvider);
  if (settings == null) return Future.value(const []);

  return ref
      .read(prayerServiceProvider)
      .getPrayerCompletionForDate(normalized, settings.location);
}

/// Canonical status for [prayer] on today's calendar day.
@riverpod
Future<CompletionStatus> prayerTodayStatus(Ref ref, Prayer prayer) async {
  ref.watch(prayerCalendarDayKeyProvider);
  final now = ref.read(currentLocationTimeProvider);
  if (now == null) return CompletionStatus.none;

  final today = normalizeCompletionDay(now);
  final settings = ref.read(effectivePrayerSettingsProvider);
  if (settings == null) return CompletionStatus.none;

  final completions = await ref.watch(
    prayerCompletionsForDateProvider(today).future,
  );
  return mapPrayerStatuses(completions, settings.location, today)[prayer] ??
      CompletionStatus.none;
}

/// Invalidates cached completions for [day].
void invalidatePrayerCompletionsForDate(Ref ref, DateTime day) {
  ref.invalidate(prayerCompletionsForDateProvider(normalizeCompletionDay(day)));
}
