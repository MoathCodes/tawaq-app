import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:riverpod_annotation/experimental/json_persist.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/core/storage/settings_storage.dart';
import 'package:tawaq/core/utils/location_extensions.dart';
import 'package:tawaq/feature/prayer/domain/models/location_constants.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_settings.dart';
import 'package:tawaq/feature/prayer/domain/services/location_service.dart';
import 'package:tawaq/feature/prayer/presentation/provider/location_service_provider.dart';
import 'package:timezone/timezone.dart';

part 'prayer_settings_provider.g.dart';

/// Platform query kept injectable for timezone-change and failure tests.
final deviceTimezoneLookupProvider = Provider<Future<Location> Function()>((
  ref,
) {
  return () async => getLocation(
    (await FlutterTimezone.getLocalTimezone().timeout(
      const Duration(seconds: 5),
    )).identifier,
  );
});

const String _prayerLogPrefix = '[PrayerSettingsNotifier]';

/// Notifier for prayer settings.
///
/// Persisted as JSON via [JsonPersist] + Hivez-backed [SettingsStorage].
@Riverpod(keepAlive: true)
@JsonPersist()
class PrayerSettingsNotifier extends _$PrayerSettingsNotifier {
  @override
  Future<PrayerSettings> build() async {
    ref.read(loggerProvider).i('$_prayerLogPrefix Building...');
    try {
      await persist(
        ref.watch(settingsStorageProvider.future),
        options: kSettingsPersistForever,
      ).future;
    } on Object catch (error, stack) {
      ref
          .read(loggerProvider)
          .e(
            '$_prayerLogPrefix hydrate failed; using current/default settings',
            error: error,
            stackTrace: stack,
          );
    }
    final settings = state.value ?? PrayerSettings.defaultSettings();
    if (!settings.useSystemTimezone) return settings;
    try {
      final location = await ref.read(deviceTimezoneLookupProvider)();
      return settings.copyWith(location: location, timezoneResolved: true);
    } on Object catch (error, stack) {
      ref
          .read(loggerProvider)
          .w('Device timezone unavailable', error: error, stackTrace: stack);
      return settings;
    }
  }

  int _locationGeneration = 0;
  int _timezoneGeneration = 0;

  void _commit(PrayerSettings Function(PrayerSettings) fn, String field) {
    if (state.value == null) return;
    final newSettings = fn(state.value!);
    if (state.value == newSettings) return;
    state = AsyncData(newSettings);
    ref.read(loggerProvider).i('$_prayerLogPrefix $field updated');
  }

  /// Awaits a durable disk write of the current settings (kill-boundary safe).
  Future<void> flush() async {
    final value = state.value;
    if (value == null) return;
    final storage = await ref.read(settingsStorageProvider.future);
    if (!ref.mounted) return;
    await flushPersistedValue(storage, key, value);
  }

  /// Sets whether to use 24-hour time format.
  void set24HourFormat({required bool value}) =>
      _commit((s) => s.copyWith(is24Hours: value), '24h format');

  /// Sets the iqamah times for prayers.
  void setIqamahTimes(Map<Prayer, int> t) =>
      _commit((s) => s.copyWith(iqamahSettings: t), 'Iqamah times');

  /// Sets the complete prayer settings object.
  void setPrayerSettings(PrayerSettings s) {
    ++_locationGeneration;
    ++_timezoneGeneration;
    _commit((_) => s, 'Settings');
  }

  /// Applies [cb] to the current settings, logging failures before rethrowing.
  @override
  Future<PrayerSettings> update(
    FutureOr<PrayerSettings> Function(PrayerSettings) cb, {
    FutureOr<PrayerSettings> Function(Object, StackTrace)? onError,
  }) {
    return super.update(
      cb,
      onError: (err, st) {
        ref
            .read(loggerProvider)
            .e('$_prayerLogPrefix Update error', error: err, stackTrace: st);
        if (onError != null) return onError(err, st);
        throw Exception(err);
      },
    );
  }

  /// Changes the place without changing the timezone policy. An explicit zone
  /// is a manual override and invalidates any pending device-zone query.
  Future<void> applyLocationBundle({
    Coordinates? coordinates,
    String? locationName,
    Location? location,
    bool? autoLocation,
  }) async {
    if (!state.hasValue) return;
    ++_locationGeneration;
    if (location != null) ++_timezoneGeneration;
    _commit(
      (current) => current.copyWith(
        coordinates: coordinates ?? current.coordinates,
        locationName:
            locationName ??
            (coordinates != null
                ? LocationConstants.unknownLocationName
                : current.locationName),
        location: location ?? current.location,
        useSystemTimezone: location == null && current.useSystemTimezone,
        timezoneResolved: location != null || current.timezoneResolved,
        autoLocation: autoLocation ?? current.autoLocation,
      ),
      'Location bundle',
    );
  }

  /// Applies GPS coordinates independently of timezone and name enrichment.
  Future<void> applyCurrentDeviceLocation({bool? autoLocation}) async {
    final generation = ++_locationGeneration;
    final service = ref.read(locationServiceProvider);
    final position = await service.getCurrentPosition();
    if (!ref.mounted || generation != _locationGeneration) return;
    final coordinates = position.coordinates;

    _commit(
      (current) => current.copyWith(
        coordinates: coordinates,
        locationName: LocationConstants.unknownLocationName,
        autoLocation: autoLocation ?? current.autoLocation,
      ),
      'Device location',
    );
    unawaited(_enrichLocationName(service, coordinates, generation));
  }

  Future<void> _enrichLocationName(
    LocationService service,
    Coordinates coordinates,
    int generation,
  ) async {
    try {
      final details = await service.getPlaceDetails(coordinates);
      if (!ref.mounted || generation != _locationGeneration) return;
      final name = details.name;
      if (name.isEmpty) return;
      _commit(
        (current) => current.copyWith(locationName: name),
        'Location name',
      );
    } on Object catch (error, stack) {
      if (!ref.mounted || generation != _locationGeneration) return;
      ref
          .read(loggerProvider)
          .w('Location name unavailable', error: error, stackTrace: stack);
    }
  }

  /// Sets timezone from [loc], or from the device when [loc] is null.
  Future<void> setSystemTimezone([Location? loc]) async {
    if (loc != null) {
      await applyLocationBundle(location: loc);
      return;
    }
    final generation = ++_timezoneGeneration;
    final location = await ref.read(deviceTimezoneLookupProvider)();
    if (!ref.mounted || generation != _timezoneGeneration) return;
    _commit(
      (s) => s.copyWith(
        location: location,
        useSystemTimezone: true,
        timezoneResolved: true,
      ),
      'Device timezone',
    );
  }

  /// Refreshes only device mode. Failures retain the last verified timezone.
  Future<void> refreshSystemTimezone() async {
    if (state.value?.useSystemTimezone != true) return;
    await setSystemTimezone();
  }

  /// Updates the iqamah time for a specific prayer.
  void updatePrayerIqamahTime(Prayer prayer, int time) {
    if (state.value == null) return;
    if ((state.value!.iqamahSettings[prayer] ?? 0) == time) return;
    final newMap = Map<Prayer, int>.from(state.value!.iqamahSettings)
      ..[prayer] = time;
    _commit((s) => s.copyWith(iqamahSettings: newMap), 'Iqamah for $prayer');
  }
}
