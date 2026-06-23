import 'package:adhan_dart/adhan_dart.dart';
import 'package:logger/logger.dart';
import 'package:tawaq/feature/prayer/data/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/data/repository/prayer_repo.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_analytics.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_analytics_calculator.dart';
import 'package:timezone/timezone.dart';

/// Service for prayer completion persistence and analytics queries.
class PrayerService {
  /// Creates a [PrayerService] instance.
  PrayerService(this._repo, this._log);

  final PrayerRepo _repo;
  final Logger _log;

  /// Adds or updates a prayer completion record.
  Future<void> addOrUpdateCompletion(
    PrayerCompletion completion,
    Location location,
  ) => _repo.addOrUpdateCompletion(completion, location);

  /// Computes the current and best streaks of fully completed prayer days.
  Future<({int current, int best})> computeStreaks(Location loc) async {
    try {
      final days = await _repo.getFullyCompletedDays(loc);
      if (days.isEmpty) return (current: 0, best: 0);

      final today = TZDateTime.now(loc);
      return PrayerAnalyticsCalculator.computeStreaks(
        fullyCompletedDays: days,
        today: DateTime(today.year, today.month, today.day),
      );
    } catch (e, st) {
      _log.e('Error computing streaks', error: e, stackTrace: st);
      return (current: 0, best: 0);
    }
  }

  /// Counts all prayer statuses within a given period.
  Future<Map<CompletionStatus, int>> countAllStatusesOnPeriod(
    PrayerAnalyticsPeriod period,
    Location location, [
    DateTime? date,
  ]) {
    final d = date ?? TZDateTime.now(location);
    final range = PrayerAnalyticsCalculator.periodCalendarRange(period, d);
    return _repo.countAllStatusesOnDate(
      range.start,
      range.end,
      location,
    );
  }

  /// Counts prayers with a specific status within a given period.
  Future<int> countPrayerOnPeriod(
    CompletionStatus status,
    PrayerAnalyticsPeriod period,
    Location location, [
    DateTime? date,
  ]) {
    final d = date ?? TZDateTime.now(location);
    return _repo.countPrayerStatusOnDate(
      status,
      d.subtract(period.duration),
      d,
      location,
    );
  }

  /// Deletes a prayer completion record by its ID.
  Future<void> deleteCompletion(int id) => _repo.deleteCompletion(id);

  /// Deletes all completion rows for [prayer] on [date]'s calendar day.
  Future<void> deleteCompletionForPrayerOnDate(
    Prayer prayer,
    DateTime date,
    Location location,
  ) =>
      _repo.deleteCompletionForPrayerOnDate(
        prayer,
        date,
        location,
      );

  /// Checks if a prayer completion record exists for the given ID.
  Future<bool> doesCompletionExists(int id) => _repo.doesCompletionExists(id);

  /// Returns all prayer completion records.
  Future<List<PrayerCompletion>> getAllCompletions() =>
      _repo.getAllCompletions();

  /// Returns the earliest logged completion time, if any.
  Future<DateTime?> getEarliestCompletionTime() =>
      _repo.getEarliestCompletionTime();

  /// Returns a single prayer completion record by its ID.
  Future<PrayerCompletion?> getSingleCompletion(int id) =>
      _repo.getSingleCompletion(id);

  /// Returns the prayer completion records for a specific date.
  Future<List<PrayerCompletion>> getPrayerCompletionForDate(
    DateTime date,
    Location location,
  ) => _repo.getPrayerCompletionForDate(date, location);

  /// Returns prayer completion records between [from] and [to] (inclusive).
  Future<List<PrayerCompletion>> getCompletionsBetween(
    DateTime from,
    DateTime to,
  ) => _repo.getCompletionsBetween(from, to);
}
