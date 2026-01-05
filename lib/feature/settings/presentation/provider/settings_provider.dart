import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:hasanat/core/logging/logger_provider.dart';
import 'package:hasanat/core/theme/theme.dart';
import 'package:hasanat/feature/settings/data/models/prayer_settings_model.dart';
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
    final log = ref.read(loggerProvider);
    log.i('$_localeNotifierLogPrefix Building Locale...');
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
    final log = ref.read(loggerProvider);
    log.i('$_localeNotifierLogPrefix Setting locale to: $newLocale');
    final service = ref.read(settingsServiceProvider);
    service.setLocale(newLocale);
    state = AsyncData(newLocale);
    log.i('$_localeNotifierLogPrefix Locale set to: $newLocale');
  }

  /// Toggles the application locale between English and Arabic.
  void toggleLocale() {
    if (state.value == null) return;
    final log = ref.read(loggerProvider);
    log.i('$_localeNotifierLogPrefix Toggling locale...');
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
    final log = ref.read(loggerProvider);
    log.i('$_prayerSettingsNotifierLogPrefix Building PrayerSettings...');
    final services = ref.read(settingsServiceProvider);
    final prayerSettings = services.getPrayerSettings();
    log.i(
      '$_prayerSettingsNotifierLogPrefix PrayerSettings loaded: $prayerSettings',
    );
    return prayerSettings;
  }

  /// Sets whether to use 24-hour time format.
  void set24HourFormat({required bool value}) {
    if (state.value == null) return;
    final log = ref.read(loggerProvider);
    log.i(
      '$_prayerSettingsNotifierLogPrefix Setting 24 hour format to: $value',
    );
    if (state.value!.is24Hours == value) {
      log.w(
        '$_prayerSettingsNotifierLogPrefix 24 format settings are the same, not updating.',
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
    final log = ref.read(loggerProvider);
    log.i(
      '$_prayerSettingsNotifierLogPrefix Setting coordinates to: $coordinates',
    );
    final service = ref.read(settingsServiceProvider);
    final newSettings = state.value!.copyWith(coordinates: coordinates);
    if (state.value == newSettings) {
      log.w(
        '$_prayerSettingsNotifierLogPrefix Coordinates are the same, not updating.',
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
    final log = ref.read(loggerProvider);
    log.i(
      '$_prayerSettingsNotifierLogPrefix Setting Iqamah times to: $iqamahTimes',
    );
    final service = ref.read(settingsServiceProvider);
    final newSettings = state.value!.copyWith(iqamahSettings: iqamahTimes);
    if (state.value == newSettings) {
      log.w(
        '$_prayerSettingsNotifierLogPrefix Iqamah times are the same, not updating.',
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
    final log = ref.read(loggerProvider);
    log.i(
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

  /// Sets the display name for the current location.
  void setLocationName(String locationName) {
    if (state.value == null) return;
    final log = ref.read(loggerProvider);
    log.i(
      '$_prayerSettingsNotifierLogPrefix Setting location name to: $locationName',
    );
    final service = ref.read(settingsServiceProvider);
    final newSettings = state.value!.copyWith(locationName: locationName);
    if (state.value == newSettings) {
      log.w(
        '$_prayerSettingsNotifierLogPrefix Location name is the same, not updating.',
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
    final log = ref.read(loggerProvider);
    log.i(
      '$_prayerSettingsNotifierLogPrefix Setting prayer settings to: $settings',
    );
    if (state.value == settings) {
      log.w(
        '$_prayerSettingsNotifierLogPrefix Prayer settings are the same, not updating.',
      );
      return;
    }
    final service = ref.read(settingsServiceProvider);
    service.setPrayerSettings(settings);
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
    final log = ref.read(loggerProvider);
    log.i(
      '$_prayerSettingsNotifierLogPrefix Updating prayer settings...',
    );
    final previous = state.value;
    return super
        .update(
          cb,
          onError: (err, stackTrace) {
            log.e(
              '$_prayerSettingsNotifierLogPrefix Error updating prayer settings',
              error: err,
              stackTrace: stackTrace,
            );
            if (onError != null) {
              return onError(err, stackTrace);
            }
            // Re-throw the error if no custom onError is provided to maintain original behavior
            throw err;
          },
        )
        .then((value) {
          // Persist changes so they survive hot restart/app relaunch.
          if (previous != value) {
            final service = ref.read(settingsServiceProvider);
            service.setPrayerSettings(value);
            log.i(
              '$_prayerSettingsNotifierLogPrefix Prayer settings updated and persisted: $value',
            );
          } else {
            log.i(
              '$_prayerSettingsNotifierLogPrefix No changes detected after update; skipping persistence.',
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
      '$_prayerSettingsNotifierLogPrefix Updating location data - coordinates: $coordinates, locationName: $locationName, location: $location',
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
          '$_prayerSettingsNotifierLogPrefix Auto-resolved location from coordinates: $finalLocation',
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

    final service = ref.read(settingsServiceProvider);
    service.setPrayerSettings(newSettings);
    state = AsyncData(newSettings);

    log.i(
      '$_prayerSettingsNotifierLogPrefix Location data updated successfully - coordinates: ${newSettings.coordinates}, locationName: ${newSettings.locationName}, location: ${newSettings.location}',
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
      '$_prayerSettingsNotifierLogPrefix Updating $prayer iqamah time to: $iqamahTime',
    );

    // Create a new map to avoid mutating the existing one.
    final newIqamahSettings = Map<Prayer, int>.from(
      currentSettings.iqamahSettings,
    )..[prayer] = iqamahTime;

    final newSettings = currentSettings.copyWith(
      iqamahSettings: newIqamahSettings,
    );

    // Persist via service and update state.
    final service = ref.read(settingsServiceProvider);
    service.setPrayerSettings(newSettings);
    state = AsyncData(newSettings);

    log.i(
      '$_prayerSettingsNotifierLogPrefix Iqamah time for $prayer set to: $iqamahTime',
    );
  }
}

/// Notifier for theme settings.
@riverpod
class ThemeNotifier extends _$ThemeNotifier {
  @override
  FutureOr<ThemeSettings> build() async {
    final log = ref.watch(loggerProvider);
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
    final log = ref.read(loggerProvider);
    log.i('$_themeNotifierLogPrefix Setting palette to: $newPalette');

    final service = ref.read(settingsServiceProvider);
    service.setAppPalette(newPalette);
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

    final service = ref.read(settingsServiceProvider);
    service.setThemeMode(newThemeMode);
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
    final log = ref.read(loggerProvider);
    log.i('$_themeNotifierLogPrefix Toggling theme mode...');
    final newThemeMode = state.value?.themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    setThemeMode(newThemeMode);
  }
}
