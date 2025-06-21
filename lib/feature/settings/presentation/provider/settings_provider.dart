import 'package:adhan_dart/adhan_dart.dart';
import 'package:hasanat/core/logging/talker_provider.dart';
import 'package:hasanat/core/theme/theme.dart';
import 'package:hasanat/feature/settings/data/models/prayer_settings_model.dart';
import 'package:hasanat/feature/settings/service/settings_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:timezone/timezone.dart';

part 'settings_provider.g.dart';

const String _localeNotifierLogPrefix = '[LocaleNotifier]';
const String _prayerSettingsNotifierLogPrefix = '[PrayerSettingsNotifier]';
const String _themeNotifierLogPrefix = '[ThemeNotifier]';

@riverpod
class LocaleNotifier extends _$LocaleNotifier {
  @override
  FutureOr<Locale> build() {
    final talker = ref.read(talkerNotifierProvider);
    talker.info('$_localeNotifierLogPrefix Building Locale...');
    final services = ref.read(settingsServiceProvider);
    final locale = services.getLocale();
    talker.info('$_localeNotifierLogPrefix Locale loaded: $locale');
    return locale;
  }

  bool isArabic() {
    return state.valueOrNull?.languageCode == 'ar';
  }

  void setLocale(Locale newLocale) {
    if (newLocale == state.valueOrNull || state.value == null) return;
    final talker = ref.read(talkerNotifierProvider);
    talker.info('$_localeNotifierLogPrefix Setting locale to: $newLocale');
    final service = ref.read(settingsServiceProvider);
    service.setLocale(newLocale);
    state = AsyncData(newLocale);
    talker.info('$_localeNotifierLogPrefix Locale set to: $newLocale');
  }

  void toggleLocale() {
    if (state.valueOrNull == null) return;
    final talker = ref.read(talkerNotifierProvider);
    talker.info('$_localeNotifierLogPrefix Toggling locale...');
    final currentLocale = state.value!;
    final newLocale = currentLocale.languageCode == 'ar'
        ? const Locale('en')
        : const Locale('ar');
    setLocale(newLocale);
  }
}

@riverpod
class PrayerSettingsNotifier extends _$PrayerSettingsNotifier {
  @override
  FutureOr<PrayerSettings> build() {
    final talker = ref.read(talkerNotifierProvider);
    talker.info('$_prayerSettingsNotifierLogPrefix Building PrayerSettings...');
    final services = ref.read(settingsServiceProvider);
    final prayerSettings = services.getPrayerSettings();
    talker.info(
        '$_prayerSettingsNotifierLogPrefix PrayerSettings loaded: $prayerSettings');
    return prayerSettings;
  }

  void setCoordinates(Coordinates coordinates) {
    if (state.valueOrNull == null) return;
    final talker = ref.read(talkerNotifierProvider);
    talker.info(
        '$_prayerSettingsNotifierLogPrefix Setting coordinates to: $coordinates');
    final service = ref.read(settingsServiceProvider);
    final newSettings = state.value!.copyWith(coordinates: coordinates);
    if (state.value == newSettings) {
      talker.warning(
          '$_prayerSettingsNotifierLogPrefix Coordinates are the same, not updating.');
      return;
    }
    service.setPrayerSettings(newSettings);
    state = AsyncData(newSettings);
    talker.info(
        '$_prayerSettingsNotifierLogPrefix Coordinates set to: $coordinates');
  }

  void setIqamahTimes(Map<Prayer, int> iqamahTimes) {
    if (state.valueOrNull == null) return;
    final talker = ref.read(talkerNotifierProvider);
    talker.info(
        '$_prayerSettingsNotifierLogPrefix Setting Iqamah times to: $iqamahTimes');
    final service = ref.read(settingsServiceProvider);
    final newSettings = state.value!.copyWith(iqamahSettings: iqamahTimes);
    if (state.value == newSettings) {
      talker.warning(
          '$_prayerSettingsNotifierLogPrefix Iqamah times are the same, not updating.');
      return;
    }
    service.setPrayerSettings(newSettings);
    state = AsyncData(newSettings);
    talker.info(
        '$_prayerSettingsNotifierLogPrefix Iqamah times set to: $iqamahTimes');
  }

  void setLocation(Location location) {
    if (state.valueOrNull == null) return;
    final talker = ref.read(talkerNotifierProvider);
    talker.info(
        '$_prayerSettingsNotifierLogPrefix Setting location to: $location');
    final service = ref.read(settingsServiceProvider);
    final newSettings = state.value!.copyWith(location: location);
    if (state.value == newSettings) {
      talker.warning(
          '$_prayerSettingsNotifierLogPrefix Location is the same, not updating.');
      return;
    }
    service.setPrayerSettings(newSettings);
    state = AsyncData(newSettings);
    talker.info('$_prayerSettingsNotifierLogPrefix Location set to: $location');
  }

  void setPrayerSettings(PrayerSettings settings) {
    if (state.valueOrNull == null) return;
    final talker = ref.read(talkerNotifierProvider);
    talker.info(
        '$_prayerSettingsNotifierLogPrefix Setting prayer settings to: $settings');
    if (state.value == settings) {
      talker.warning(
          '$_prayerSettingsNotifierLogPrefix Prayer settings are the same, not updating.');
      return;
    }
    final service = ref.read(settingsServiceProvider);
    service.setPrayerSettings(settings);
    state = AsyncData(settings);
    talker.info(
        '$_prayerSettingsNotifierLogPrefix Prayer settings set to: $settings');
  }

  @override
  Future<PrayerSettings> update(
      FutureOr<PrayerSettings> Function(PrayerSettings p1) cb,
      {FutureOr<PrayerSettings> Function(Object err, StackTrace stackTrace)?
          onError}) {
    final talker = ref.read(talkerNotifierProvider);
    talker
        .info('$_prayerSettingsNotifierLogPrefix Updating prayer settings...');
    return super.update(cb, onError: (err, stackTrace) {
      talker.handle(err, stackTrace,
          '$_prayerSettingsNotifierLogPrefix Error updating prayer settings');
      if (onError != null) {
        return onError(err, stackTrace);
      }
      // Re-throw the error if no custom onError is provided to maintain original behavior
      throw err;
    }).then((value) {
      talker.info(
          '$_prayerSettingsNotifierLogPrefix Prayer settings updated successfully: $value');
      return value;
    });
  }
}

@riverpod
class ThemeNotifier extends _$ThemeNotifier {
  @override
  FutureOr<ThemeSettings> build() async {
    final talker = ref.read(talkerNotifierProvider);
    talker.info('$_themeNotifierLogPrefix Building ThemeSettings...');
    final services = ref.read(settingsServiceProvider);
    final appPalette = await services.getAppPalette();
    final themeMode = await services.getThemeMode();
    final settings = ThemeSettings(
        appPalette: appPalette,
        themeMode: themeMode,
        colorScheme: resolveColorScheme(appPalette, themeMode));
    talker.info('$_themeNotifierLogPrefix ThemeSettings loaded: $settings');
    return settings;
  }

  void setPalette(AppPalette newPalette) {
    if (newPalette == state.valueOrNull?.appPalette || state.value == null) {
      return;
    }
    final talker = ref.read(talkerNotifierProvider);
    talker.info('$_themeNotifierLogPrefix Setting palette to: $newPalette');

    final service = ref.read(settingsServiceProvider);
    service.setAppPalette(newPalette);
    final newColorScheme =
        resolveColorScheme(newPalette, state.valueOrNull!.themeMode);
    state = AsyncData(state.value!.copyWith(
      appPalette: newPalette,
      colorScheme: newColorScheme,
    ));
    talker.info('$_themeNotifierLogPrefix Palette set to: $newPalette');
  }

  void setThemeMode(ThemeMode newThemeMode) {
    if (newThemeMode == state.valueOrNull?.themeMode || state.value == null) {
      return;
    }
    final talker = ref.read(talkerNotifierProvider);
    talker
        .info('$_themeNotifierLogPrefix Setting theme mode to: $newThemeMode');

    final newColorScheme =
        resolveColorScheme(state.value!.appPalette, newThemeMode);

    final service = ref.read(settingsServiceProvider);
    service.setThemeMode(newThemeMode);
    state = AsyncData(state.value!.copyWith(
      themeMode: newThemeMode,
      colorScheme: newColorScheme,
    ));
    talker.info('$_themeNotifierLogPrefix Theme mode set to: $newThemeMode');
  }

  void toggleThemeMode() {
    final talker = ref.read(talkerNotifierProvider);
    talker.info('$_themeNotifierLogPrefix Toggling theme mode...');
    final newThemeMode = state.valueOrNull?.themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    setThemeMode(newThemeMode);
  }
}
