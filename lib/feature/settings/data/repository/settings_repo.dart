import 'package:flutter/material.dart';
import 'package:hasanat/core/logging/logger_provider.dart';
import 'package:hasanat/core/theme/theme.dart';
import 'package:hasanat/feature/settings/data/models/prayer_settings_model.dart';
import 'package:hasanat/l10n/app_localizations.dart';
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
