import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hasanat/core/logging/talker_provider.dart';
import 'package:hasanat/core/utils/calculation_methods_extension.dart';
import 'package:hasanat/feature/prayer/data/models/prayer_completion.dart';
import 'package:hasanat/feature/prayer/data/repository/prayer_repo.dart';
import 'package:hasanat/feature/settings/data/models/prayer_settings_model.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hijri_date_time/hijri_date_time.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:timezone/timezone.dart';

export '../use_cases/compute_prayer_card_decision.dart'
    show computePrayerCardDecision;

part 'prayer_service.g.dart';

@riverpod
PrayerService prayerService(Ref ref) {
  final repo = ref.watch(prayerRepoProvider);
  final talker = ref.read(talkerNotifierProvider);
  final settings = ref.watch(prayerSettingsNotifierProvider);

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
  final PrayerRepo _repo;
  final PrayerSettings _settings;
  final Talker _log;

  PrayerService(this._repo, this._settings, this._log);

  // Future<void> addOrUpdateCompletion(PrayerCompletion completion) {
  //   return _repo.addOrUpdateCompletion(completion);
  // }

  Prayer currentPrayer(PrayerTimes prayerTime) {
    final date = _currentTime();
    return prayerTime.currentPrayer(date: date);
  }

  // Future<void> deleteCompletion(int id) {
  //   return _repo.deleteCompletion(id);
  // }

  // Future<List<PrayerCompletion>> getAllCompletions() {
  //   return _repo.getAllCompletions();
  // }

  // Future<PrayerCompletion?> getSingleCompletion(int id) {
  //   return _repo.getSingleCompletion(id);
  // }

  SunnahTimes getSunnahTime(PrayerTimes prayerTimes) {
    return _repo.getSunnahTime(prayerTimes);
  }

  PrayerTimes getTodaysPrayerTimes([DateTime? date]) {
    const logPrefix = "[PrayerService.getTodaysPrayerTimes] ";
    final activeDate = date ?? _currentTime();

    final prayerTimes = _repo.getPrayerTimes(
        activeDate, _settings.coordinates, _settings.method.parameters);

    final isRamadan = HijriDateTime.now().month == 9;

    if (isRamadan && _settings.method == CalculationMethod.ummAlQura) {
      _log.debug("$logPrefix Method is Umm Al-Qura, and month is Ramadan, "
          "adjusting prayer times accordingly");
      prayerTimes.isha =
          prayerTimes.isha.copyWith(minute: prayerTimes.isha.minute + 30);
    }

    return prayerTimes;
  }

  // Future<bool> isCompletionExists(int id) {
  //   return _repo.isCompletionExists(id);
  // }

  Prayer nextPrayerByDate(PrayerTimes prayerTime, [DateTime? date]) {
    final activeDate = date ?? _currentTime();
    return prayerTime.nextPrayer(date: activeDate);
  }

  // Stream<List<PrayerCompletion>> watchPrayerCompletionByDate([DateTime? date]) {
  //   final activeDate = date ?? _currentTime();

  //   return _repo.watchPrayerCompletionByDate(
  //     activeDate.year,
  //     activeDate.month,
  //     activeDate.day,
  //   );
  // }

  TZDateTime _currentTime() {
    return TZDateTime.from(DateTime.now(), _settings.location);
  }
}
