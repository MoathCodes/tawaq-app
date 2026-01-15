import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hasanat/core/logging/logger_provider.dart';
import 'package:hasanat/core/theme/theme.dart';
import 'package:hasanat/core/utils/location_extensions.dart';
import 'package:hasanat/feature/quran/domain/models/quran_layouts.dart';
import 'package:hasanat/feature/settings/data/models/prayer_settings_model.dart';
import 'package:hasanat/feature/settings/data/models/state_settings.dart';
import 'package:hasanat/feature/settings/service/location_service.dart';
import 'package:hasanat/feature/settings/service/settings_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timezone/timezone.dart';

part 'settings_provider.g.dart';

const String _localeNotifierLogPrefix = '[LocaleNotifier]';
const String _prayerSettingsNotifierLogPrefix = '[PrayerSettingsNotifier]';
const String _themeNotifierLogPrefix = '[ThemeNotifier]';

/// Notifier for the application locale.
@riverpod
class LocaleNotifier extends _$LocaleNotifier {
  @override
  FutureOr<Locale> build() {
    final log = ref.read(loggerProvider)
      ..i('$_localeNotifierLogPrefix Building Locale...');
    final services = ref.read(settingsServiceProvider);
    final locale = services.getLocale();
    log.i('$_localeNotifierLogPrefix Locale loaded: $locale');
    return locale;
  }

  /// Returns true if the current locale is Arabic.
  bool isArabic() {
    return state.value?.languageCode == 'ar';
  }

  /// Sets the application locale.
  void setLocale(Locale newLocale) {
    if (newLocale == state.value || state.value == null) return;
    final log = ref.read(loggerProvider)
      ..i('$_localeNotifierLogPrefix Setting locale to: $newLocale');
    ref.read(settingsServiceProvider).setLocale(newLocale);
    state = AsyncData(newLocale);
    log.i('$_localeNotifierLogPrefix Locale set to: $newLocale');
  }

  /// Toggles the application locale between English and Arabic.
  void toggleLocale() {
    if (state.value == null) return;
    ref.read(loggerProvider).i('$_localeNotifierLogPrefix Toggling locale...');
    final currentLocale = state.value!;
    final newLocale = currentLocale.languageCode == 'ar'
        ? const Locale('en')
        : const Locale('ar');
    setLocale(newLocale);
  }
}

/// Notifier for prayer settings.
@riverpod
class PrayerSettingsNotifier extends _$PrayerSettingsNotifier {
  @override
  FutureOr<PrayerSettings> build() {
    final log = ref.read(loggerProvider)
      ..i('$_prayerSettingsNotifierLogPrefix Building PrayerSettings...');
    final services = ref.read(settingsServiceProvider);
    final prayerSettings = services.getPrayerSettings();
    log.i(
      '$_prayerSettingsNotifierLogPrefix PrayerSettings loaded: '
      '$prayerSettings',
    );
    return prayerSettings;
  }

  /// Sets whether to use 24-hour time format.
  void set24HourFormat({required bool value}) {
    if (state.value == null) return;
    final log = ref.read(loggerProvider)
      ..i(
        '$_prayerSettingsNotifierLogPrefix Setting 24 hour format to: $value',
      );
    if (state.value!.is24Hours == value) {
      log.w(
        '$_prayerSettingsNotifierLogPrefix 24 format settings are the same, '
        'not updating.',
      );
      return;
    }
    final service = ref.read(settingsServiceProvider);
    final newSettings = state.value!.copyWith(is24Hours: value);
    service.setPrayerSettings(newSettings);
    state = AsyncData(newSettings);
    log.i(
      '$_prayerSettingsNotifierLogPrefix 24 hour format set to: $value',
    );
  }

  /// Sets the coordinates for prayer time calculations.
  void setCoordinates(Coordinates coordinates) {
    if (state.value == null) return;
    final log = ref.read(loggerProvider)
      ..i(
        '$_prayerSettingsNotifierLogPrefix Setting coordinates to: $coordinates',
      );
    final service = ref.read(settingsServiceProvider);
    final newSettings = state.value!.copyWith(coordinates: coordinates);
    if (state.value == newSettings) {
      log.w(
        '$_prayerSettingsNotifierLogPrefix Coordinates are the same, '
        'not updating.',
      );
      return;
    }
    service.setPrayerSettings(newSettings);
    state = AsyncData(newSettings);
    log.i(
      '$_prayerSettingsNotifierLogPrefix Coordinates set to: $coordinates',
    );
  }

  /// Sets the iqamah times for prayers.
  void setIqamahTimes(Map<Prayer, int> iqamahTimes) {
    if (state.value == null) return;
    final log = ref.read(loggerProvider)
      ..i(
        '$_prayerSettingsNotifierLogPrefix Setting Iqamah times to: $iqamahTimes',
      );
    final service = ref.read(settingsServiceProvider);
    final newSettings = state.value!.copyWith(iqamahSettings: iqamahTimes);
    if (state.value == newSettings) {
      log.w(
        '$_prayerSettingsNotifierLogPrefix Iqamah times are the same, '
        'not updating.',
      );
      return;
    }
    service.setPrayerSettings(newSettings);
    state = AsyncData(newSettings);
    log.i(
      '$_prayerSettingsNotifierLogPrefix Iqamah times set to: $iqamahTimes',
    );
  }

  /// Sets the timezone location for prayer time calculations.
  void setLocation(Location location) {
    if (state.value == null) return;
    final log = ref.read(loggerProvider)
      ..i(
        '$_prayerSettingsNotifierLogPrefix Setting location to: $location',
      );
    final service = ref.read(settingsServiceProvider);
    final newSettings = state.value!.copyWith(location: location);
    if (state.value == newSettings) {
      log.w(
        '$_prayerSettingsNotifierLogPrefix Location is the same, not updating.',
      );
      return;
    }
    service.setPrayerSettings(newSettings);
    state = AsyncData(newSettings);
    log.i('$_prayerSettingsNotifierLogPrefix Location set to: $location');
  }

  /// Sets whether to use automatic location detection.
  void setAutoLocation({required bool value}) {
    if (state.value == null) return;
    final log = ref.read(loggerProvider)
      ..i(
        '$_prayerSettingsNotifierLogPrefix Setting auto location to: $value',
      );
    if (state.value!.autoLocation == value) {
      log.w(
        '$_prayerSettingsNotifierLogPrefix Auto location is the same, '
        'not updating.',
      );
      return;
    }
    final service = ref.read(settingsServiceProvider);
    final newSettings = state.value!.copyWith(autoLocation: value);
    service.setPrayerSettings(newSettings);
    state = AsyncData(newSettings);
    log.i(
      '$_prayerSettingsNotifierLogPrefix Auto location set to: $value',
    );
  }

  /// Sets the display name for the current location.
  void setLocationName(String locationName) {
    if (state.value == null) return;
    final log = ref.read(loggerProvider)
      ..i(
        '$_prayerSettingsNotifierLogPrefix Setting location name to: '
        '$locationName',
      );
    final service = ref.read(settingsServiceProvider);
    final newSettings = state.value!.copyWith(locationName: locationName);
    if (state.value == newSettings) {
      log.w(
        '$_prayerSettingsNotifierLogPrefix Location name is the same, '
        'not updating.',
      );
      return;
    }
    service.setPrayerSettings(newSettings);
    state = AsyncData(newSettings);
    log.i(
      '$_prayerSettingsNotifierLogPrefix Location name set to: $locationName',
    );
  }

  /// Sets the complete prayer settings object.
  void setPrayerSettings(PrayerSettings settings) {
    if (state.value == null) return;
    final log = ref.read(loggerProvider)
      ..i(
        '$_prayerSettingsNotifierLogPrefix Setting prayer settings to: $settings',
      );
    if (state.value == settings) {
      log.w(
        '$_prayerSettingsNotifierLogPrefix Prayer settings are the same, '
        'not updating.',
      );
      return;
    }
    ref.read(settingsServiceProvider).setPrayerSettings(settings);
    state = AsyncData(settings);
    log.i(
      '$_prayerSettingsNotifierLogPrefix Prayer settings set to: $settings',
    );
  }

  @override
  Future<PrayerSettings> update(
    FutureOr<PrayerSettings> Function(PrayerSettings p1) cb, {
    FutureOr<PrayerSettings> Function(Object err, StackTrace stackTrace)?
    onError,
  }) {
    final log = ref.read(loggerProvider)
      ..i(
        '$_prayerSettingsNotifierLogPrefix Updating prayer settings...',
      );
    final previous = state.value;
    return super
        .update(
          cb,
          onError: (err, stackTrace) {
            log.e(
              '$_prayerSettingsNotifierLogPrefix Error updating prayer '
              'settings',
              error: err,
              stackTrace: stackTrace,
            );
            if (onError != null) {
              return onError(err, stackTrace);
            }
            // Re-throw the error if no custom onError is provided to maintain original behavior
            throw Exception(err);
          },
        )
        .then((value) {
          // Persist changes so they survive hot restart/app relaunch.
          if (previous != value) {
            final service = ref.read(settingsServiceProvider);
            service.setPrayerSettings(value);
            log.i(
              '$_prayerSettingsNotifierLogPrefix Prayer settings updated and '
              'persisted: $value',
            );
          } else {
            log.i(
              '$_prayerSettingsNotifierLogPrefix No changes detected '
              'after update; skipping persistence.',
            );
          }
          return value;
        });
  }

  /// Updates location-related data in prayer settings.
  Future<void> updateLocationData({
    Coordinates? coordinates,
    String? locationName,
    Location? location,
  }) async {
    if (state.value == null) return;
    final log = ref.read(loggerProvider);

    log.i(
      '$_prayerSettingsNotifierLogPrefix Updating location data - '
      'coordinates: $coordinates, locationName: $locationName, '
      'location: $location',
    );

    final finalCoordinates = coordinates;
    final finalLocationName = locationName;
    var finalLocation = location;

    // If we have coordinates but need location
    if (finalCoordinates != null && finalLocation == null) {
      try {
        finalLocation = ref
            .read(locationServiceProvider)
            .getLocationFromCoordinatesOffline(finalCoordinates);
        log.i(
          '$_prayerSettingsNotifierLogPrefix Auto-resolved location from '
          'coordinates: $finalLocation',
        );
      } catch (e) {
        log.e(
          '$_prayerSettingsNotifierLogPrefix Failed to resolve location from coordinates',
          error: e,
        );
      }
    }

    final newSettings = state.value!.copyWith(
      coordinates: finalCoordinates ?? state.value!.coordinates,
      locationName: finalLocationName ?? state.value!.locationName,
      location: finalLocation ?? state.value!.location,
    );

    if (state.value == newSettings) {
      log.w(
        '$_prayerSettingsNotifierLogPrefix No changes detected, not updating.',
      );
      return;
    }

    await ref.read(settingsServiceProvider).setPrayerSettings(newSettings);
    state = AsyncData(newSettings);

    log.i(
      '$_prayerSettingsNotifierLogPrefix Location data updated successfully - '
      'coordinates: ${newSettings.coordinates}, '
      'locationName: ${newSettings.locationName}, '
      'location: ${newSettings.location}',
    );
  }

  /// Fetches and sets the current device location.
  ///
  /// This will request location permissions if needed, get the current
  /// GPS position, fetch place details for the location name, and
  /// update all location-related settings.
  Future<void> useCurrentLocation() async {
    final log = ref.read(loggerProvider)
      ..i('$_prayerSettingsNotifierLogPrefix Using current location...');

    final locationService = ref.read(locationServiceProvider);
    final currentLocation = await locationService.getCurrentPosition();
    final placeDetails = await locationService.getPlaceDetails(
      currentLocation.coordinates,
    );
    final name = placeDetails.name.isNotEmpty
        ? placeDetails.name
        : 'Unknown Location';

    await updateLocationData(
      coordinates: currentLocation.coordinates,
      locationName: name,
    );

    log.i(
      '$_prayerSettingsNotifierLogPrefix Current location set: $name at '
      '$currentLocation',
    );
  }

  /// Sets the timezone from the system's current timezone.
  ///
  /// Optionally accepts a [Location] to set directly. If not provided,
  /// the system timezone will be detected and used.
  Future<void> setSystemTimezone([Location? loc]) async {
    final log = ref.read(loggerProvider)
      ..i('$_prayerSettingsNotifierLogPrefix Setting system timezone...');

    final timezone = await FlutterTimezone.getLocalTimezone();
    loc ??= getLocation(timezone.identifier);
    setLocation(loc);

    log.i(
      '$_prayerSettingsNotifierLogPrefix System timezone set: ${loc.name}',
    );
  }

  /// Updates the iqamah time for a specific prayer.
  void updatePrayerIqamahTime(Prayer prayer, int iqamahTime) {
    if (state.value == null) return;
    final log = ref.read(loggerProvider);
    final currentSettings = state.value!;
    final currentIqamah = currentSettings.iqamahSettings[prayer] ?? 0;
    if (currentIqamah == iqamahTime) {
      log.w(
        '[33m$_prayerSettingsNotifierLogPrefix Iqamah time for $prayer already $iqamahTime, not updating.[0m',
      );
      return;
    }

    log.i(
      '$_prayerSettingsNotifierLogPrefix Updating $prayer iqamah time to: '
      '$iqamahTime',
    );

    // Create a new map to avoid mutating the existing one.
    final newIqamahSettings = Map<Prayer, int>.from(
      currentSettings.iqamahSettings,
    )..[prayer] = iqamahTime;

    final newSettings = currentSettings.copyWith(
      iqamahSettings: newIqamahSettings,
    );

    // Persist via service and update state.
    ref.read(settingsServiceProvider).setPrayerSettings(newSettings);
    state = AsyncData(newSettings);

    log.i(
      '$_prayerSettingsNotifierLogPrefix Iqamah time for $prayer set to: '
      '$iqamahTime',
    );
  }
}

/// Notifier for theme settings.
@riverpod
class ThemeNotifier extends _$ThemeNotifier {
  @override
  FutureOr<ThemeSettings> build() async {
    final log = ref.read(loggerProvider);
    log.i('$_themeNotifierLogPrefix Building ThemeSettings...');
    final services = ref.watch(settingsServiceProvider);
    final appPalette = await services.getAppPalette();
    final themeMode = await services.getThemeMode();
    final settings = ThemeSettings(
      appPalette: appPalette,
      themeMode: themeMode,
      colorScheme: resolveColorScheme(appPalette, themeMode),
    );
    log.i('$_themeNotifierLogPrefix ThemeSettings loaded: $settings');
    return settings;
  }

  /// Sets the application palette.
  void setPalette(AppPalette newPalette) {
    if (newPalette == state.value?.appPalette || state.value == null) {
      return;
    }
    final log = ref.read(loggerProvider)
      ..i('$_themeNotifierLogPrefix Setting palette to: $newPalette');

    ref.read(settingsServiceProvider).setAppPalette(newPalette);
    final newColorScheme = resolveColorScheme(
      newPalette,
      state.value!.themeMode,
    );
    state = AsyncData(
      state.value!.copyWith(
        appPalette: newPalette,
        colorScheme: newColorScheme,
      ),
    );
    log.i('$_themeNotifierLogPrefix Palette set to: $newPalette');
  }

  /// Sets the theme mode.
  void setThemeMode(ThemeMode newThemeMode) {
    if (newThemeMode == state.value?.themeMode || state.value == null) {
      return;
    }
    final log = ref.read(loggerProvider);
    log.i(
      '$_themeNotifierLogPrefix Setting theme mode to: $newThemeMode',
    );

    final newColorScheme = resolveColorScheme(
      state.value!.appPalette,
      newThemeMode,
    );

    ref.read(settingsServiceProvider).setThemeMode(newThemeMode);
    state = AsyncData(
      state.value!.copyWith(
        themeMode: newThemeMode,
        colorScheme: newColorScheme,
      ),
    );
    log.i('$_themeNotifierLogPrefix Theme mode set to: $newThemeMode');
  }

  /// Toggles the theme mode between light and dark.
  void toggleThemeMode() {
    ref
        .read(loggerProvider)
        .i('$_themeNotifierLogPrefix Toggling theme mode...');
    final newThemeMode = state.value?.themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    setThemeMode(newThemeMode);
  }
}

@riverpod
/// Notifier for application state settings.
///
/// Can be used to manage settings like sidebar collapsed state,
/// last Quran page, reading layout, etc.
class StateSettingsNotifier extends _$StateSettingsNotifier {
  @override
  Future<StateSettings> build() async {
    final stateSettings = await ref
        .read(settingsServiceProvider)
        .getAppStateSettings();
    // log.d('State Settings: $stateSettings');
    return stateSettings;
  }

  Future<void> setSidebarCollapsed({required bool collapsed}) async {
    if (!state.hasValue) return;
    final log = ref.read(loggerProvider)
      ..i(
        '[StateSettingsNotifier] Setting sidebar collapsed to: $collapsed',
      );
    final newState = state.value!.copyWith(
      sidebarCollapsed: collapsed,
    );
    state = AsyncData(newState);
    await ref.read(settingsServiceProvider).setAppStateSettings(newState);
    log.i(
      '[StateSettingsNotifier] Sidebar collapsed set to: $collapsed',
    );
  }

  Future<void> setLastQuranPage(int page) async {
    if (!state.hasValue) return;
    final log = ref.read(loggerProvider)
      ..i(
        '[StateSettingsNotifier] Setting last Quran page to: $page',
      );
    final newState = state.value!.copyWith(
      lastQuranPage: page,
    );
    state = AsyncData(newState);
    await ref.read(settingsServiceProvider).setAppStateSettings(newState);
    log.i(
      '[StateSettingsNotifier] Last Quran page set to: $page',
    );
  }

  Future<void> setLastLayout(QuranReadingLayout layout) async {
    if (!state.hasValue) return;
    final log = ref.read(loggerProvider)
      ..i(
        '[StateSettingsNotifier] Setting reading layout to: $layout',
      );
    final newState = state.value!.copyWith(
      lastLayout: layout,
    );
    state = AsyncData(newState);
    await ref.read(settingsServiceProvider).setAppStateSettings(newState);
    log.i(
      '[StateSettingsNotifier] Reading layout set to: $layout',
    );
  }
}
