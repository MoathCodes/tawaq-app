import 'dart:io';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:hasanat/core/logging/talker_provider.dart';
import 'package:hasanat/core/utils/prayer_extensions.dart';
import 'package:hasanat/feature/prayer/data/models/prayer_completion.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:timezone/timezone.dart';

part 'prayer_database.g.dart';

/// Provides a singleton instance of the [PrayerDatabase].
///
/// This provider is responsible for creating and managing the lifecycle of the
/// [PrayerDatabase]. It ensures that the database is opened when it is first
/// accessed and closed when the application is disposed.
@riverpod
PrayerDatabase prayerDatabase(Ref ref) {
  final log = ref.read(talkerProvider);
  try {
    final database = LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'prayer.db'));
      return NativeDatabase(file);
    });
    final prayerDatabase = PrayerDatabase(database, log);
    ref.onDispose(() async {
      await prayerDatabase.close();
    });
    return prayerDatabase;
  } catch (e, stackTrace) {
    log.handle(e, stackTrace);
    rethrow;
  }
}

/// The table that stores the prayer completion data.
@UseRowClass(PrayerCompletion)
class PrayerCompletions extends Table {
  /// The time the prayer was completed.
  DateTimeColumn get completionTime => dateTime()();

  /// The unique identifier of the prayer completion.
  IntColumn get id => integer().autoIncrement()();
  // Add useful indexes to speed up date-range and status queries.
  @override
  List<Set<Column>> get indexes => [
        {completionTime},
        {status, completionTime},
      ];

  /// The prayer that was completed.
  IntColumn get prayer => intEnum<Prayer>()();

  /// The status of the prayer completion.
  IntColumn get status => intEnum<CompletionStatus>()();
}

/// The database for the prayer data.
@DriftDatabase(tables: [PrayerCompletions])
class PrayerDatabase extends _$PrayerDatabase {
  /// Creates a new instance of the [PrayerDatabase].
  PrayerDatabase(super.executor, this._log);
  final Talker _log;

  @override
  int get schemaVersion => 1;

  /// Counts the number of all prayers on a given date.
  Future<int> countAllPrayersOnDate(DateTime from, DateTime to) async {
    try {
      final query = managers.prayerCompletions.filter(
        (f) => f.completionTime.isBetween(from, to),
      );
      return await query.count();
    } catch (e, stackTrace) {
      _log.handle(e, stackTrace);
      rethrow;
    }
  }

  /// Counts the number of prayers for each completion status on a given date.
  Future<Map<CompletionStatus, int>> countAllPrayerStatusOnDate(
    DateTime from,
    DateTime to,
  ) async {
    try {
      // Initialize result map with zero counts for all statuses so callers
      // can rely on every key being present.
      final counts = <CompletionStatus, int>{
        for (final s in CompletionStatus.values) s: 0,
      };

      // Use Drift's fluent API instead of raw SQL. We create a SELECT query
      // that only fetches the `status` column and an aggregated COUNT(*),
      // filtered by the requested date interval, and grouped by status.

      final statusColumn = prayerCompletions.status;
      final countExpr = statusColumn.count();

      final rows = await (selectOnly(prayerCompletions)
            ..addColumns([statusColumn, countExpr])
            ..where(
              prayerCompletions.completionTime.isBetweenValues(from, to),
            )
            ..groupBy([statusColumn]))
          .get();

      for (final row in rows) {
        final statusIndex = row.read(statusColumn)!;
        final total = row.read(countExpr)!;
        final status = CompletionStatus.values[statusIndex];
        counts[status] = total;
      }

      return counts;
    } catch (e, stackTrace) {
      _log.handle(e, stackTrace);
      rethrow;
    }
  }

  /// Counts the number of prayers with a specific completion status on a given date.
  Future<int> countPrayerStatusOnDate(
    CompletionStatus status,
    DateTime from,
    DateTime to,
  ) async {
    try {
      final query = managers.prayerCompletions.filter(
        (f) => f.completionTime.isBetween(from, to) & f.status.equals(status),
      );
      return await query.count();
    } catch (e, stackTrace) {
      _log.handle(e, stackTrace);
      rethrow;
    }
  }

  /// Deletes a prayer completion.
  Future<void> deleteCompletion(int id) async {
    try {
      final query = managers.prayerCompletions.filter((f) => f.id.equals(id));
      await query.delete();
    } catch (e, stackTrace) {
      _log.handle(e, stackTrace);
      rethrow;
    }
  }

  /// Returns all prayer completions.
  Future<List<PrayerCompletion>> getAllCompletions() async {
    try {
      final query = select(prayerCompletions);
      return await query.get();
    } catch (e, stackTrace) {
      _log.handle(e, stackTrace);
      rethrow;
    }
  }

  /// Returns a prayer completion by its ID.
  Future<PrayerCompletion?> getCompletionById(int id) async {
    try {
      final query = managers.prayerCompletions.filter((f) => f.id.equals(id));
      return await query.getSingleOrNull();
    } catch (e, stackTrace) {
      _log.handle(e, stackTrace);
      rethrow;
    }
  }

  /// Returns a list of dates on which all prayers were completed.
  Future<List<DateTime>> getFullyCompletedDays(Location loc) async {
    try {
      final completions = await (select(prayerCompletions)
            ..where(
              (tbl) =>
                  tbl.status.equals(CompletionStatus.missed.index).not() &
                  tbl.status.equals(CompletionStatus.none.index).not(),
            ))
          .get();

      // 2️⃣  Group by local calendar day and collect distinct prayers.
      final bucket = <DateTime, Set<Prayer>>{};
      for (final entry in completions) {
        final localTime = entry.completionTime.toLocation(loc);
        final dayKey = DateTime(localTime.year, localTime.month, localTime.day);
        bucket.putIfAbsent(dayKey, () => <Prayer>{}).add(entry.prayer);
      }

      // 3️⃣  Keep only days that have ALL obligatory prayers (5).
      final fullDays = bucket.entries
          .where((e) => e.value.length == 5)
          .map((e) => e.key)
          .toList()
        ..sort();

      return fullDays;
    } catch (e, stackTrace) {
      _log.handle(e, stackTrace);
      rethrow;
    }
  }

  /// Inserts or updates a prayer completion.
  Future<void> insertOrUpdateCompletion(
    PrayerCompletionsCompanion completion,
  ) async {
    try {
      final query = into(prayerCompletions);
      await query.insertOnConflictUpdate(completion);
    } catch (e, stackTrace) {
      _log.handle(e, stackTrace);
      rethrow;
    }
  }

  /// Returns whether a prayer completion exists.
  Future<bool> isCompletionExists(int id) async {
    try {
      final query = managers.prayerCompletions.filter((f) => f.id.equals(id));
      return await query.exists();
    } catch (e, stackTrace) {
      _log.handle(e, stackTrace);
      rethrow;
    }
  }

  /// Watches for changes to the prayer completions on a specific date.
  Stream<List<PrayerCompletion>> watchCompletionsBasedOnDate(
    int day,
    int month,
    int year,
  ) {
    try {
      final query = managers.prayerCompletions.filter(
        (f) =>
            f.completionTime.column.year.equals(year) &
            f.completionTime.column.month.equals(month) &
            f.completionTime.column.day.equals(day),
      );

      return query.watch();
    } catch (e, stackTrace) {
      _log.handle(e, stackTrace);
      rethrow;
    }
  }
}