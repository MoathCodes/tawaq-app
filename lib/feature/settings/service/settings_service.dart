import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hasanat/core/logging/talker_provider.dart';
import 'package:hasanat/core/theme/theme.dart';
import 'package:hasanat/feature/settings/data/models/prayer_settings_model.dart';
import 'package:hasanat/feature/settings/data/repository/settings_repo.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'settings_service.g.dart';

@riverpod
SettingsService settingsService(Ref ref) {
  final settingsRepository = ref.read(settingsRepositoryProvider);
  final talker = ref.read(talkerNotifierProvider);
  return SettingsService(settingsRepository, talker);
}

class SettingsService {
  final SettingsRepo _settingsRepository;
  final Talker _talker;
  SettingsService(this._settingsRepository, this._talker);

  Future<AppPalette> getAppPalette() async {
    return _settingsRepository.getAppPalette();
  }

  Future<Locale> getLocale() async {
    return _settingsRepository.getLocale();
  }

  Future<PrayerSettings> getPrayerSettings() async {
    return _settingsRepository.getPrayerSettings();
  }

  Future<ThemeMode> getThemeMode() async {
    return _settingsRepository.getThemeMode();
  }

  Future<void> setAppPalette(AppPalette appPalette) async {
    const logPrefix = "[SettingsService.setAppPalette] ";
    try {
      _talker.debug("$logPrefix Setting app palette to: ${appPalette.name}");
      await _settingsRepository.setAppPalette(appPalette);
    } catch (e, stackTrace) {
      _talker.handle(e, stackTrace);
    }
  }

  Future<void> setLocale(Locale locale) async {
    const logPrefix = "[SettingsService.setLocale] ";
    try {
      _talker.debug("$logPrefix Setting locale to: ${locale.languageCode}");
      await _settingsRepository.setLocale(locale);
    } catch (e, stackTrace) {
      _talker.handle(e, stackTrace);
    }
  }

  Future<void> setPrayerSettings(PrayerSettings settings) async {
    const logPrefix = "[SettingsService.setPrayerSettings] ";
    try {
      _talker.debug("$logPrefix Setting prayer settings: ${settings.toJson()}");
      await _settingsRepository.setPrayerSettings(settings);
    } catch (e, stackTrace) {
      _talker.handle(e, stackTrace);
    }
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    const logPrefix = "[SettingsService.setThemeMode] ";
    try {
      _talker.debug("$logPrefix Setting theme mode to: ${themeMode.name}");
      await _settingsRepository.setThemeMode(themeMode);
    } catch (e, stackTrace) {
      _talker.handle(e, stackTrace);
    }
  }
}
