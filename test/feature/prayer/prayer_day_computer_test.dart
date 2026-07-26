import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_time_inputs.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_day_computer.dart';
import 'package:tawaq/feature/settings/data/models/prayer_settings_model.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart';

PrayerTimeInputs inputsFromSettings(PrayerSettings settings) =>
    PrayerTimeInputs(
      method: settings.method,
      coordinates: settings.coordinates,
      location: settings.location,
      adhanAdjustments: settings.adhanAdjustments,
    );

void main() {
  setUpAll(tz.initializeTimeZones);

  late PrayerSettings jeddahSettings;

  setUp(() {
    jeddahSettings = PrayerSettings.defaultSettings().copyWith(
      coordinates: Coordinates(21.575224, 39.210725),
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
      );

      // Location readiness is enforced by [prayerTimeInputsProvider], not here.
      expect(result.fajr, isNotNull);
    });
  });

  group('computePrayerDayBundle', () {
    test('builds bundle for sentinel (0,0) when inputs are provided', () {
      final settings = PrayerSettings.defaultSettings();
      final result = computePrayerDayBundle(
        inputs: inputsFromSettings(settings),
        anchorNow: TZDateTime(getLocation('Asia/Riyadh'), 2026, 6, 18, 12),
      );
      expect(result.today.fajr, isNotNull);
    });

    test('produces consistent today times for Jeddah', () {
      final anchor = TZDateTime(getLocation('Asia/Riyadh'), 2026, 6, 18, 16, 3);
      final bundle = computePrayerDayBundle(
        inputs: inputsFromSettings(jeddahSettings),
        anchorNow: anchor,
      );

      expect(bundle.today.fajr, isNotNull);
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
      );
      final eveningBundle = computePrayerDayBundle(
        inputs: inputsFromSettings(jeddahSettings),
        anchorNow: evening,
      );

      expect(morningBundle.today.fajr, eveningBundle.today.fajr);
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
      );
      final dateOnly = computePrayerTimesForAnchor(
        inputs: inputsFromSettings(jeddahSettings),
        anchor: dateAnchor,
      );

      expect(liveBundle.today.fajr, dateOnly.fajr);
    });

    test('bakes adhanAdjustments into timeline; sunnah stays raw', () {
      final location = getLocation('Asia/Riyadh');
      final anchor = TZDateTime(location, 2026, 6, 18, 12);
      final raw = computePrayerDayBundle(
        inputs: inputsFromSettings(jeddahSettings),
        anchorNow: anchor,
      );
      final adjusted = computePrayerDayBundle(
        inputs: inputsFromSettings(
          jeddahSettings.copyWith(
            adhanAdjustments: {
              Prayer.fajr: 5,
              Prayer.dhuhr: -3,
            },
          ),
        ),
        anchorNow: anchor,
      );

      expect(
        adjusted.timeline.fajrToday,
        raw.timeline.fajrToday.add(const Duration(minutes: 5)),
      );
      expect(
        adjusted.timeline.dhuhrToday,
        raw.timeline.dhuhrToday.subtract(const Duration(minutes: 3)),
      );
      expect(
        adjusted.timeline.fajrToday.isAtSameMomentAs(adjusted.today.fajr),
        isTrue,
      );
      // Sunnah night windows are derived from unadjusted isha/fajr.
      expect(
        adjusted.timeline.middleOfNightToday,
        raw.timeline.middleOfNightToday,
      );
      expect(
        adjusted.timeline.lastThirdToday,
        raw.timeline.lastThirdToday,
      );
    });
  });
}
