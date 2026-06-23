import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivez_flutter/hivez_flutter.dart';
import 'package:logger/logger.dart';
import 'package:tawaq/feature/prayer/data/database/prayer_database.dart';
import 'package:tawaq/feature/prayer/data/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/data/repository/prayer_repo.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_time_inputs.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_day_computer.dart';
import 'package:tawaq/feature/prayer/domain/use_cases/compute_prayer_card_decision.dart';
import 'package:tawaq/feature/settings/data/models/prayer_settings_model.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart';

PrayerTimeInputs inputsFromSettings(PrayerSettings settings) => PrayerTimeInputs(
      method: settings.method,
      coordinates: settings.coordinates,
      location: settings.location,
    );

void main() {
  setUpAll(tz.initializeTimeZones);

  group('Prayer Card Decision Tests', () {
    late Location location;
    late PrayerRepo repo;
    late PrayerSettings settings;
    late PrayerTimeInputs inputs;

    setUpAll(() {
      location = getLocation('Asia/Riyadh');
      final box = Box<int, PrayerCompletion>(
        'card_decision_${DateTime.now().microsecondsSinceEpoch}',
      );
      repo = PrayerRepo(
        prayerDatabase: PrayerDatabase(box),
        log: Logger(),
      );
      settings = PrayerSettings.defaultSettings().copyWith(
        coordinates: const Coordinates(24.7136, 46.6753),
        location: location,
      );
      inputs = inputsFromSettings(settings);
    });

    test(
      'Prayer decision at 11:15 PM should show midnight as next prayer '
      'with correct time source',
      () {
        final testTime = TZDateTime(location, 2024, 1, 15, 23, 15);
        final bundle = computePrayerDayBundle(
          inputs: inputs,
          anchorNow: testTime,
          repo: repo,
        )!;
        final yesterdayBundle = computePrayerDayBundle(
          inputs: inputs,
          anchorNow: testTime.subtract(const Duration(days: 1)),
          repo: repo,
        )!;

        final decision = computePrayerCardDecision(
          currentTime: testTime,
          location: location,
          todaysPrayerTimes: bundle.today,
          yesterdaysPrayerTimes: yesterdayBundle.today,
          todaysSunnahTimes: bundle.todaySunnah,
          yesterdaysSunnahTimes: yesterdayBundle.todaySunnah,
        );

        expect(decision.prayer, equals(Prayer.fajrAfter));
      },
    );

    test('Prayer decision after midnight should show last third of night', () {
      final testTime = TZDateTime(location, 2024, 1, 16, 0, 30);
      final bundle = computePrayerDayBundle(
        inputs: inputs,
        anchorNow: testTime,
        repo: repo,
      )!;
      final yesterdayBundle = computePrayerDayBundle(
        inputs: inputs,
        anchorNow: testTime.subtract(const Duration(days: 1)),
        repo: repo,
      )!;

      final decision = computePrayerCardDecision(
        currentTime: testTime,
        location: location,
        todaysPrayerTimes: bundle.today,
        yesterdaysPrayerTimes: yesterdayBundle.today,
        todaysSunnahTimes: bundle.todaySunnah,
        yesterdaysSunnahTimes: yesterdayBundle.todaySunnah,
      );

      expect(decision.prayer, equals(Prayer.ishaBefore));
    });
  });
}
