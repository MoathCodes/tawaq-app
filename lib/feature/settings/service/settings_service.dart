import 'package:flutter/material.dart';
import 'package:hasanat/core/logging/logger_provider.dart';
import 'package:hasanat/core/theme/theme.dart';
import 'package:hasanat/feature/settings/data/models/prayer_settings_model.dart';
import 'package:hasanat/feature/settings/data/repository/settings_repo.dart';
import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_service.g.dart';

/// Provider for the [SettingsService].
@riverpod
SettingsService settingsService(Ref ref) {
  final settingsRepository = ref.read(settingsRepositoryProvider);
  final log = ref.read(loggerProvider);
  return SettingsService(settingsRepository, log);
}

/// Service for managing application settings.
class SettingsService {
  /// Creates a new [SettingsService] instance.
  SettingsService(this._settingsRepository, this._log);
  final SettingsRepo _settingsRepository;
  final Logger _log;

  /// Retrieves the current application palette.
  Future<AppPalette> getAppPalette() async {
    return _settingsRepository.getAppPalette();
  }

  /// Retrieves the current application locale.
  Future<Locale> getLocale() async {
    return _settingsRepository.getLocale();
  }

  /// Retrieves the current prayer settings.
  Future<PrayerSettings> getPrayerSettings() async {
    return _settingsRepository.getPrayerSettings();
  }

  /// Retrieves the current theme mode.
  Future<ThemeMode> getThemeMode() async {
    return _settingsRepository.getThemeMode();
  }

  /// Updates the application palette.
  Future<void> setAppPalette(AppPalette appPalette) async {
    const logPrefix = '[SettingsService.setAppPalette] ';
    try {
      _log.d('$logPrefix Setting app palette to: ${appPalette.name}');
      await _settingsRepository.setAppPalette(appPalette);
    } catch (e, stackTrace) {
      _log.e('$logPrefix Error', error: e, stackTrace: stackTrace);
    }
  }

  /// Updates the application locale.
  Future<void> setLocale(Locale locale) async {
    const logPrefix = '[SettingsService.setLocale] ';
    try {
      _log.d('$logPrefix Setting locale to: ${locale.languageCode}');
      await _settingsRepository.setLocale(locale);
    } catch (e, stackTrace) {
      _log.e('$logPrefix Error', error: e, stackTrace: stackTrace);
    }
  }

  /// Updates the prayer settings.
  Future<void> setPrayerSettings(PrayerSettings settings) async {
    const logPrefix = '[SettingsService.setPrayerSettings] ';
    try {
      _log.d('$logPrefix Setting prayer settings: ${settings.toJson()}');
      await _settingsRepository.setPrayerSettings(settings);
    } catch (e, stackTrace) {
      _log.e('$logPrefix Error', error: e, stackTrace: stackTrace);
    }
  }

  /// Updates the theme mode.
  Future<void> setThemeMode(ThemeMode themeMode) async {
    const logPrefix = '[SettingsService.setThemeMode] ';
    try {
      _log.d('$logPrefix Setting theme mode to: ${themeMode.name}');
      await _settingsRepository.setThemeMode(themeMode);
    } catch (e, stackTrace) {
      _log.e('$logPrefix Error', error: e, stackTrace: stackTrace);
    }
  }

  /// Retrieves the date of the first recorded prayer.
  Future<DateTime?> getFirstPrayerRecordedDate() async {
    return _settingsRepository.getFirstPrayerRecordedDate();
  }

  /// Sets the date of the first recorded prayer (only if not already set).
  Future<void> setFirstPrayerRecordedDateIfNull(DateTime date) async {
    await _settingsRepository.setFirstPrayerRecordedDateIfNull(date);
  }
}
