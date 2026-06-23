import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivez_flutter/hivez_flutter.dart';
import 'package:logger/logger.dart';
import 'package:tawaq/feature/prayer/data/database/prayer_database.dart';
import 'package:tawaq/feature/prayer/data/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/data/repository/prayer_repo.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_time_inputs.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_day_computer.dart';
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

  late PrayerRepo repo;
  late PrayerSettings jeddahSettings;

  setUp(() {
    final box = Box<int, PrayerCompletion>(
      'computer_test_${DateTime.now().microsecondsSinceEpoch}',
    );
    repo = PrayerRepo(
      prayerDatabase: PrayerDatabase(box),
      log: Logger(),
    );
    jeddahSettings = PrayerSettings.defaultSettings().copyWith(
      coordinates: const Coordinates(21.575224, 39.210725),
      location: getLocation('Asia/Riyadh'),
    );
  });

  group('computePrayerTimesForAnchor', () {
    test('computes times for sentinel (0,0) when inputs are provided', () {
      final settings = PrayerSettings.defaultSettings();
      expect(settings.isLocationReady, isFalse);

      final result = computePrayerTimesForAnchor(
        inputs: inputsFromSettings(settings),
        anchor: TZDateTime(getLocation('Asia/Riyadh'), 2026, 6, 18),
        repo: repo,
      );

      // Location readiness is enforced by [prayerTimeInputsProvider], not here.
      expect(result, isNotNull);
    });
  });

  group('computePrayerDayBundle', () {
    test('builds bundle for sentinel (0,0) when inputs are provided', () {
      final settings = PrayerSettings.defaultSettings();
      final result = computePrayerDayBundle(
        inputs: inputsFromSettings(settings),
        anchorNow: TZDateTime(getLocation('Asia/Riyadh'), 2026, 6, 18, 12),
        repo: repo,
      );
      expect(result, isNotNull);
    });

    test('produces consistent today times for Jeddah', () {
      final anchor = TZDateTime(getLocation('Asia/Riyadh'), 2026, 6, 18, 16, 3);
      final bundle = computePrayerDayBundle(
        inputs: inputsFromSettings(jeddahSettings),
        anchorNow: anchor,
        repo: repo,
      );

      expect(bundle, isNotNull);
      expect(bundle!.today.fajr, isNotNull);
      expect(bundle.timeline.fajrToday, isNotNull);
      expect(
        bundle.today.fajr.isBefore(bundle.today.dhuhr),
        isTrue,
      );
    });

    test('anchor date parity: same calendar day yields same fajr', () {
      final morning = TZDateTime(getLocation('Asia/Riyadh'), 2026, 6, 18, 6);
      final evening = TZDateTime(getLocation('Asia/Riyadh'), 2026, 6, 18, 20);

      final morningBundle = computePrayerDayBundle(
        inputs: inputsFromSettings(jeddahSettings),
        anchorNow: morning,
        repo: repo,
      );
      final eveningBundle = computePrayerDayBundle(
        inputs: inputsFromSettings(jeddahSettings),
        anchorNow: evening,
        repo: repo,
      );

      expect(morningBundle!.today.fajr, eveningBundle!.today.fajr);
    });

    test('live anchor matches single-date anchor for same day', () {
      final liveAnchor = TZDateTime(
        getLocation('Asia/Riyadh'),
        2026,
        6,
        18,
        16,
        3,
      );
      final dateAnchor = TZDateTime(
        getLocation('Asia/Riyadh'),
        2026,
        6,
        18,
        12,
      );

      final liveBundle = computePrayerDayBundle(
        inputs: inputsFromSettings(jeddahSettings),
        anchorNow: liveAnchor,
        repo: repo,
      );
      final dateOnly = computePrayerTimesForAnchor(
        inputs: inputsFromSettings(jeddahSettings),
        anchor: dateAnchor,
        repo: repo,
      );

      expect(liveBundle!.today.fajr, dateOnly!.fajr);
    });
  });
}
