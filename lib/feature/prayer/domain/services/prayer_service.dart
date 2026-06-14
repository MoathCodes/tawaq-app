import 'package:adhan_dart/adhan_dart.dart';
import 'package:hijri_date/hijri.dart';
import 'package:logger/logger.dart';
import 'package:tawaq/feature/prayer/data/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/data/repository/prayer_repo.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_analytics.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_analytics_calculator.dart';
import 'package:tawaq/feature/settings/data/models/prayer_settings_model.dart';
import 'package:timezone/timezone.dart';

export '../use_cases/compute_prayer_card_decision.dart'
    show computePrayerCardDecision;

/// Service class for prayer-related operations.
class PrayerService {
  /// Creates a [PrayerService] instance.
  PrayerService(this._repo, this._settings, this._log);
  final PrayerRepo _repo;
  final PrayerSettings _settings;
  final Logger _log;

  TZDateTime _now() => TZDateTime.now(_settings.location);

  /// Adds or updates a prayer completion record.
  Future<void> addOrUpdateCompletion(PrayerCompletion c) =>
      _repo.addOrUpdateCompletion(c, _settings.location);

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
    PrayerAnalyticsPeriod period, [
    DateTime? date,
  ]) {
    final d = date ?? _now();
    final range = PrayerAnalyticsCalculator.periodCalendarRange(period, d);
    return _repo.countAllStatusesOnDate(
      range.start,
      range.end,
      _settings.location,
    );
  }

  /// Counts prayers with a specific status within a given period.
  Future<int> countPrayerOnPeriod(
    CompletionStatus status,
    PrayerAnalyticsPeriod period, [
    DateTime? date,
  ]) {
    final d = date ?? _now();
    return _repo.countPrayerStatusOnDate(
      status,
      d.subtract(period.duration),
      d,
      _settings.location,
    );
  }

  /// Returns the current prayer based on the provided prayer times.
  Prayer currentPrayer(PrayerTimes t) => t.currentPrayer(time: _now());

  /// Deletes a prayer completion record by its ID.
  Future<void> deleteCompletion(int id) => _repo.deleteCompletion(id);

  /// Deletes all completion rows for [prayer] on [date]'s calendar day.
  Future<void> deleteCompletionForPrayerOnDate(Prayer prayer, DateTime date) =>
      _repo.deleteCompletionForPrayerOnDate(
        prayer,
        date,
        _settings.location,
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

  /// Returns the Sunnah times for the given prayer times.
  SunnahTimes getSunnahTime(PrayerTimes t) => _repo.getSunnahTime(t);

  /// Returns prayer times for [date] or today using saved settings.
  ///
  /// During Ramadan with [UmmAlQura], Isha is extended by 30 minutes.
  PrayerTimes getTodaysPrayerTimes(
    DateTime? date, {
    bool roundToMinutes = true,
  }) {
    var times = _repo.getPrayerTimes(
      date ?? _now(),
      _settings.coordinates,
      _settings.method,
      roundToMinutes: roundToMinutes,
    );
    final anchor = date ?? _now();
    if (HijriDate.fromDate(anchor).hMonth == 9 &&
        _settings.method is UmmAlQura) {
      _log.d('Adjusting Isha for Ramadan');
      times = times.copyWith(isha: times.isha.add(const Duration(minutes: 30)));
    }
    return times;
  }

  /// Returns the next prayer based on the provided prayer times.
  Prayer nextPrayerByDate(PrayerTimes t, [DateTime? date]) =>
      t.nextPrayer(time: date ?? _now());

  /// Returns the prayer completion records for a specific date.
  Future<List<PrayerCompletion>> getPrayerCompletionForDate([DateTime? date]) =>
      _repo.getPrayerCompletionForDate(date ?? _now(), _settings.location);

  /// Returns prayer completion records between [from] and [to] (inclusive).
  Future<List<PrayerCompletion>> getCompletionsBetween(
    DateTime from,
    DateTime to,
  ) => _repo.getCompletionsBetween(from, to);
}
