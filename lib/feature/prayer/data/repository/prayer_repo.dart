import 'package:adhan_dart/adhan_dart.dart';
import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/core/utils/date_extensions.dart';
import 'package:tawaq/feature/prayer/data/database/prayer_database.dart';
import 'package:tawaq/feature/prayer/data/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/domain/completion_dedup.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_analysis_section.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_analytics.dart';
import 'package:tawaq/feature/prayer/domain/prayer_calendar.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_analytics_calculator.dart';
import 'package:timezone/timezone.dart';

part 'prayer_repo.g.dart';

/// Provides a singleton instance of the [PrayerRepo].
@Riverpod(keepAlive: true)
PrayerRepo prayerRepo(Ref ref) {
  ref.watch(prayerCompletionsRepairProvider);
  final database = ref.read(prayerDatabaseProvider);
  final log = ref.read(loggerProvider);
  return PrayerRepo(prayerDatabase: database, log: log);
}

/// A repository for accessing prayer data with an in-memory day-key index.
class PrayerRepo {
  /// Creates a new instance of the [PrayerRepo].
  PrayerRepo({required this.prayerDatabase, required this.log});

  /// The database for the prayer data.
  final PrayerDatabase prayerDatabase;

  /// The logger for the application.
  final Logger log;

  final Map<int, List<PrayerCompletion>> _byDayKey = {};
  final Map<int, Map<CompletionStatus, int>> _statusCountsByDayKey = {};
  final List<int> _fullyCompletedDayKeys = [];
  Location? _indexedLocation;
  bool _indexLoaded = false;
  ({int current, int best})? _cachedStreaks;
  DateTime? _cachedStreaksToday;

  /// Adds or updates a prayer completion.
  Future<void> addOrUpdateCompletion(
    PrayerCompletion completion,
    Location location,
  ) async {
    try {
      await prayerDatabase.insertOrUpdateCompletion(completion, location);
      await _refreshDayInIndex(completion.completionTime, location);
    } catch (e, stackTrace) {
      log.e(
        'Error adding/updating completion',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Counts deduped completion statuses between [from] and [to].
  Future<Map<CompletionStatus, int>> countAllStatusesOnDate(
    DateTime from,
    DateTime to,
    Location location,
  ) async {
    await _ensureIndex(location);
    final fromKey = completionDayKey(from, location);
    final toKey = completionDayKey(to, location);
    final counts = _emptyStatusCounts();
    for (final entry in _statusCountsByDayKey.entries) {
      if (entry.key < fromKey || entry.key > toKey) continue;
      for (final status in CompletionStatus.values) {
        counts[status] = (counts[status] ?? 0) + (entry.value[status] ?? 0);
      }
    }
    return counts;
  }

  /// Counts deduped status totals for [period] ending on [anchor]'s calendar day.
  Future<Map<CompletionStatus, int>> countAllStatusesOnPeriod(
    PrayerAnalyticsPeriod period,
    Location location,
    DateTime anchor,
  ) async {
    final range = PrayerAnalyticsCalculator.periodCalendarRange(period, anchor);
    return countAllStatusesOnDate(range.start, range.end, location);
  }

  /// Computes current and best streaks from the maintained day index.
  Future<({int current, int best})> computeStreaks(Location location) async {
    await _ensureIndex(location);
    final today = TZDateTime.now(location);
    final todayNorm = DateTime(today.year, today.month, today.day);
    if (_cachedStreaks != null && _cachedStreaksToday == todayNorm) {
      return _cachedStreaks!;
    }

    final days = _fullyCompletedDayKeys.map(dateFromCalendarDayKey).toList();
    final result = PrayerAnalyticsCalculator.computeStreaks(
      fullyCompletedDays: days,
      today: todayNorm,
    );
    _cachedStreaks = result;
    _cachedStreaksToday = todayNorm;
    return result;
  }

  /// Deletes a prayer completion.
  Future<void> deleteCompletion(int id, Location location) async {
    final existing = await prayerDatabase.getCompletionById(id);
    await prayerDatabase.deleteCompletion(id);
    if (existing != null) {
      await _refreshDayInIndex(existing.completionTime, location);
    } else {
      _invalidateIndex();
    }
  }

  /// Deletes all completions for [prayer] on [date]'s calendar day.
  Future<void> deleteCompletionForPrayerOnDate(
    Prayer prayer,
    DateTime date,
    Location location,
  ) async {
    await prayerDatabase.deleteCompletionForPrayerOnDate(
      prayer,
      date,
      location,
    );
    await _refreshDayInIndex(date, location);
  }

  /// Returns the earliest logged completion time, if any.
  Future<DateTime?> getEarliestCompletionTime() {
    return prayerDatabase.getEarliestCompletionTime();
  }

  /// Returns prayer completions recorded on [date].
  Future<List<PrayerCompletion>> getPrayerCompletionForDate(
    DateTime date,
    Location location,
  ) async {
    await _ensureIndex(location);
    final dayKey = completionDayKey(date, location);
    final raw = _byDayKey[dayKey] ?? const [];
    return dedupeCompletions(raw, location);
  }

  /// Returns deduped completions whose calendar day falls in [from, to].
  Future<List<PrayerCompletion>> getCompletionsBetween(
    DateTime from,
    DateTime to,
    Location location,
  ) async {
    await _ensureIndex(location);
    final fromKey = completionDayKey(from, location);
    final toKey = completionDayKey(to, location);
    final result = <PrayerCompletion>[];
    for (final entry in _byDayKey.entries) {
      if (entry.key < fromKey || entry.key > toKey) continue;
      result.addAll(dedupeCompletions(entry.value, location));
    }
    return result
        .where((c) => c.completionTime.isBetween(from, to))
        .toList();
  }

  /// Returns the prayer times for a given date, coordinates, and calculation
  /// parameters.
  PrayerTimes getPrayerTimes(
    DateTime date,
    Coordinates coordinates,
    CalculationMethod calculationMethod, {
    bool roundToMinutes = true,
  }) {
    return PrayerTimes(
      date: date,
      coordinates: coordinates,
      calculationMethod: calculationMethod,
      roundToMinutes: roundToMinutes,
    );
  }

  /// Returns the sunnah times for a given prayer times.
  SunnahTimes getSunnahTime(PrayerTimes prayerTimes) {
    return SunnahTimes(prayerTimes);
  }

  Future<void> _ensureIndex(Location location) async {
    if (_indexLoaded && _indexedLocation == location) return;
    await _rebuildIndex(location);
  }

  Future<void> _rebuildIndex(Location location) async {
    _byDayKey.clear();
    _statusCountsByDayKey.clear();
    _fullyCompletedDayKeys.clear();
    _cachedStreaks = null;
    _cachedStreaksToday = null;

    final all = await prayerDatabase.getAllCompletions();
    for (final completion in all) {
      final dayKey = completionDayKey(completion.completionTime, location);
      _byDayKey.putIfAbsent(dayKey, () => []).add(completion);
    }

    for (final dayKey in _byDayKey.keys.toList()..sort()) {
      _recomputeDayBucket(dayKey, location);
    }

    _indexedLocation = location;
    _indexLoaded = true;
  }

  Future<void> _refreshDayInIndex(DateTime date, Location location) async {
    await _ensureIndex(location);
    final dayKey = completionDayKey(date, location);
    final fresh = await prayerDatabase.getCompletionsForDate(date, location);
    if (fresh.isEmpty) {
      _byDayKey.remove(dayKey);
    } else {
      _byDayKey[dayKey] = fresh;
    }
    _recomputeDayBucket(dayKey, location);
  }

  void _recomputeDayBucket(int dayKey, Location location) {
    final raw = _byDayKey[dayKey];
    if (raw == null || raw.isEmpty) {
      _statusCountsByDayKey.remove(dayKey);
      _fullyCompletedDayKeys.remove(dayKey);
      _cachedStreaks = null;
      return;
    }

    final deduped = dedupeCompletions(raw, location);
    _statusCountsByDayKey[dayKey] = countDedupedStatuses(deduped, location);
    _updateFullyCompletedDayKey(dayKey, deduped, location);
  }

  void _updateFullyCompletedDayKey(
    int dayKey,
    List<PrayerCompletion> deduped,
    Location location,
  ) {
    final statuses = mapPrayerStatuses(
      deduped,
      location,
      dateFromCalendarDayKey(dayKey),
    );
    final complete = kObligatoryPrayers.every((prayer) {
      final status = statuses[prayer] ?? CompletionStatus.none;
      return status != CompletionStatus.none &&
          status != CompletionStatus.missed;
    });

    final index = _fullyCompletedDayKeys.indexOf(dayKey);
    if (complete && index == -1) {
      _fullyCompletedDayKeys.add(dayKey);
      _fullyCompletedDayKeys.sort();
    } else if (!complete && index != -1) {
      _fullyCompletedDayKeys.removeAt(index);
    }
    _cachedStreaks = null;
  }

  void _invalidateIndex() {
    _indexLoaded = false;
    _indexedLocation = null;
    _byDayKey.clear();
    _statusCountsByDayKey.clear();
    _fullyCompletedDayKeys.clear();
    _cachedStreaks = null;
    _cachedStreaksToday = null;
  }

  Map<CompletionStatus, int> _emptyStatusCounts() {
    return {
      for (final status in CompletionStatus.values) status: 0,
    };
  }
}
