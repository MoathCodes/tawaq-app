import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_time_inputs.dart';
import 'package:tawaq/feature/prayer/domain/prayer_slots.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_day_computer.dart';
import 'package:tawaq/feature/settings/data/models/prayer_settings_model.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart';

PrayerTimeInputs inputsFromSettings(PrayerSettings settings) =>
    PrayerTimeInputs(
      method: settings.method,
      coordinates: settings.coordinates,
      location: settings.location,
    );

void main() {
  setUpAll(tz.initializeTimeZones);

  group('Prayer Card Decision Tests', () {
    late Location location;
    late PrayerSettings settings;
    late PrayerTimeInputs inputs;

    setUpAll(() {
      location = getLocation('Asia/Riyadh');
      settings = PrayerSettings.defaultSettings().copyWith(
        coordinates: Coordinates(24.7136, 46.6753),
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
        )!;

        final decision = computePrayerCardDecisionFromParts(
          currentTime: testTime,
          location: location,
          timeline: bundle.timeline,
          todaysPrayerTimes: bundle.today,
        );

        expect(decision.prayer, equals(Prayer.fajrAfter));
      },
    );

    test('Prayer decision after midnight should show last third of night', () {
      final testTime = TZDateTime(location, 2024, 1, 16, 0, 30);
      final bundle = computePrayerDayBundle(
        inputs: inputs,
        anchorNow: testTime,
      )!;

      final decision = computePrayerCardDecisionFromParts(
        currentTime: testTime,
        location: location,
        timeline: bundle.timeline,
        todaysPrayerTimes: bundle.today,
      );

      expect(decision.prayer, equals(Prayer.ishaBefore));
    });
  });
}
