import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:free_map/free_map.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:tawaq/core/bootstrap/app_init_providers.dart';
import 'package:tawaq/feature/settings/data/location_constants.dart';
import 'package:tawaq/feature/settings/data/models/prayer_settings_model.dart';
import 'package:tawaq/feature/settings/data/repository/settings_storage.dart';
import 'package:tawaq/feature/settings/domain/models/location_failure.dart';
import 'package:tawaq/feature/settings/domain/services/location_service.dart';
import 'package:tawaq/feature/settings/presentation/provider/location_service_provider.dart';
import 'package:tawaq/feature/settings/presentation/provider/prayer_settings_provider.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class _MockLocationService extends Mock implements LocationService {}

ProviderContainer _container({
  required Storage<String, String> storage,
  LocationService? locationService,
}) {
  return ProviderContainer(
    overrides: [
      hiveCoreInitProvider.overrideWith((ref) async {}),
      settingsStorageProvider.overrideWith((ref) async => storage),
      if (locationService != null)
        locationServiceProvider.overrideWithValue(locationService),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(tzdata.initializeTimeZones);

  setUpAll(() {
    registerFallbackValue(Coordinates(0, 0));
  });

  group('applyLocationBundle', () {
    test('commits coords + name + tz + auto in one state update', () async {
      final storage = Storage<String, String>.inMemory();
      final container = _container(storage: storage);
      addTearDown(container.dispose);

      await container.read(prayerSettingsProvider.future);
      final notifier = container.read(prayerSettingsProvider.notifier);
      final before = container.read(prayerSettingsProvider).requireValue;

      final london = tz.getLocation('Europe/London');
      await notifier.applyLocationBundle(
        coordinates: Coordinates(51.5074, -0.1278),
        locationName: 'London',
        location: london,
        autoLocation: true,
      );

      final after = container.read(prayerSettingsProvider).requireValue;
      expect(after.coordinates.latitude, closeTo(51.5074, 0.0001));
      expect(after.locationName, 'London');
      expect(after.location.name, 'Europe/London');
      expect(after.autoLocation, isTrue);
      expect(before.autoLocation, isFalse);

      await notifier.flush();
      final written = await storage.read('PrayerSettingsNotifier');
      expect(written?.data, contains('"auto_location":true'));
      expect(written?.data, contains('London'));
    });

    test('keeps previous pair when GPS enable fails (no auto flag)', () async {
      final storage = Storage<String, String>.inMemory();
      final mock = _MockLocationService();
      when(() => mock.getCurrentPosition()).thenThrow(
        const LocationException(LocationFailureCode.permissionDenied),
      );

      final container = _container(storage: storage, locationService: mock);
      addTearDown(container.dispose);

      await container.read(prayerSettingsProvider.future);
      final before = container.read(prayerSettingsProvider).requireValue;

      final notifier = container.read(prayerSettingsProvider.notifier);
      await expectLater(
        notifier.applyCurrentDeviceLocation(autoLocation: true),
        throwsA(isA<LocationException>()),
      );

      final after = container.read(prayerSettingsProvider).requireValue;
      expect(after.autoLocation, isFalse);
      expect(after.coordinates.latitude, before.coordinates.latitude);
      expect(after.location.name, before.location.name);
    });

    test('resolves TZ from coords via location service', () async {
      final storage = Storage<String, String>.inMemory();
      final mock = _MockLocationService();
      final nyc = tz.getLocation('America/New_York');
      when(
        () => mock.getLocationFromCoordinatesOffline(any()),
      ).thenReturn(nyc);

      final container = _container(storage: storage, locationService: mock);
      addTearDown(container.dispose);

      await container.read(prayerSettingsProvider.future);
      await container.read(prayerSettingsProvider.notifier).applyLocationBundle(
        coordinates: Coordinates(40.7128, -74.006),
        locationName: 'New York',
      );

      final after = container.read(prayerSettingsProvider).requireValue;
      expect(after.location.name, 'America/New_York');
      expect(after.locationName, 'New York');
      verify(
        () => mock.getLocationFromCoordinatesOffline(any()),
      ).called(1);
    });
  });

  group('PrayerSettings JSON hydrate harden', () {
    test('skips unknown prayer keys in iqamah / adjustments maps', () {
      final iqamah = iqamahSettingsFromJson({
        'fajr': 15,
        'not_a_prayer': 99,
        'dhuhr': 20,
      });
      expect(iqamah[Prayer.fajr], 15);
      expect(iqamah[Prayer.dhuhr], 20);
      expect(iqamah.length, 2);

      final adjustments = adhanAdjustmentsFromJson({
        'maghrib': 3,
        'ghost': -1,
      });
      expect(adjustments[Prayer.maghrib], 3);
      expect(adjustments.length, 1);
    });

    test('invalid IANA location falls back without wiping other fields', () {
      final json = PrayerSettings.defaultSettings()
          .copyWith(
            locationName: 'Jeddah',
            coordinates: Coordinates(21.4858, 39.1925),
            is24Hours: true,
            autoLocation: true,
          )
          .toJson();
      json['location'] = 'Not/A/RealZone';

      final recovered = PrayerSettings.fromJson(json);
      expect(recovered.location.name, 'Asia/Riyadh');
      expect(recovered.locationName, 'Jeddah');
      expect(recovered.is24Hours, isTrue);
      expect(recovered.autoLocation, isTrue);
      expect(recovered.coordinates.latitude, closeTo(21.4858, 0.0001));
    });

    test('locationFromJson recovers from unknown zone', () {
      expect(locationFromJson('Asia/Riyadh').name, 'Asia/Riyadh');
      expect(locationFromJson('Totally/Fake').name, 'Asia/Riyadh');
    });
  });

  group('default sentinel', () {
    test('default location name constant still used', () {
      expect(
        PrayerSettings.defaultSettings().locationName,
        LocationConstants.defaultLocationName,
      );
    });
  });
}
