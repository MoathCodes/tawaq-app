import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hasanat/core/logging/logger_provider.dart';
import 'package:hasanat/core/utils/location_extensions.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_analytics.dart';
import 'package:hasanat/feature/quran/domain/models/font_sizes.dart';
import 'package:hasanat/feature/quran/domain/models/quran_layouts.dart';
import 'package:hasanat/feature/quran/domain/models/quran_screen_state.dart';
import 'package:hasanat/feature/settings/data/models/prayer_settings_model.dart';
import 'package:hasanat/feature/settings/data/models/state_settings.dart';
import 'package:hasanat/feature/settings/data/models/theme_prefs.dart';
import 'package:hasanat/feature/settings/data/repository/settings_storage.dart';
import 'package:hasanat/feature/settings/service/location_service.dart';
import 'package:hasanat/theme/theme_model.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:riverpod_annotation/experimental/json_persist.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timezone/timezone.dart';

part 'settings_provider.g.dart';

const String _localeLogPrefix = '[LocaleNotifier]';
const String _prayerLogPrefix = '[PrayerSettingsNotifier]';
const String _themeLogPrefix = '[ThemeNotifier]';

// ---------------------------------------------------------------------------
// Locale
// ---------------------------------------------------------------------------

/// Notifier for the application locale.
///
/// Persisted as a plain language-code string via [persist].
@riverpod
@JsonPersist()
class LocaleNotifier extends _$LocaleNotifier {
  @override
  String build() {
    ref.read(loggerProvider).i('$_localeLogPrefix Building...');
    persist(
      ref.read(settingsStorageProvider),
      options: const StorageOptions(
        cacheTime: StorageCacheTime.unsafe_forever,
      ),
    );
    return 'en';
  }

  @override
  String get key => 'locale';

  /// Returns true if the current locale is Arabic.
  bool isArabic() => state == 'ar';

  /// Sets the application locale.
  void setLocale(Locale newLocale) {
    if (newLocale.languageCode == state) return;
    ref.read(loggerProvider).i('$_localeLogPrefix Setting to: $newLocale');
    state = newLocale.languageCode;
  }

  /// Toggles the application locale between English and Arabic.
  void toggleLocale() {
    setLocale(
      state == 'ar' ? const Locale('en') : const Locale('ar'),
    );
  }
}

// ---------------------------------------------------------------------------
// Prayer Settings
// ---------------------------------------------------------------------------

/// Notifier for prayer settings.
///
/// Persisted as JSON via [JsonPersist] + Hivez-backed [SettingsStorage].
@riverpod
@JsonPersist()
class PrayerSettingsNotifier extends _$PrayerSettingsNotifier {
  @override
  Future<PrayerSettings> build() async {
    ref.read(loggerProvider).i('$_prayerLogPrefix Building...');
    await persist(
      ref.read(settingsStorageProvider),
      options: const StorageOptions(
        cacheTime: StorageCacheTime.unsafe_forever,
      ),
    ).future;
    return state.value ?? PrayerSettings.defaultSettings();
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
      locationName: details.name.isNotEmpty ? details.name : 'Unknown Location',
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

// ---------------------------------------------------------------------------
// Theme
// ---------------------------------------------------------------------------

/// Notifier for theme settings.
///
/// Persists [ThemePrefs] (palette + mode) via [JsonPersist].
@riverpod
@JsonPersist()
class ThemeNotifier extends _$ThemeNotifier {
  @override
  Future<ThemePrefs> build() async {
    ref.read(loggerProvider).i('$_themeLogPrefix Building...');
    await persist(
      ref.read(settingsStorageProvider),
      options: const StorageOptions(
        cacheTime: StorageCacheTime.unsafe_forever,
      ),
    ).future;
    return state.value ?? ThemePrefs.defaults();
  }

  /// Sets the application palette.
  void setPalette(AppPalette p) {
    final prefs = state.value;
    if (prefs == null || p == prefs.appPalette) return;
    state = AsyncData(prefs.copyWith(appPalette: p));
  }

  /// Sets the theme mode.
  void setThemeMode(ThemeMode m) {
    final prefs = state.value;
    if (prefs == null || m == prefs.themeMode) return;
    state = AsyncData(prefs.copyWith(themeMode: m));
  }

  /// Toggles the theme mode between light and dark.
  void toggleThemeMode() => setThemeMode(
    state.value?.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
  );
}

// ---------------------------------------------------------------------------
// State Settings
// ---------------------------------------------------------------------------

/// Notifier for application state settings.
///
/// Persisted via [JsonPersist]. Contains sidebar/quran/analytics state.
@riverpod
@JsonPersist()
class StateSettingsNotifier extends _$StateSettingsNotifier {
  @override
  Future<StateSettings> build() async {
    await persist(
      ref.read(settingsStorageProvider),
      options: const StorageOptions(
        cacheTime: StorageCacheTime.unsafe_forever,
      ),
    ).future;
    return state.value ?? StateSettings.initial();
  }

  Future<void> _update(
    StateSettings Function(StateSettings) fn,
    String field,
  ) async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!state.hasValue) return;
      final newState = fn(state.value!);
      state = AsyncData(newState);
      ref.read(loggerProvider).i('[StateSettingsNotifier] $field updated');
    });
  }

  /// Updates the quran state with a transform function.
  Future<void> _updateQuranState(
    QuranScreenState Function(QuranScreenState) fn,
    String field,
  ) => _update(
    (s) => s.copyWith(quranState: fn(s.quranState)),
    field,
  );

  /// Sets the sidebar collapsed state.
  Future<void> setSidebarCollapsed({required bool collapsed}) =>
      _update((s) => s.copyWith(sidebarCollapsed: collapsed), 'Sidebar');

  /// Sets the prayer analytics period.
  Future<void> setPrayerAnalyticsPeriod(PrayerAnalyticsPeriod period) =>
      _update(
        (s) => s.copyWith(prayerAnalyticsPeriod: period),
        'Prayer analytics period',
      );

  /// Sets the last Quran page info.
  Future<void> setLastQuranPageInfo(MushafPageInfo info) =>
      _updateQuranState((s) => s.copyWith(pageInfo: info), 'Last Quran page');

  /// Sets the reading layout.
  Future<void> setLastLayout(QuranReadingLayout layout) =>
      _updateQuranState((s) => s.copyWith(layout: layout), 'Layout');

  /// Sets the font size.
  Future<void> setFontSize(FontSizes size) =>
      _updateQuranState((s) => s.copyWith(fontSize: size), 'Font size');

  /// Sets the selected ayah.
  Future<void> selectAyah(Ayah? ayah) =>
      _updateQuranState((s) => s.copyWith(selectedAyah: ayah), 'Selected ayah');

  /// Sets the tafsir accordion expanded state.
  Future<void> setTafsirEnabled({required bool enabled}) => _updateQuranState(
    (s) => s.copyWith(tafsirEnabled: enabled),
    'Tafsir enabled',
  );

  /// Sets the translation accordion expanded state.
  Future<void> setTranslationEnabled({required bool enabled}) =>
      _updateQuranState(
        (s) => s.copyWith(translationEnabled: enabled),
        'Translation enabled',
      );
}

// ---------------------------------------------------------------------------
// First Prayer Recorded Date
// ---------------------------------------------------------------------------

/// Persisted date of the first prayer ever recorded.
///
/// Stored as an ISO 8601 string. This replaces the old Prf-based setting and
/// is used by prayer analytics / completion providers.
@riverpod
@JsonPersist()
class FirstPrayerRecordedDate extends _$FirstPrayerRecordedDate {
  @override
  String? build() {
    persist(
      ref.read(settingsStorageProvider),
      options: const StorageOptions(
        cacheTime: StorageCacheTime.unsafe_forever,
      ),
    );
    return null;
  }

  @override
  String get key => 'first_prayer_recorded_date';

  /// Sets the date only if not already set.
  void setIfNull(DateTime date) {
    if (state != null) return;
    state = date.toIso8601String();
  }
}

// ---------------------------------------------------------------------------
// Derived Providers
// ---------------------------------------------------------------------------

/// The full [ThemeSettings] derived from the persisted [ThemePrefs].
@riverpod
ThemeSettings themeSettingsFromPrefs(Ref ref) {
  final prefs = ref.watch(themeProvider).value ?? ThemePrefs.defaults();
  return ThemeSettings(
    appPalette: prefs.appPalette,
    themeMode: prefs.themeMode,
    colorScheme: resolveColorScheme(prefs.appPalette, prefs.themeMode),
  );
}

/// The parsed [DateTime] from the persisted first-prayer-recorded date string.
@riverpod
DateTime? firstPrayerRecordedDateTime(Ref ref) {
  final raw = ref.watch(firstPrayerRecordedDateProvider);
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}
