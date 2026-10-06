import 'dart:io';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:hivez_flutter/hivez_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/bootstrap/app_init_providers.dart';
import 'package:tawaq/core/utils/prayer_extensions.dart';
import 'package:tawaq/feature/prayer/data/database/prayer_history_migration.dart';
import 'package:tawaq/feature/prayer/domain/completion_dedup.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_completion.dart';
import 'package:timezone/timezone.dart';

part 'prayer_database.g.dart';

/// Provides a singleton instance of the [PrayerDatabase].
@Riverpod(keepAlive: true)
PrayerDatabase prayerDatabase(Ref ref) {
  final storageReady = ref.watch(hiveCoreInitProvider.future);
  final completionBox = Box<int, PrayerCompletion>('prayer_completions');
  final prayerDatabase = PrayerDatabase(
    completionBox,
    initialize: () async {
      await storageReady;
      // The database gates every consumer until the approved cleanup finishes.
      await completionBox.getAllKeys();
      final boxPath = completionBox.path;
      if (boxPath == null)
        throw StateError('Prayer history has no storage path');
      final migration = PrayerHistoryMigration(
        completionBox,
        Directory(p.join(p.dirname(boxPath), 'migrations', 'prayer-history')),
      );
      final digest = await migration.prepare();
      await migration.apply(approvedBackupSha256: digest);
    },
  );
  ref.onDispose(() async {
    await prayerDatabase.close();
  });
  return prayerDatabase;
}

/// Prevents mounting the app's history consumers before storage migration.
@Riverpod(keepAlive: true)
Future<void> prayerHistoryReady(Ref ref) =>
    ref.watch(prayerDatabaseProvider).ready;

/// The database for the prayer data.
class PrayerDatabase {
  /// Creates a new instance of the [PrayerDatabase].
  new(this._box, {Future<void> Function()? initialize})
    : _initialize = initialize;
  final Box<int, PrayerCompletion> _box;
  final Future<void> Function()? _initialize;

  /// Shared initialization barrier for reads, writes, analytics and repair.
  Future<void> get ready => _ready ??= _initializeOnce();
  Future<void>? _ready;

  Future<void> _initializeOnce() async {
    try {
      final initialize = _initialize;
      if (initialize != null) await Future<void>.sync(initialize);
    } on Object {
      _ready = null;
      rethrow;
    }
  }

  /// Waits for an active migration before closing its storage handle.
  Future<void> close() async {
    try {
      await _ready;
    } on Object {
      // A failed initialization has already retained its recovery journal.
    }
    await _box.closeBox();
  }

  /// Deletes a prayer completion by Hive key.
  Future<void> deleteCompletion(int id) async {
    await ready;
    await _box.delete(id);
  }

  /// Deletes all completions for [prayer] on [date]'s calendar day.
  Future<void> deleteCompletionForPrayerOnDate(
    Prayer prayer,
    DateTime date,
    Location location,
  ) async {
    await ready;
    final keys = await _findAllMatchingKeys(prayer, date, location);
    for (final key in keys) {
      await _box.delete(key);
    }
  }

  /// Returns all prayer completions.
  Future<List<PrayerCompletion>> getAllCompletions() async {
    await ready;
    final values = await _box.getAllValues();
    return values.toList();
  }

  /// Returns the earliest logged completion time, if any.
  Future<DateTime?> getEarliestCompletionTime() async {
    await ready;
    final values = await _box.getAllValues();
    if (values.isEmpty) return null;

    var earliest = values.first.completionTime;
    for (final completion in values) {
      if (completion.completionTime.isBefore(earliest)) {
        earliest = completion.completionTime;
      }
    }
    return earliest;
  }

  /// Returns a prayer completion by its ID.
  Future<PrayerCompletion?> getCompletionById(int id) async {
    await ready;
    return _box.get(id);
  }

  /// Returns deduped completions for a calendar day in [location].
  Future<List<PrayerCompletion>> getCompletionsForDate(
    DateTime date,
    Location location,
  ) async {
    await ready;
    final completions = await _box.getValuesWhere((value) {
      return value.completionTime.isSameCalendarDay(date, location);
    });

    return dedupeCompletions(completions.toList(), location);
  }

  /// Inserts or updates a prayer completion.
  ///
  /// Collapses duplicate rows for the same prayer on the same calendar day.
  Future<void> insertOrUpdateCompletion(
    PrayerCompletion completion,
    Location location,
  ) async {
    await ready;
    final matchingKeys = await _findAllMatchingKeys(
      completion.prayer,
      completion.completionTime,
      location,
    );

    if (matchingKeys.isNotEmpty) {
      final existingRows = <PrayerCompletion>[];
      for (final key in matchingKeys) {
        final row = await _box.get(key);
        if (row != null) {
          existingRows.add(row.copyWith(id: key));
        }
      }
      final canonical = pickCanonical(
        existingRows,
        prayer: completion.prayer,
        location: location,
        day: completion.completionTime,
      );
      final canonicalId = canonical?.id ?? matchingKeys.first;
      await _box.put(
        canonicalId,
        completion.copyWith(
          id: canonicalId,
          completionTime:
              canonical?.completionTime ?? completion.completionTime,
        ),
      );
      for (final key in matchingKeys) {
        if (key != canonicalId) {
          await _box.delete(key);
        }
      }
      return;
    }

    if (completion.id != null && await _box.containsKey(completion.id!)) {
      await _box.put(completion.id!, completion);
      return;
    }

    final id = await _box.add(completion);
    await _box.put(id, completion.copyWith(id: id));
  }

  /// Removes duplicate rows, keeping the canonical row per prayer+day.
  Future<int> repairDuplicates(Location location) async {
    await ready;
    final keys = await _box.getAllKeys();
    final groups = <String, List<({int key, PrayerCompletion value})>>{};

    for (final key in keys) {
      final value = await _box.get(key);
      if (value == null) continue;
      final groupKey = completionGroupKey(value, location);
      groups.putIfAbsent(groupKey, () => []).add((key: key, value: value));
    }

    var removed = 0;
    for (final entries in groups.values) {
      // Fixtures and imported legacy rows can bypass startup migration.
      // Never discard a positive row behind a missed row during repair.
      if (entries.any((entry) => entry.value.status == CompletionStatus.missed))
        continue;
      if (entries.length <= 1) continue;

      final rows = [
        for (final entry in entries) entry.value.copyWith(id: entry.key),
      ];
      final canonical = rows.reduce(preferCanonicalCompletion);
      final canonicalId = canonical.id!;

      for (final entry in entries) {
        if (entry.key == canonicalId) {
          await _box.put(entry.key, canonical);
        } else {
          await _box.delete(entry.key);
          removed++;
        }
      }
    }
    return removed;
  }

  Future<List<int>> _findAllMatchingKeys(
    Prayer prayer,
    DateTime date,
    Location location,
  ) async {
    final keys = await _box.getAllKeys();
    final matches = <int>[];
    for (final key in keys) {
      final value = await _box.get(key);
      if (value != null &&
          value.prayer == prayer &&
          value.completionTime.isSameCalendarDay(date, location)) {
        matches.add(key);
      }
    }
    return matches;
  }
}
