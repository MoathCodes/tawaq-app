import 'package:flutter/material.dart';
import 'package:hasanat/core/logging/logger_provider.dart';
import 'package:hasanat/feature/settings/data/models/prayer_settings_model.dart';
import 'package:hasanat/feature/settings/data/models/state_settings.dart';
import 'package:hasanat/l10n/app_localizations.dart';
import 'package:hasanat/theme/theme_model.dart';
import 'package:logger/logger.dart';
import 'package:prf/prf.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_repo.g.dart';

/// Provider for the [SettingsRepo].
@riverpod
SettingsRepo settingsRepository(Ref ref) {
  final log = ref.read(loggerProvider);
  return SettingsRepo(log);
}

/// Repository for managing application settings.
class SettingsRepo {
  /// Creates a [SettingsRepo] instance.
  SettingsRepo(this._log);
  final Logger _log;
  final Prf<AppPalette> _appPalette = Prf.enumerated<AppPalette>(
    'app_palette',
    values: AppPalette.values,
    defaultValue: AppPalette.zinc,
  );
  final Prf<ThemeMode> _themeMode = Prf.enumerated<ThemeMode>(
    'theme_mode',
    values: ThemeMode.values,
    defaultValue: ThemeMode.light,
  );
  final Prf<Locale> _langPref = Prf.cast<Locale, String>(
    'saved_language',
    defaultValue: const Locale('en'),
    encode: (locale) => locale.languageCode,
    decode: (string) => string == null ? null : Locale(string),
  );
  final Prf<PrayerSettings> _prayerSettings = Prf.json<PrayerSettings>(
    'prayer_settings',
    defaultValue: PrayerSettings.defaultSettings(),
    fromJson: PrayerSettings.fromJson,
    toJson: (object) => object.toJson(),
  );
  final Prf<DateTime?> _firstPrayerRecordedDate = Prf.cast<DateTime?, String>(
    'first_prayer_recorded_date',
    encode: (date) => date?.toIso8601String() ?? '',
    decode: (string) =>
        string == null || string.isEmpty ? null : DateTime.parse(string),
  );
  final Prf<StateSettings> _appStateSettings = Prf.json(
    'app_state_settings',
    fromJson: StateSettings.fromJson,
    toJson: (object) => object.toJson(),
    defaultValue: StateSettings.initial(),
  );

  /// Returns the date of the first recorded prayer.
  Future<DateTime?> getFirstPrayerRecordedDate() async {
    return _firstPrayerRecordedDate.get();
  }

  /// Returns the current app state settings.
  Future<StateSettings> getAppStateSettings() async {
    return _appStateSettings.getOrDefault();
  }

  /// Sets the app state settings.
  Future<void> setAppStateSettings(StateSettings settings) async {
    const logPrefix = '[SettingsRepo.setAppStateSettings] ';
    try {
      _log.d('$logPrefix Setting app state settings: ${settings.toJson()}');
      await _appStateSettings.set(settings);
    } catch (e, stackTrace) {
      _log.e('$logPrefix Error', error: e, stackTrace: stackTrace);
    }
  }

  /// Sets the date of the first recorded prayer (only if not already set).
  Future<void> setFirstPrayerRecordedDateIfNull(DateTime date) async {
    const logPrefix = '[SettingsRepo.setFirstPrayerRecordedDateIfNull] ';
    try {
      final existing = await _firstPrayerRecordedDate.get();
      if (existing == null) {
        _log.d('$logPrefix Setting first prayer recorded date to: $date');
        await _firstPrayerRecordedDate.set(date);
      }
    } catch (e, stackTrace) {
      _log.e('$logPrefix Error', error: e, stackTrace: stackTrace);
    }
  }

  /// Returns the current application palette.
  Future<AppPalette> getAppPalette() async {
    return _appPalette.getOrDefault();
  }

  /// Returns the current locale.
  Future<Locale> getLocale() async {
    return _langPref.getOrDefault();
  }

  /// Returns the current prayer settings.
  Future<PrayerSettings> getPrayerSettings() async {
    return _prayerSettings.getOrDefault();
  }

  /// Returns the current theme mode.
  Future<ThemeMode> getThemeMode() async {
    return _themeMode.getOrDefault();
  }

  /// Sets the application palette.
  Future<void> setAppPalette(AppPalette appPalette) async {
    const logPrefix = '[SettingsRepo.setAppPalette] ';
    try {
      _log.d('$logPrefix Setting app palette to: ${appPalette.name}');
      await _appPalette.set(appPalette);
    } catch (e, stackTrace) {
      _log.e('$logPrefix Error', error: e, stackTrace: stackTrace);
    }
  }

  /// Sets the locale.
  Future<void> setLocale(Locale locale) async {
    const logPrefix = '[SettingsRepo.setLocale] ';
    try {
      _log.d('$logPrefix Setting locale to: ${locale.languageCode}');
      if (AppLocalizations.supportedLocales.contains(locale)) {
        _log.d('$logPrefix Locale is supported: ${locale.languageCode}');
        await _langPref.set(locale);
      } else {
        _log.w(
          '$logPrefix Locale not supported: ${locale.languageCode}',
        );
      }
    } catch (e, stackTrace) {
      _log.e('$logPrefix Error', error: e, stackTrace: stackTrace);
    }
  }

  /// Sets the prayer settings.
  Future<void> setPrayerSettings(PrayerSettings settings) async {
    const logPrefix = '[SettingsRepo.setPrayerSettings] ';
    try {
      _log.d('$logPrefix Setting prayer settings: ${settings.toJson()}');
      await _prayerSettings.set(settings);
    } catch (e, stackTrace) {
      _log.e('$logPrefix Error', error: e, stackTrace: stackTrace);
    }
  }

  /// Sets the theme mode.
  Future<void> setThemeMode(ThemeMode themeMode) async {
    const logPrefix = '[SettingsRepo.setThemeMode] ';
    try {
      _log.d('$logPrefix Setting theme mode to: ${themeMode.name}');
      await _themeMode.set(themeMode);
    } catch (e, stackTrace) {
      _log.e('$logPrefix Error', error: e, stackTrace: stackTrace);
    }
  }
}
