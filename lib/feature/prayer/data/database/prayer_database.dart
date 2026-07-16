import 'package:adhan_dart/adhan_dart.dart';
import 'package:hivez_flutter/hivez_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/bootstrap/app_init_providers.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/core/utils/prayer_extensions.dart';
import 'package:tawaq/feature/prayer/data/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/domain/completion_dedup.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_day.dart';
import 'package:timezone/timezone.dart';

part 'prayer_database.g.dart';

const _repairMetaKey = 'repaired_v1';

/// Provides a singleton instance of the [PrayerDatabase].
@Riverpod(keepAlive: true)
PrayerDatabase prayerDatabase(Ref ref) {
  ref.watch(hiveCoreInitProvider);
  final completionBox = Box<int, PrayerCompletion>('prayer_completions');
  final prayerDatabase = PrayerDatabase(completionBox);
  ref.onDispose(() async {
    await completionBox.closeBox();
  });
  return prayerDatabase;
}

/// One-time duplicate repair for legacy prayer completion rows.
///
/// Defers until [prayerTimeInputsProvider] has a real prayer location so
/// grouping keys match completion calendar days. Does not mark repaired when
/// only a device-local fallback would be available.
@Riverpod(keepAlive: true)
Future<void> prayerCompletionsRepair(Ref ref) async {
  await ref.watch(hiveCoreInitProvider.future);
  final repairedBox = Box<String, int>('prayer_completions_meta');
  final alreadyRepaired = (await repairedBox.get(_repairMetaKey) ?? 0) == 1;
  if (alreadyRepaired) return;

  final inputs = ref.watch(prayerTimeInputsProvider);
  if (inputs == null) return;

  final removed = await ref
      .read(prayerDatabaseProvider)
      .repairDuplicates(inputs.location);

  if (removed > 0) {
    ref.read(loggerProvider).i(
      'Repaired $removed duplicate prayer completion row(s)',
    );
  }

  await repairedBox.put(_repairMetaKey, 1);
}

/// The database for the prayer data.
class PrayerDatabase {
  /// Creates a new instance of the [PrayerDatabase].
  PrayerDatabase(this._box);
  final Box<int, PrayerCompletion> _box;

  /// Deletes a prayer completion by Hive key.
  Future<void> deleteCompletion(int id) async {
    await _box.delete(id);
  }

  /// Deletes all completions for [prayer] on [date]'s calendar day.
  Future<void> deleteCompletionForPrayerOnDate(
    Prayer prayer,
    DateTime date,
    Location location,
  ) async {
    final keys = await _findAllMatchingKeys(prayer, date, location);
    for (final key in keys) {
      await _box.delete(key);
    }
  }

  /// Returns all prayer completions.
  Future<List<PrayerCompletion>> getAllCompletions() async {
    final values = await _box.getAllValues();
    return values.toList();
  }

  /// Returns the earliest logged completion time, if any.
  Future<DateTime?> getEarliestCompletionTime() async {
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
    return _box.get(id);
  }

  /// Returns deduped completions for a calendar day in [location].
  Future<List<PrayerCompletion>> getCompletionsForDate(
    DateTime date,
    Location location,
  ) async {
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
          completionTime: canonical?.completionTime ?? completion.completionTime,
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
      if (entries.length <= 1) continue;

      final rows = [
        for (final entry in entries)
          entry.value.copyWith(id: entry.key),
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
