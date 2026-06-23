import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:riverpod_annotation/experimental/json_persist.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/core/utils/location_extensions.dart';
import 'package:tawaq/feature/settings/data/location_constants.dart';
import 'package:tawaq/feature/settings/data/models/prayer_settings_model.dart';
import 'package:tawaq/feature/settings/data/repository/settings_storage.dart';
import 'package:tawaq/feature/settings/presentation/provider/location_service_provider.dart';
import 'package:timezone/timezone.dart';

part 'prayer_settings_provider.g.dart';

const String _prayerLogPrefix = '[PrayerSettingsNotifier]';

/// Last successfully resolved prayer settings, reused when a (re)build cannot
/// read storage.
///
/// Without it a transient/failed hydrate (e.g. right after the machine wakes
/// from sleep) silently reverts the whole prayer-time pipeline to the (0,0)
/// "null island" defaults, which compute prayer times ~2-3h off and fire
/// alerts at the wrong time. Lives at module scope so it survives the
/// provider's autoDispose rebuilds, and is seeded with the first-run defaults
/// so it is never null.
PrayerSettings _lastGoodPrayerSettings = PrayerSettings.defaultSettings();

/// Synchronous prayer settings safe for time math and completions.
///
/// Returns the hydrated settings when location is ready, otherwise the last
/// good stored settings. Null when no valid coordinates exist yet.
@Riverpod(keepAlive: true)
PrayerSettings? effectivePrayerSettings(Ref ref) {
  ref.watch(prayerSettingsProvider);
  final current = ref.read(prayerSettingsProvider).value;
  if (current != null && current.isLocationReady) return current;
  if (_lastGoodPrayerSettings.isLocationReady) return _lastGoodPrayerSettings;
  return null;
}

/// Whether prayer times can be computed from stored coordinates.
@Riverpod(keepAlive: true)
bool prayerLocationReady(Ref ref) {
  return ref.watch(effectivePrayerSettingsProvider) != null;
}

/// Notifier for prayer settings.
///
/// Persisted as JSON via [JsonPersist] + Hivez-backed [SettingsStorage].
@riverpod
@JsonPersist()
class PrayerSettingsNotifier extends _$PrayerSettingsNotifier {
  @override
  Future<PrayerSettings> build() async {
    ref.read(loggerProvider).i('$_prayerLogPrefix Building...');
    // Remember every good value so a later failed read falls back to it
    // instead of the (0,0) defaults.
    listenSelf((_, next) {
      final value = next.value;
      if (value != null) _lastGoodPrayerSettings = value;
    });
    try {
      await persist(
        ref.read(settingsStorageProvider),
        options: const StorageOptions(
          cacheTime: StorageCacheTime.unsafe_forever,
        ),
      ).future;
    } on Object catch (error, stack) {
      ref
          .read(loggerProvider)
          .e(
            '$_prayerLogPrefix hydrate failed; keeping last-good settings',
            error: error,
            stackTrace: stack,
          );
    }
    return state.value ?? _lastGoodPrayerSettings;
  }

  void _update(PrayerSettings Function(PrayerSettings) fn, String field) {
    if (state.value == null) return;
    final newSettings = fn(state.value!);
    if (state.value == newSettings) return;
    state = AsyncData(newSettings);
    ref.read(loggerProvider).i('$_prayerLogPrefix $field updated');
  }

  /// Sets whether to use 24-hour time format.
  void set24HourFormat({required bool value}) =>
      _update((s) => s.copyWith(is24Hours: value), '24h format');

  /// Sets the coordinates for prayer time calculations.
  void setCoordinates(Coordinates c) =>
      _update((s) => s.copyWith(coordinates: c), 'Coordinates');

  /// Sets the iqamah times for prayers.
  void setIqamahTimes(Map<Prayer, int> t) =>
      _update((s) => s.copyWith(iqamahSettings: t), 'Iqamah times');

  /// Sets the timezone location for prayer time calculations.
  void setLocation(Location l) =>
      _update((s) => s.copyWith(location: l), 'Location');

  /// Sets whether to use automatic location detection.
  void setAutoLocation({required bool value}) =>
      _update((s) => s.copyWith(autoLocation: value), 'Auto location');

  /// Sets the display name for the current location.
  void setLocationName(String n) =>
      _update((s) => s.copyWith(locationName: n), 'Location name');

  /// Sets the complete prayer settings object.
  void setPrayerSettings(PrayerSettings s) {
    if (state.value == null || state.value == s) return;
    state = AsyncData(s);
    ref.read(loggerProvider).i('$_prayerLogPrefix Settings updated');
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

  /// Updates location-related data in prayer settings.
  Future<void> updateLocationData({
    Coordinates? coordinates,
    String? locationName,
    Location? location,
  }) async {
    if (state.value == null) return;
    var loc = location;
    if (coordinates != null && loc == null) {
      try {
        loc = ref
            .read(locationServiceProvider)
            .getLocationFromCoordinatesOffline(coordinates);
      } catch (_) {}
    }
    final s = state.value!;
    final newSettings = s.copyWith(
      coordinates: coordinates ?? s.coordinates,
      locationName: locationName ?? s.locationName,
      location: loc ?? s.location,
    );
    if (s == newSettings) return;
    state = AsyncData(newSettings);
  }

  /// Fetches and sets the current device location.
  Future<void> useCurrentLocation() async {
    final svc = ref.read(locationServiceProvider);
    final pos = await svc.getCurrentPosition();
    final details = await svc.getPlaceDetails(pos.coordinates);
    await updateLocationData(
      coordinates: pos.coordinates,
      locationName: details.name.isNotEmpty
          ? details.name
          : LocationConstants.unknownLocationName,
    );
  }

  /// Sets the timezone from the system's current timezone.
  Future<void> setSystemTimezone([Location? loc]) async {
    final tz = await FlutterTimezone.getLocalTimezone();
    setLocation(loc ?? getLocation(tz.identifier));
  }

  /// Updates the iqamah time for a specific prayer.
  void updatePrayerIqamahTime(Prayer prayer, int time) {
    if (state.value == null) return;
    if ((state.value!.iqamahSettings[prayer] ?? 0) == time) return;
    final newMap = Map<Prayer, int>.from(state.value!.iqamahSettings)
      ..[prayer] = time;
    _update((s) => s.copyWith(iqamahSettings: newMap), 'Iqamah for $prayer');
  }
}

/// Display name for the current prayer location (shell app bar).
@riverpod
String? prayerLocationName(Ref ref) {
  return ref.watch(prayerSettingsProvider).value?.locationName;
}
