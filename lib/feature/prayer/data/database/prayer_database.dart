import 'package:adhan_dart/adhan_dart.dart';
import 'package:hivez_flutter/hivez_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/utils/date_extensions.dart';
import 'package:tawaq/feature/prayer/data/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/domain/prayer_extensions.dart';
import 'package:timezone/timezone.dart';

part 'prayer_database.g.dart';

/// Provides a singleton instance of the [PrayerDatabase].
///
/// This provider is responsible for creating and managing the lifecycle of the
/// [PrayerDatabase]. It ensures that the database is opened when it is first
/// accessed and closed when the application is disposed.
@Riverpod(keepAlive: true)
PrayerDatabase prayerDatabase(Ref ref) {
  final completionBox = Box<int, PrayerCompletion>('prayer_completions');
  final prayerDatabase = PrayerDatabase(completionBox);
  ref.onDispose(() async {
    await completionBox.closeBox();
  });
  return prayerDatabase;
}

/// The database for the prayer data.
class PrayerDatabase {
  /// Creates a new instance of the [PrayerDatabase].
  PrayerDatabase(this._box);
  final Box<int, PrayerCompletion> _box;

  /// Counts the number of prayers for each completion status on a given date.
  Future<Map<CompletionStatus, int>> countAllPrayerStatusOnDate(
    DateTime from,
    DateTime to,
  ) async {
    // Initialize result map with zero counts for all statuses so callers
    // can rely on every key being present.
    final counts = <CompletionStatus, int>{
      for (final s in CompletionStatus.values) s: 0,
    };

    // Get all completions in the date range
    final completions = await _box.getValuesWhere(
      (value) => value.completionTime.isBetween(from, to),
    );

    // Count each status
    for (final completion in completions) {
      counts[completion.status] = (counts[completion.status] ?? 0) + 1;
    }

    return counts;
  }

  /// Counts the number of prayers with a specific completion status on a given
  /// date.
  Future<int> countPrayerStatusOnDate(
    CompletionStatus status,
    DateTime from,
    DateTime to,
  ) async {
    final values = await _box.getValuesWhere(
      (value) =>
          value.status == status && value.completionTime.isBetween(from, to),
    );
    return values.length;
  }

  /// Deletes a prayer completion.
  Future<void> deleteCompletion(int id) async {
    await _box.delete(id);
  }

  /// Returns all prayer completions.
  Future<List<PrayerCompletion>> getAllCompletions() async {
    final values = await _box.getAllValues();
    return values.toList();
  }

  /// Returns a prayer completion by its ID.
  Future<PrayerCompletion?> getCompletionById(int id) async {
    return _box.get(id);
  }

  /// Returns all prayer completions for a specific calendar day in [location].
  Future<List<PrayerCompletion>> getCompletionsForDate(
    DateTime date,
    Location location,
  ) async {
    final completions = await _box.getValuesWhere((value) {
      return value.completionTime.isSameCalendarDay(date, location);
    });

    return completions.toList();
  }

  /// Returns all prayer completions between [from] and [to] (inclusive).
  Future<List<PrayerCompletion>> getCompletionsBetween(
    DateTime from,
    DateTime to,
  ) async {
    final completions = await _box.getValuesWhere(
      (value) => value.completionTime.isBetween(from, to),
    );

    return completions.toList();
  }

  /// Returns a list of dates on which all prayers were completed.
  Future<List<DateTime>> getFullyCompletedDays(Location loc) async {
    // Get all completions that are not missed or none
    final completions = await _box.getValuesWhere(
      (value) =>
          value.status != CompletionStatus.missed &&
          value.status != CompletionStatus.none,
    );

    // Group by local calendar day and collect distinct prayers.
    final bucket = <DateTime, Set<Prayer>>{};
    for (final entry in completions) {
      final localTime = entry.completionTime.toLocation(loc);
      final dayKey = DateTime(localTime.year, localTime.month, localTime.day);
      bucket.putIfAbsent(dayKey, () => <Prayer>{}).add(entry.prayer);
    }

    // Keep only days that have ALL obligatory prayers (5).
    final fullDays =
        bucket.entries
            .where((e) => e.value.length == 5)
            .map((e) => e.key)
            .toList()
          ..sort();

    return fullDays;
  }

  /// Inserts or updates a prayer completion.
  ///
  /// If a completion for the same prayer on the same date already exists,
  /// it will be updated. Otherwise, a new completion will be inserted.
  Future<void> insertOrUpdateCompletion(
    PrayerCompletion completion,
    Location location,
  ) async {
    // First, check if a completion already exists for this prayer+date
    final existingId = await _findExistingCompletionId(
      completion.prayer,
      completion.completionTime,
      location,
    );

    if (existingId != null) {
      // Update existing completion with the same ID
      await _box.put(existingId, completion.copyWith(id: existingId));
    } else if (completion.id != null) {
      // Update by explicit ID
      await _box.put(completion.id!, completion);
    } else {
      // Add new completion (Hivez will auto-assign an ID)
      final id = await _box.add(completion);
      await _box.put(id, completion.copyWith(id: id));
    }
  }

  /// Finds an existing completion ID for a prayer on a specific date.
  Future<int?> _findExistingCompletionId(
    Prayer prayer,
    DateTime date,
    Location location,
  ) async {
    return _box.firstKeyWhere(
      (_, value) =>
          value.prayer == prayer &&
          value.completionTime.isSameCalendarDay(date, location),
    );
  }

  /// Returns whether a prayer completion exists.
  Future<bool> isCompletionExists(int id) async {
    return _box.containsKey(id);
  }
}
