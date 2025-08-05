import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hasanat/core/logging/talker_provider.dart';
import 'package:hasanat/core/theme/theme.dart';
import 'package:hasanat/feature/settings/data/models/prayer_settings_model.dart';
import 'package:hasanat/l10n/app_localizations.dart';
import 'package:prf/prf.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'settings_repo.g.dart';

@riverpod
SettingsRepo settingsRepository(Ref ref) {
  final talker = ref.read(talkerNotifierProvider);
  return SettingsRepo(talker);
}

class SettingsRepo {
  final Talker _talker;
  final _appPalette = Prf.enumerated<AppPalette>(
    'app_palette',
    values: AppPalette.values,
    defaultValue: AppPalette.zinc,
  );
  final _themeMode = Prf.enumerated<ThemeMode>(
    'theme_mode',
    values: ThemeMode.values,
    defaultValue: ThemeMode.light,
  );
  final _langPref = Prf.cast<Locale, String>(
    'saved_language',
    defaultValue: const Locale('en'),
    encode: (locale) => locale.languageCode,
    decode: (string) => string == null ? null : Locale(string),
  );
  final _prayerSettings = Prf.json<PrayerSettings>(
    'prayer_settings',
    defaultValue: PrayerSettings.defaultSettings(),
    fromJson: (json) => PrayerSettings.fromJson(json),
    toJson: (object) => object.toJson(),
  );

  SettingsRepo(this._talker);

  Future<AppPalette> getAppPalette() async {
    return _appPalette.getOrDefault();
  }

  Future<Locale> getLocale() async {
    return _langPref.getOrDefault();
  }

  Future<PrayerSettings> getPrayerSettings() async {
    return _prayerSettings.getOrDefault();
  }

  Future<ThemeMode> getThemeMode() async {
    return _themeMode.getOrDefault();
  }

  Future<void> setAppPalette(AppPalette appPalette) async {
    const logPrefix = "[SettingsRepo.setAppPalette] ";
    try {
      _talker.debug("$logPrefix Setting app palette to: ${appPalette.name}");
      await _appPalette.set(appPalette);
    } catch (e, stackTrace) {
      _talker.handle(e, stackTrace);
    }
  }

  Future<void> setLocale(Locale locale) async {
    const logPrefix = "[SettingsRepo.setLocale] ";
    try {
      _talker.debug("$logPrefix Setting locale to: ${locale.languageCode}");
      if (AppLocalizations.supportedLocales.contains(locale)) {
        _talker.debug("$logPrefix Locale is supported: ${locale.languageCode}");
        await _langPref.set(locale);
      } else {
        _talker
            .warning("$logPrefix Locale not supported: ${locale.languageCode}");
      }
    } catch (e, stackTrace) {
      _talker.handle(e, stackTrace);
    }
  }

  Future<void> setPrayerSettings(PrayerSettings settings) async {
    const logPrefix = "[SettingsRepo.setPrayerSettings] ";
    try {
      _talker.debug("$logPrefix Setting prayer settings: ${settings.toJson()}");
      await _prayerSettings.set(settings);
    } catch (e, stackTrace) {
      _talker.handle(e, stackTrace);
    }
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    const logPrefix = "[SettingsRepo.setThemeMode] ";
    try {
      _talker.debug("$logPrefix Setting theme mode to: ${themeMode.name}");
      await _themeMode.set(themeMode);
    } catch (e, stackTrace) {
      _talker.handle(e, stackTrace);
    }
  }
}
