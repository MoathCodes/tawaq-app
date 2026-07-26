import 'package:adhan_dart/adhan_dart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/feature/prayer/data/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/data/repository/prayer_repo.dart';
import 'package:tawaq/feature/prayer/domain/completion_dedup.dart';
import 'package:tawaq/feature/prayer/domain/prayer_calendar.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_day.dart';

part 'prayer_completions_for_date_provider.g.dart';

/// Deduped completion rows for a calendar day (`yyyymmdd` [dayKey]).
@riverpod
Future<List<PrayerCompletion>> prayerCompletionsForDate(
  Ref ref,
  int dayKey,
) {
  final location = ref.watch(prayerTimeInputsProvider)?.location;
  if (location == null) return Future.value(const []);

  return ref
      .read(prayerRepoProvider)
      .getPrayerCompletionForDate(
        calendarDayFromKey(dayKey, location),
        location,
      );
}

/// Canonical completion status for [prayer] on [dayKey].
///
/// Returns `null` while completions are loading/unknown so UI does not treat
/// loading as [CompletionStatus.none].
@riverpod
CompletionStatus? completionStatus(
  Ref ref,
  Prayer prayer,
  int dayKey,
) {
  final location = ref.watch(prayerTimeInputsProvider)?.location;
  if (location == null) return null;

  final completionsAsync = ref.watch(
    prayerCompletionsForDateProvider(dayKey),
  );
  if (!completionsAsync.hasValue) return null;
  return mapPrayerStatuses(
        completionsAsync.requireValue,
        location,
        calendarDayFromKey(dayKey, location),
      )[prayer] ??
      CompletionStatus.none;
}

/// Invalidates cached completions for [dayKey].
void invalidatePrayerCompletionsForDayKey(Ref ref, int dayKey) {
  ref.invalidate(prayerCompletionsForDateProvider(dayKey));
}
