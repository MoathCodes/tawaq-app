import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:free_map/free_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:tawaq/core/bootstrap/app_init_providers.dart';
import 'package:tawaq/core/storage/settings_storage.dart';
import 'package:tawaq/core/utils/app_clock_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_day.dart';
import 'package:tawaq/feature/prayer/domain/models/location_constants.dart';
import 'package:tawaq/feature/prayer/domain/models/location_failure.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_settings.dart';
import 'package:tawaq/feature/prayer/domain/services/location_service.dart';
import 'package:tawaq/feature/prayer/presentation/provider/location_service_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_settings_provider.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class _MockLocationService extends Mock implements LocationService {}

ProviderContainer _container({
  required Storage<String, String> storage,
  LocationService? locationService,
  Future<tz.Location> Function()? timezoneLookup,
  DateTime? instant,
}) {
  return ProviderContainer(
    overrides: [
      if (instant != null)
        appClockProvider.overrideWith((ref) => Stream.value(instant)),
      deviceTimezoneLookupProvider.overrideWithValue(
        timezoneLookup ?? () async => tz.getLocation('Asia/Riyadh'),
      ),
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
      when(mock.getCurrentPosition).thenThrow(
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

    test(
      'city changes keep device timezone even in a different zone',
      () async {
        final storage = Storage<String, String>.inMemory();
        final mock = _MockLocationService();
        final nyc = tz.getLocation('America/New_York');
        when(() => mock.getLocationFromCoordinatesOffline(any()))
            .thenReturn(nyc);

        final container = _container(storage: storage, locationService: mock);
        addTearDown(container.dispose);

        await container.read(prayerSettingsProvider.future);
        await container
            .read(prayerSettingsProvider.notifier)
            .applyLocationBundle(
              coordinates: Coordinates(40.7128, -74.006),
              locationName: 'New York',
            );

        final after = container.read(prayerSettingsProvider).requireValue;
        expect(after.location.name, 'Asia/Riyadh');
        expect(after.useSystemTimezone, isTrue);
        expect(after.locationName, 'New York');
        verifyNever(() => mock.getLocationFromCoordinatesOffline(any()));
      },
    );
  });

  group('device location enrichment', () {
    test(
      'commits GPS and zone while geocoder is stalled; ignores old name',
      () async {
        final storage = Storage<String, String>.inMemory();
        final service = _MockLocationService();
        final name = Completer<FmData>();
        when(service.getCurrentPosition)
            .thenAnswer((_) async => const LatLng(24.471153, 39.6111216));
        when(() => service.getLocationFromCoordinatesOffline(any()))
            .thenReturn(tz.getLocation('Asia/Riyadh'));
        when(() => service.getPlaceDetails(any()))
            .thenAnswer((_) => name.future);
        final container = _container(
          storage: storage,
          locationService: service,
        );
        addTearDown(container.dispose);
        await container.read(prayerSettingsProvider.future);
        final notifier = container.read(prayerSettingsProvider.notifier);
        await notifier.applyCurrentDeviceLocation(autoLocation: true);
        final gps = container.read(prayerSettingsProvider).requireValue;
        expect(gps.coordinates.latitude, 24.471153);
        expect(gps.location.name, 'Asia/Riyadh');
        expect(gps.locationName, LocationConstants.unknownLocationName);
        await notifier.applyLocationBundle(
          coordinates: Coordinates(51.5074, -0.1278),
          location: tz.getLocation('Europe/London'),
          locationName: 'London',
          autoLocation: false,
        );
        name.complete(
          FmData.fromJSON({'name': 'Old city', 'lat': '24.47', 'lon': '39.61'}),
        );
        await pumpEventQueue();
        final manual = container.read(prayerSettingsProvider).requireValue;
        expect(manual.locationName, 'London');
        expect(manual.location.name, 'Europe/London');
        expect(manual.autoLocation, false);
      },
    );

    test(
      'name failure preserves the valid coordinates/timezone pair',
      () async {
        final service = _MockLocationService();
        when(service.getCurrentPosition)
            .thenAnswer((_) async => const LatLng(24.471153, 39.6111216));
        when(() => service.getLocationFromCoordinatesOffline(any()))
            .thenReturn(tz.getLocation('Asia/Riyadh'));
        when(() => service.getPlaceDetails(any()))
            .thenThrow(StateError('offline'));
        final container = _container(
          storage: Storage<String, String>.inMemory(),
          locationService: service,
        );
        addTearDown(container.dispose);
        await container.read(prayerSettingsProvider.future);
        await container
            .read(prayerSettingsProvider.notifier)
            .applyCurrentDeviceLocation();
        await pumpEventQueue();
        final settings = container.read(prayerSettingsProvider).requireValue;
        expect(settings.coordinates.latitude, 24.471153);
        expect(settings.location.name, 'Asia/Riyadh');
        expect(settings.locationName, LocationConstants.unknownLocationName);
      },
    );
  });

  group('timezone policy', () {
    test('manual choice survives pending startup detection', () async {
      final storage = Storage<String, String>.inMemory();
      await flushPersistedValue(
        storage,
        'PrayerSettingsNotifier',
        PrayerSettings.defaultSettings().copyWith(timezoneResolved: true),
      );
      final started = Completer<void>();
      final lookup = Completer<tz.Location>();
      final container = _container(
        storage: storage,
        timezoneLookup: () {
          started.complete();
          return lookup.future;
        },
      );
      addTearDown(container.dispose);
      container.read(prayerSettingsProvider);
      await started.future;
      expect(container.read(prayerSettingsProvider).hasValue, true);
      await container
          .read(prayerSettingsProvider.notifier)
          .setSystemTimezone(tz.getLocation('Europe/London'));
      lookup.complete(tz.getLocation('America/New_York'));
      await pumpEventQueue();
      final settings = container.read(prayerSettingsProvider).requireValue;
      expect(settings.useSystemTimezone, false);
      expect(settings.location.name, 'Europe/London');
    });

    for (final fails in [false, true]) {
      test(
        'startup detection preserves newer edits (failure: $fails)',
        () async {
          final storage = Storage<String, String>.inMemory();
          await flushPersistedValue(
            storage,
            'PrayerSettingsNotifier',
            PrayerSettings.defaultSettings().copyWith(timezoneResolved: true),
          );
          final started = Completer<void>();
          final lookup = Completer<tz.Location>();
          final container = _container(
            storage: storage,
            timezoneLookup: () {
              started.complete();
              return lookup.future;
            },
          );
          addTearDown(container.dispose);
          container.read(prayerSettingsProvider);
          await started.future;
          final notifier = container.read(prayerSettingsProvider.notifier);
          await notifier.applyLocationBundle(
            coordinates: Coordinates(51.5, -.1),
            locationName: 'London',
          );
          notifier.set24HourFormat(value: true);
          if (fails) {
            lookup.completeError(StateError('unavailable'));
          } else {
            lookup.complete(tz.getLocation('America/New_York'));
          }
          await pumpEventQueue();
          final settings = container.read(prayerSettingsProvider).requireValue;
          expect(settings.locationName, 'London');
          expect(settings.coordinates.latitude, 51.5);
          expect(settings.is24Hours, true);
          expect(settings.useSystemTimezone, true);
          expect(
            settings.location.name,
            fails ? 'Asia/Riyadh' : 'America/New_York',
          );
        },
      );
    }

    test(
      'manual choice survives city edits, restart, and device refresh',
      () async {
        final storage = Storage<String, String>.inMemory();
        final container = _container(storage: storage);
        await container.read(prayerSettingsProvider.future);
        final notifier = container.read(prayerSettingsProvider.notifier);
        await notifier.setSystemTimezone(tz.getLocation('Europe/London'));
        await notifier.applyLocationBundle(
          coordinates: Coordinates(40, -74),
          locationName: 'New York',
        );
        await notifier.refreshSystemTimezone();
        expect(
          container.read(prayerSettingsProvider).requireValue.location.name,
          'Europe/London',
        );
        await notifier.flush();
        container.dispose();
        final restarted = _container(storage: storage);
        addTearDown(restarted.dispose);
        final restored = await restarted.read(prayerSettingsProvider.future);
        expect(restored.location.name, 'Europe/London');
        expect(restored.useSystemTimezone, false);
      },
    );

    test(
      'device change refreshes independently of GPS and persists policy',
      () async {
        var zone = 'Asia/Riyadh';
        final container = _container(
          storage: Storage<String, String>.inMemory(),
          timezoneLookup: () async => tz.getLocation(zone),
        );
        addTearDown(container.dispose);
        await container.read(prayerSettingsProvider.future);
        final notifier = container.read(prayerSettingsProvider.notifier);
        await notifier.applyLocationBundle(
          coordinates: Coordinates(51.5, -.1),
          locationName: 'London',
        );
        zone = 'America/New_York';
        await notifier.refreshSystemTimezone();
        final settings = container.read(prayerSettingsProvider).requireValue;
        expect(settings.location.name, zone);
        expect(settings.autoLocation, false);
        expect(settings.locationName, 'London');
        await notifier.flush();
        expect(
          (await container
                  .read(settingsStorageProvider.future)
                  .then((s) => s.read('PrayerSettingsNotifier')))
              ?.data,
          contains('"use_system_timezone":true'),
        );
      },
    );

    test('stale device query cannot replace a newer manual choice', () async {
      final lookup = Completer<tz.Location>();
      var delayed = false;
      final container = _container(
        storage: Storage<String, String>.inMemory(),
        timezoneLookup: () => delayed
            ? lookup.future
            : Future.value(tz.getLocation('Asia/Riyadh')),
      );
      addTearDown(container.dispose);
      await container.read(prayerSettingsProvider.future);
      final notifier = container.read(prayerSettingsProvider.notifier);
      delayed = true;
      final refresh = notifier.refreshSystemTimezone();
      await notifier.setSystemTimezone(tz.getLocation('Europe/London'));
      lookup.complete(tz.getLocation('America/New_York'));
      await refresh;
      final settings = container.read(prayerSettingsProvider).requireValue;
      expect(settings.useSystemTimezone, false);
      expect(settings.location.name, 'Europe/London');
    });

    test(
      'failed fresh detection blocks prayer readiness and allows retry',
      () async {
        var failing = true;
        final container = _container(
          storage: Storage<String, String>.inMemory(),
          timezoneLookup: () async {
            if (failing) throw StateError('unavailable');
            return tz.getLocation('Europe/London');
          },
        );
        addTearDown(container.dispose);
        await container.read(prayerSettingsProvider.future);
        final notifier = container.read(prayerSettingsProvider.notifier);
        await notifier.applyLocationBundle(coordinates: Coordinates(51.5, -.1));
        expect(
          container.read(prayerSettingsProvider).requireValue.isLocationReady,
          false,
        );
        failing = false;
        await notifier.refreshSystemTimezone();
        expect(
          container.read(prayerSettingsProvider).requireValue.isLocationReady,
          true,
        );
        failing = true;
        await expectLater(notifier.refreshSystemTimezone(), throwsStateError);
        expect(
          container.read(prayerSettingsProvider).requireValue.location.name,
          'Europe/London',
        );
      },
    );

    test(
      'device timezone change updates the live prayer day across midnight',
      () async {
        var zone = 'Asia/Riyadh';
        final container = _container(
          storage: Storage<String, String>.inMemory(),
          instant: DateTime.utc(2026, 10, 11, 22, 30),
          timezoneLookup: () async => tz.getLocation(zone),
        );
        addTearDown(container.dispose);
        await container.read(prayerSettingsProvider.future);
        final notifier = container.read(prayerSettingsProvider.notifier);
        await notifier.applyLocationBundle(coordinates: Coordinates(40.7, -74));
        final subscription = container.listen(prayerDayProvider, (_, _) {});
        addTearDown(subscription.close);
        await container.read(appClockProvider.future);
        final day = await container
            .read(prayerDayProvider.future)
            .timeout(const Duration(seconds: 3));
        expect(day.now.day, 12);
        expect(day.location.name, 'Asia/Riyadh');
        zone = 'America/New_York';
        await notifier.refreshSystemTimezone();
        await pumpEventQueue();
        final changed = container.read(prayerDayProvider).requireValue;
        expect(changed.now.day, 11);
        expect(changed.location.name, zone);
        expect(changed.now.timeZoneOffset, const Duration(hours: -4));
        expect(changed.calendarDayKey, isNot(day.calendarDayKey));
      },
    );

    test('older JSON keeps its zone as a verified manual choice', () {
      final json = PrayerSettings.defaultSettings().toJson()
        ..remove('use_system_timezone')
        ..remove('timezone_resolved');
      json['location'] = 'Europe/London';
      final legacy = PrayerSettings.fromJson(json);
      expect(legacy.useSystemTimezone, false);
      expect(legacy.timezoneResolved, true);
      expect(legacy.location.name, 'Europe/London');
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

      final adjustments = adhanAdjustmentsFromJson({'maghrib': 3, 'ghost': -1});
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
