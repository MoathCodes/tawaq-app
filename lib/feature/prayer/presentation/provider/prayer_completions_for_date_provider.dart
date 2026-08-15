import 'package:adhan_dart/adhan_dart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/bootstrap/app_init_providers.dart';
import 'package:tawaq/feature/prayer/data/database/prayer_database.dart';
import 'package:tawaq/feature/prayer/domain/completion_dedup.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/domain/prayer_calendar.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_day.dart';
import 'package:timezone/timezone.dart';

part 'prayer_completions_for_date_provider.g.dart';

/// The only writable runtime authority for all prayer completions.
@Riverpod(keepAlive: true)
class PrayerCompletionStore extends _$PrayerCompletionStore {
  late Location _location;

  @override
  Future<Map<int, List<PrayerCompletion>>> build() async {
    await ref.watch(hiveCoreInitProvider.future);
    final location = ref.watch(prayerTimeInputsProvider)?.location;
    if (location == null) return const {};
    _location = location;

    final database = ref.read(prayerDatabaseProvider);
    await database.repairDuplicates(location);
    final all = await database.getAllCompletions();
    return _index(all, location);
  }

  /// Writes [completion] before atomically replacing its day bucket.
  Future<void> save(PrayerCompletion completion) async {
    final database = ref.read(prayerDatabaseProvider);
    await database.insertOrUpdateCompletion(completion, _location);
    await _refreshDay(completion.completionTime);
  }

  /// Deletes [prayer] from [date] before publishing its refreshed day bucket.
  Future<void> deletePrayer(Prayer prayer, DateTime date) async {
    final database = ref.read(prayerDatabaseProvider);
    await database.deleteCompletionForPrayerOnDate(prayer, date, _location);
    await _refreshDay(date);
  }

  /// Deletes the row with [id] before atomically publishing the new index.
  Future<void> deleteById(int id) async {
    final database = ref.read(prayerDatabaseProvider);
    final existing = await database.getCompletionById(id);
    await database.deleteCompletion(id);
    if (existing == null) return;
    await _refreshDay(existing.completionTime);
  }

  Future<void> _refreshDay(DateTime date) async {
    final dayKey = completionDayKey(date, _location);
    final fresh = await ref
        .read(prayerDatabaseProvider)
        .getCompletionsForDate(date, _location);
    if (!ref.mounted) return;
    final next = {...state.value ?? const <int, List<PrayerCompletion>>{}};
    if (fresh.isEmpty) {
      next.remove(dayKey);
    } else {
      next[dayKey] = List.unmodifiable(fresh);
    }
    state = AsyncData(Map.unmodifiable(next));
  }

  Map<int, List<PrayerCompletion>> _index(
    List<PrayerCompletion> rows,
    Location location,
  ) {
    final grouped = <int, List<PrayerCompletion>>{};
    for (final row in rows) {
      grouped
          .putIfAbsent(completionDayKey(row.completionTime, location), () => [])
          .add(row);
    }
    return Map.unmodifiable({
      for (final entry in grouped.entries)
        entry.key: List<PrayerCompletion>.unmodifiable(
          dedupeCompletions(entry.value, location),
        ),
    });
  }
}

/// Deduped completion rows for a calendar day (`yyyymmdd` [dayKey]).
@riverpod
Future<List<PrayerCompletion>> prayerCompletionsForDate(
  Ref ref,
  int dayKey,
) async {
  final index = await ref.watch(prayerCompletionStoreProvider.future);
  return index[dayKey] ?? const [];
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
