import 'package:adhan_dart/adhan_dart.dart';
import 'package:hasanat/core/logging/talker_provider.dart';
import 'package:hasanat/core/utils/prayer_extensions.dart';
import 'package:hasanat/feature/prayer/data/models/prayer_completion.dart';
import 'package:hasanat/feature/prayer/data/repository/prayer_repo.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_analytics.dart';
import 'package:hasanat/feature/settings/data/models/prayer_settings_model.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hijriyah_indonesia/hijriyah_indonesia.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:timezone/timezone.dart';

export '../use_cases/compute_prayer_card_decision.dart'
    show computePrayerCardDecision;

part 'prayer_service.g.dart';

@riverpod
PrayerService prayerService(Ref ref) {
  final repo = ref.watch(prayerRepoProvider);
  final talker = ref.read(talkerProvider);
  final settings = ref.watch(prayerSettingsProvider);

  return settings.when(
    data: (data) {
      return PrayerService(repo, data, talker);
    },
    loading: () {
      return PrayerService(repo, PrayerSettings.defaultSettings(), talker);
    },
    error: (error, stackTrace) {
      talker.handle(error, stackTrace);
      return PrayerService(repo, PrayerSettings.defaultSettings(), talker);
    },
  );
}

class PrayerService {
  PrayerService(this._repo, this._settings, this._log);
  final PrayerRepo _repo;
  final PrayerSettings _settings;
  final Talker _log;

  Future<void> addOrUpdateCompletion(PrayerCompletion completion) {
    return _repo.addOrUpdateCompletion(completion);
  }

  Future<({int current, int best})> computeStreaks(Location loc) async {
    try {
      final completedDays = await _repo.getFullyCompletedDays(loc);
      if (completedDays.isEmpty) return (current: 0, best: 0);

      var bestStreak = 0;
      var currentStreak = 0;
      var consecutiveDays = 0;
      DateTime? previousDay;

      for (final currentDay in completedDays) {
        if (previousDay == null ||
            currentDay.difference(previousDay).inDays == 1) {
          consecutiveDays++;
        } else {
          bestStreak = consecutiveDays > bestStreak
              ? consecutiveDays
              : bestStreak;
          consecutiveDays = 1;
        }
        previousDay = currentDay;
      }
      bestStreak = consecutiveDays > bestStreak ? consecutiveDays : bestStreak;

      final today = DateTime.now().toLocation(loc);
      if (previousDay != null && today.difference(previousDay).inDays == 0) {
        currentStreak = consecutiveDays;
      } else {
        currentStreak = 0;
      }
      return (current: currentStreak, best: bestStreak);
    } catch (e, stackTrace) {
      _log.handle(e, stackTrace);
      return (current: 0, best: 0);
    }
  }

  Future<int> countAllPrayersOnPeriod(
    PrayerAnalyticsPeriod period, [
    DateTime? date,
  ]) {
    final activeDate = date ?? _currentTime();
    final fromDate = activeDate.subtract(period.duration);
    final toDate = activeDate;
    return _repo.countAllPrayersOnDate(fromDate, toDate);
  }

  Future<Map<CompletionStatus, int>> countAllStatusesOnPeriod(
    PrayerAnalyticsPeriod period, [
    DateTime? date,
  ]) {
    final activeDate = date ?? _currentTime();
    final fromDate = activeDate.subtract(period.duration);
    final toDate = activeDate;
    return _repo.countAllStatusesOnDate(fromDate, toDate);
  }

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

  Prayer currentPrayer(PrayerTimesData prayerTime) {
    final date = _currentTime();
    return prayerTime.currentPrayer(date: date);
  }

  Future<void> deleteCompletion(int id) {
    return _repo.deleteCompletion(id);
  }

  Future<bool> doesCompletionExists(int id) {
    return _repo.doesCompletionExists(id);
  }

  Future<List<PrayerCompletion>> getAllCompletions() {
    return _repo.getAllCompletions();
  }

  Future<PrayerCompletion?> getSingleCompletion(int id) {
    return _repo.getSingleCompletion(id);
  }

  SunnahTimes getSunnahTime(PrayerTimesData prayerTimes) {
    return _repo.getSunnahTime(prayerTimes);
  }

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
      _log.debug(
        '$logPrefix Method is Umm Al-Qura, and month is Ramadan, '
        'adjusting prayer times accordingly',
      );
      prayerTimes = prayerTimes.copyWith(
        isha: prayerTimes.isha.add(const Duration(minutes: 30)),
      );
    }

    return prayerTimes;
  }

  Prayer nextPrayerByDate(PrayerTimesData prayerTime, [DateTime? date]) {
    final activeDate = date ?? _currentTime();
    return prayerTime.nextPrayer(date: activeDate);
  }

  Future<List<PrayerCompletion>> getPrayerCompletionForDate([DateTime? date]) {
    final activeDate = date ?? _currentTime();

    return _repo.getPrayerCompletionForDate(
      activeDate
    );
  }

  TZDateTime _currentTime() {
    return TZDateTime.from(DateTime.now(), _settings.location);
  }
}
