import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:riverpod_annotation/experimental/json_persist.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/core/storage/settings_storage.dart';
import 'package:tawaq/core/utils/location_extensions.dart';
import 'package:tawaq/feature/prayer/domain/models/location_constants.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_settings.dart';
import 'package:tawaq/feature/prayer/presentation/provider/location_service_provider.dart';
import 'package:timezone/timezone.dart';

part 'prayer_settings_provider.g.dart';

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
    return state.value ?? PrayerSettings.defaultSettings();
  }

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
  void setPrayerSettings(PrayerSettings s) => _commit((_) => s, 'Settings');

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
            .e(
              '$_prayerLogPrefix Update error',
              error: err,
              stackTrace: st,
            );
        if (onError != null) return onError(err, st);
        throw Exception(err);
      },
    );
  }

  /// Resolves IANA timezone for [coordinates], falling back to device TZ.
  ///
  /// Throws when neither offline lookup nor device TZ succeeds — callers must
  /// not commit coords without a matching timezone (no stale-pair writes).
  Future<Location> _resolveTimezone(Coordinates coordinates) async {
    try {
      final resolved = ref
          .read(locationServiceProvider)
          .getLocationFromCoordinatesOffline(coordinates);
      if (resolved != null) return resolved;
    } on Object catch (error, stack) {
      ref
          .read(loggerProvider)
          .w(
            '$_prayerLogPrefix coord TZ lookup failed; trying device TZ',
            error: error,
            stackTrace: stack,
          );
    }
    final tz = await FlutterTimezone.getLocalTimezone();
    return getLocation(tz.identifier);
  }

  /// Atomically applies location fields in a single persist write.
  ///
  /// When [coordinates] change without an explicit [location], timezone is
  /// resolved from coords (device TZ only if offline lookup fails). On resolve
  /// failure the previous coords+tz pair is left untouched and the error
  /// propagates.
  Future<void> applyLocationBundle({
    Coordinates? coordinates,
    String? locationName,
    Location? location,
    bool? autoLocation,
  }) async {
    if (state.value == null) return;

    var loc = location;
    if (coordinates != null && loc == null) {
      loc = await _resolveTimezone(coordinates);
    }

    _commit(
      (current) => current.copyWith(
        coordinates: coordinates ?? current.coordinates,
        locationName:
            locationName ??
            (coordinates != null
                ? LocationConstants.unknownLocationName
                : current.locationName),
        location: loc ?? current.location,
        autoLocation: autoLocation ?? current.autoLocation,
      ),
      'Location bundle',
    );
  }

  /// Fetches GPS + place details and applies via [applyLocationBundle].
  ///
  /// Pass [autoLocation] to set the flag in the same commit (e.g. `true` when
  /// enabling auto-location). Omitting it leaves the flag unchanged.
  Future<void> applyCurrentDeviceLocation({bool? autoLocation}) async {
    final svc = ref.read(locationServiceProvider);
    final pos = await svc.getCurrentPosition();
    logger.i('$_prayerLogPrefix GPS coords: ${pos.coordinates}');
    final details = await svc.getPlaceDetails(pos.coordinates);
    logger.i('$_prayerLogPrefix Place details: ${details.name}');
    await applyLocationBundle(
      coordinates: pos.coordinates,
      locationName: details.name.isNotEmpty
          ? details.name
          : LocationConstants.unknownLocationName,
      autoLocation: autoLocation,
    );
  }

  /// Sets timezone from [loc], or from the device when [loc] is null.
  Future<void> setSystemTimezone([Location? loc]) async {
    if (loc != null) {
      await applyLocationBundle(location: loc);
      return;
    }
    final tz = await FlutterTimezone.getLocalTimezone();
    await applyLocationBundle(location: getLocation(tz.identifier));
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
