import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/settings/data/location_constants.dart';
import 'package:tawaq/feature/settings/data/models/prayer_settings_model.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart';

void main() {
  setUpAll(tz.initializeTimeZones);

  group('PrayerSettings', () {
    group('defaultSettings', () {
      test('returns valid default settings', () {
        final settings = PrayerSettings.defaultSettings();

        expect(settings.method, isA<UmmAlQura>());
        expect(settings.is24Hours, isFalse);
        expect(settings.coordinates.latitude, 0);
        expect(settings.coordinates.longitude, 0);
        expect(settings.locationName, LocationConstants.defaultLocationName);
        expect(settings.autoLocation, isFalse);
      });

      test('default settings have Riyadh timezone', () {
        final settings = PrayerSettings.defaultSettings();

        expect(settings.location.name, 'Asia/Riyadh');
      });

      test('default iqamah settings is empty map', () {
        final settings = PrayerSettings.defaultSettings();

        expect(settings.iqamahSettings, isEmpty);
      });

      test('default adhan adjustments is empty', () {
        final settings = PrayerSettings.defaultSettings();

        expect(settings.adhanAdjustments, isEmpty);
      });
    });

    group('copyWith', () {
      test('updates location while preserving other fields', () {
        final original = PrayerSettings.defaultSettings();
        final newLocation = getLocation('America/New_York');

        final updated = original.copyWith(location: newLocation);

        expect(updated.location.name, 'America/New_York');
        expect(updated.method, original.method);
        expect(updated.is24Hours, original.is24Hours);
      });

      test('updates calculation method', () {
        final original = PrayerSettings.defaultSettings();

        final updated = original.copyWith(method: const MuslimWorldLeague());

        expect(updated.method, isA<MuslimWorldLeague>());
      });

      test('updates is24Hours', () {
        final original = PrayerSettings.defaultSettings();
        expect(original.is24Hours, isFalse);

        final updated = original.copyWith(is24Hours: true);

        expect(updated.is24Hours, isTrue);
      });

      test('updates coordinates', () {
        final original = PrayerSettings.defaultSettings();
        final newCoords = Coordinates(51.5074, -0.1278); // London

        final updated = original.copyWith(coordinates: newCoords);

        expect(updated.coordinates.latitude, closeTo(51.5074, 0.0001));
        expect(updated.coordinates.longitude, closeTo(-0.1278, 0.0001));
      });

      test('updates iqamah settings', () {
        final original = PrayerSettings.defaultSettings();
        final newIqamah = {
          Prayer.fajr: 15,
          Prayer.dhuhr: 25,
          Prayer.asr: 15,
          Prayer.maghrib: 10,
          Prayer.isha: 20,
        };

        final updated = original.copyWith(iqamahSettings: newIqamah);

        expect(updated.iqamahSettings[Prayer.fajr], 15);
        expect(updated.iqamahSettings[Prayer.dhuhr], 25);
        expect(updated.iqamahSettings[Prayer.isha], 20);
      });

      test('updates adhan adjustments', () {
        final original = PrayerSettings.defaultSettings();
        final adjustments = {
          Prayer.fajr: -2,
          Prayer.maghrib: 3,
        };

        final updated = original.copyWith(adhanAdjustments: adjustments);

        expect(updated.adhanAdjustments[Prayer.fajr], -2);
        expect(updated.adhanAdjustments[Prayer.maghrib], 3);
      });
    });

    group('JSON serialization helpers', () {
      test('locationFromJson parses timezone string', () {
        final location = locationFromJson('America/New_York');

        expect(location.name, 'America/New_York');
        expect(location, isA<Location>());
      });

      test('locationToJson returns timezone name', () {
        final location = getLocation('Europe/London');

        final json = locationToJson(location);

        expect(json, 'Europe/London');
      });

      test('iqamahSettingsFromJson parses prayer map', () {
        final json = {
          'fajr': 15,
          'dhuhr': 20,
          'asr': 15,
        };

        final settings = iqamahSettingsFromJson(json);

        expect(settings[Prayer.fajr], 15);
        expect(settings[Prayer.dhuhr], 20);
        expect(settings[Prayer.asr], 15);
      });

      test('iqamahSettingsToJson serializes prayer map', () {
        final settings = {
          Prayer.fajr: 15,
          Prayer.dhuhr: 20,
        };

        final json = iqamahSettingsToJson(settings);

        expect(json['fajr'], 15);
        expect(json['dhuhr'], 20);
      });

      test('adhanAdjustmentsFromJson parses adjustments', () {
        final json = {
          'fajr': -5,
          'maghrib': 3,
        };

        final adjustments = adhanAdjustmentsFromJson(json);

        expect(adjustments[Prayer.fajr], -5);
        expect(adjustments[Prayer.maghrib], 3);
      });

      test('adhanAdjustmentsToJson serializes adjustments', () {
        final adjustments = {
          Prayer.fajr: -5,
          Prayer.isha: 2,
        };

        final json = adhanAdjustmentsToJson(adjustments);

        expect(json['fajr'], -5);
        expect(json['isha'], 2);
      });
    });

    group('toJson/fromJson roundtrip', () {
      test('preserves all settings through JSON roundtrip', () {
        final original = PrayerSettings(
          method: const MuslimWorldLeague(),
          is24Hours: true,
          iqamahSettings: {
            Prayer.fajr: 15,
            Prayer.dhuhr: 25,
          },
          adhanAdjustments: {
            Prayer.fajr: -3,
          },
          coordinates: Coordinates(21.4225, 39.8262), // Mecca
          locationName: 'Mecca',
          location: getLocation('Asia/Riyadh'),
          autoLocation: true,
        );

        final json = original.toJson();
        final restored = PrayerSettings.fromJson(json);

        expect(restored.method, isA<MuslimWorldLeague>());
        expect(restored.is24Hours, isTrue);
        expect(restored.locationName, 'Mecca');
        expect(restored.autoLocation, isTrue);
        expect(restored.coordinates.latitude, closeTo(21.4225, 0.0001));
        expect(restored.iqamahSettings[Prayer.fajr], 15);
        expect(restored.adhanAdjustments[Prayer.fajr], -3);
      });
    });
  });
}
