import 'package:adhan_dart/adhan_dart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/feature/prayer/data/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/data/repository/prayer_repo.dart';
import 'package:tawaq/feature/prayer/domain/completion_dedup.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_day.dart';

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
  final location = ref.watch(prayerTimeInputsProvider)?.location;
  if (location == null) return Future.value(const []);

  return ref
      .read(prayerRepoProvider)
      .getPrayerCompletionForDate(normalized, location);
}

/// Canonical completion status for [prayer] on [completionDay].
@riverpod
CompletionStatus completionStatus(
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

/// Invalidates cached completions for [day].
void invalidatePrayerCompletionsForDate(Ref ref, DateTime day) {
  ref.invalidate(prayerCompletionsForDateProvider(normalizeCompletionDay(day)));
}
