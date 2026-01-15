import 'package:adhan_dart/adhan_dart.dart';
import 'package:hasanat/core/logging/logger_provider.dart';
import 'package:hasanat/feature/prayer/data/models/prayer_completion.dart';
import 'package:hasanat/feature/prayer/data/repository/prayer_repo.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_analytics.dart';
import 'package:hasanat/feature/settings/data/models/prayer_settings_model.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hijriyah_indonesia/hijriyah_indonesia.dart';
import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timezone/timezone.dart';

export '../use_cases/compute_prayer_card_decision.dart'
    show computePrayerCardDecision;

part 'prayer_service.g.dart';

/// Provider for the [PrayerService].
@riverpod
PrayerService prayerService(Ref ref) {
  final repo = ref.watch(prayerRepoProvider);
  final log = ref.read(loggerProvider);
  final settings = ref.watch(prayerSettingsProvider);

  return settings.when(
    data: (d) => PrayerService(repo, d, log),
    loading: () => PrayerService(repo, PrayerSettings.defaultSettings(), log),
    error: (e, st) {
      log.e('Error loading settings', error: e, stackTrace: st);
      return PrayerService(repo, PrayerSettings.defaultSettings(), log);
    },
  );
}

/// Service class for prayer-related operations.
class PrayerService {
  /// Creates a [PrayerService] instance.
  PrayerService(this._repo, this._settings, this._log);
  final PrayerRepo _repo;
  final PrayerSettings _settings;
  final Logger _log;

  TZDateTime _now() => TZDateTime.from(DateTime.now(), _settings.location);

  /// Adds or updates a prayer completion record.
  Future<void> addOrUpdateCompletion(PrayerCompletion c) =>
      _repo.addOrUpdateCompletion(c);

  /// Computes the current and best streaks of fully completed prayer days.
  Future<({int current, int best})> computeStreaks(Location loc) async {
    try {
      final days = await _repo.getFullyCompletedDays(loc);
      if (days.isEmpty) return (current: 0, best: 0);

      var best = 0, streak = 0;
      DateTime? prev;

      for (final day in days) {
        if (prev == null) {
          streak = 1;
        } else if (day.difference(prev).inDays == 1) {
          streak++;
        } else {
          if (streak > best) best = streak;
          streak = 1;
        }
        prev = day;
      }
      if (streak > best) best = streak;

      var current = 0;
      if (prev != null) {
        final today = TZDateTime.now(loc);
        final diff = DateTime(
          today.year,
          today.month,
          today.day,
        ).difference(prev).inDays;
        if (diff <= 1) current = streak;
      }
      return (current: current, best: best);
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
    return _repo.countAllStatusesOnDate(d.subtract(period.duration), d);
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
    );
  }

  /// Returns the current prayer based on the provided prayer times.
  Prayer currentPrayer(PrayerTimes t) => t.currentPrayer(time: _now());

  /// Deletes a prayer completion record by its ID.
  Future<void> deleteCompletion(int id) => _repo.deleteCompletion(id);

  /// Checks if a prayer completion record exists for the given ID.
  Future<bool> doesCompletionExists(int id) => _repo.doesCompletionExists(id);

  /// Returns all prayer completion records.
  Future<List<PrayerCompletion>> getAllCompletions() =>
      _repo.getAllCompletions();

  /// Returns a single prayer completion record by its ID.
  Future<PrayerCompletion?> getSingleCompletion(int id) =>
      _repo.getSingleCompletion(id);

  /// Returns the Sunnah times for the given prayer times.
  SunnahTimes getSunnahTime(PrayerTimes t) => _repo.getSunnahTime(t);

  /// Returns the prayer times for today (or a specific date).
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
    if (Hijriyah.now().hMonth == 9 && _settings.method is UmmAlQura) {
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
      _repo.getPrayerCompletionForDate(date ?? _now());
}
