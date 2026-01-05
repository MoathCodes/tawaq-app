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
    data: (data) {
      return PrayerService(repo, data, log);
    },
    loading: () {
      return PrayerService(repo, PrayerSettings.defaultSettings(), log);
    },
    error: (error, stackTrace) {
      log.e('Error loading settings', error: error, stackTrace: stackTrace);
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

  /// Adds or updates a prayer completion record.
  Future<void> addOrUpdateCompletion(PrayerCompletion completion) {
    return _repo.addOrUpdateCompletion(completion);
  }

  /// Computes the current and best streaks of fully completed prayer days.
  Future<({int current, int best})> computeStreaks(Location loc) async {
    try {
      final completedDays = await _repo.getFullyCompletedDays(loc);
      if (completedDays.isEmpty) return (current: 0, best: 0);

      var bestStreak = 0;
      var currentStreakLength = 0;
      DateTime? previousDay;

      // Process all completed days to find best streak and track current
      for (final currentDay in completedDays) {
        if (previousDay == null) {
          // First day
          currentStreakLength = 1;
        } else {
          final daysDiff = currentDay.difference(previousDay).inDays;
          if (daysDiff == 1) {
            // Consecutive day
            currentStreakLength++;
          } else {
            // Gap found - update best streak and reset counter
            if (currentStreakLength > bestStreak) {
              bestStreak = currentStreakLength;
            }
            currentStreakLength = 1;
          }
        }
        previousDay = currentDay;
      }

      // After loop, check if the last streak is the best
      if (currentStreakLength > bestStreak) {
        bestStreak = currentStreakLength;
      }

      // Determine current streak:
      // Current streak only counts if it includes today or yesterday
      var finalCurrentStreak = 0;
      if (previousDay != null) {
        final today = TZDateTime.now(loc);
        final todayDate = DateTime(today.year, today.month, today.day);
        final daysSinceLastCompletion = todayDate
            .difference(previousDay)
            .inDays;

        if (daysSinceLastCompletion == 0 || daysSinceLastCompletion == 1) {
          // Streak is active (today or yesterday was completed)
          finalCurrentStreak = currentStreakLength;
        }
        // else: streak is broken (last completion was 2+ days ago)
      }

      return (current: finalCurrentStreak, best: bestStreak);
    } catch (e, stackTrace) {
      _log.e('Error computing streaks', error: e, stackTrace: stackTrace);
      return (current: 0, best: 0);
    }
  }

  /// Counts all prayers completed within a given period.
  Future<int> countAllPrayersOnPeriod(
    PrayerAnalyticsPeriod period, [
    DateTime? date,
  ]) {
    final activeDate = date ?? _currentTime();
    final fromDate = activeDate.subtract(period.duration);
    final toDate = activeDate;
    return _repo.countAllPrayersOnDate(fromDate, toDate);
  }

  /// Counts all prayer statuses within a given period.
  Future<Map<CompletionStatus, int>> countAllStatusesOnPeriod(
    PrayerAnalyticsPeriod period, [
    DateTime? date,
  ]) {
    final activeDate = date ?? _currentTime();
    final fromDate = activeDate.subtract(period.duration);
    final toDate = activeDate;
    return _repo.countAllStatusesOnDate(fromDate, toDate);
  }

  /// Counts prayers with a specific status within a given period.
  Future<int> countPrayerOnPeriod(
    CompletionStatus status,
    PrayerAnalyticsPeriod period, [
    DateTime? date,
  ]) {
    final activeDate = date ?? _currentTime();
    final fromDate = activeDate.subtract(period.duration);
    final toDate = activeDate;
    return _repo.countPrayerStatusOnDate(status, fromDate, toDate);
  }

  /// Returns the current prayer based on the provided prayer times.
  Prayer currentPrayer(PrayerTimesData prayerTime) {
    final date = _currentTime();
    return prayerTime.currentPrayer(date: date);
  }

  /// Deletes a prayer completion record by its ID.
  Future<void> deleteCompletion(int id) {
    return _repo.deleteCompletion(id);
  }

  /// Checks if a prayer completion record exists for the given ID.
  Future<bool> doesCompletionExists(int id) {
    return _repo.doesCompletionExists(id);
  }

  /// Returns all prayer completion records.
  Future<List<PrayerCompletion>> getAllCompletions() {
    return _repo.getAllCompletions();
  }

  /// Returns a single prayer completion record by its ID.
  Future<PrayerCompletion?> getSingleCompletion(int id) {
    return _repo.getSingleCompletion(id);
  }

  /// Returns the Sunnah times for the given prayer times.
  SunnahTimes getSunnahTime(PrayerTimesData prayerTimes) {
    return _repo.getSunnahTime(prayerTimes);
  }

  /// Returns the prayer times for today (or a specific date).
  PrayerTimesData getTodaysPrayerTimes([
    DateTime? date,
    bool roundToMinutes = true,
  ]) {
    const logPrefix = '[PrayerService.getTodaysPrayerTimes] ';
    final activeDate = date ?? _currentTime();
    final params = _settings.customParameters ?? _settings.method.parameters;
    var prayerTimes = _repo.getPrayerTimes(
      activeDate,
      _settings.coordinates,
      params,
      roundToMinutes,
    );

    final isRamadan = Hijriyah.now().hMonth == 9;

    if (isRamadan && _settings.method == CalculationMethod.ummAlQura) {
      _log.d(
        '$logPrefix Method is Umm Al-Qura, and month is Ramadan, '
        'adjusting prayer times accordingly',
      );
      prayerTimes = prayerTimes.copyWith(
        isha: prayerTimes.isha.add(const Duration(minutes: 30)),
      );
    }

    return prayerTimes;
  }

  /// Returns the next prayer based on the provided prayer times.
  Prayer nextPrayerByDate(PrayerTimesData prayerTime, [DateTime? date]) {
    final activeDate = date ?? _currentTime();
    return prayerTime.nextPrayer(date: activeDate);
  }

  /// Returns the prayer completion records for a specific date.
  Future<List<PrayerCompletion>> getPrayerCompletionForDate([DateTime? date]) {
    final activeDate = date ?? _currentTime();

    return _repo.getPrayerCompletionForDate(activeDate);
  }

  TZDateTime _currentTime() {
    return TZDateTime.from(DateTime.now(), _settings.location);
  }
}
