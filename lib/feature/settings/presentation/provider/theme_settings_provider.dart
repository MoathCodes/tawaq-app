import 'package:flutter/material.dart';
import 'package:riverpod_annotation/experimental/json_persist.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/feature/settings/data/models/app_text_scale.dart';
import 'package:tawaq/feature/settings/data/models/theme_prefs.dart';
import 'package:tawaq/feature/settings/data/repository/settings_storage.dart';
import 'package:tawaq/theme/theme_model.dart';

part 'theme_settings_provider.g.dart';

const String _themeLogPrefix = '[ThemeNotifier]';

ThemePrefs _lastGoodThemePrefs = ThemePrefs.defaults();

/// Notifier for theme settings.
///
/// Persisted [ThemePrefs] (palette + mode) via [JsonPersist].
@riverpod
@JsonPersist()
class ThemeNotifier extends _$ThemeNotifier {
  @override
  Future<ThemePrefs> build() async {
    ref.read(loggerProvider).i('$_themeLogPrefix Building...');
    listenSelf((_, next) {
      final value = next.value;
      if (value != null) _lastGoodThemePrefs = value;
    });
    try {
      await persist(
        ref.read(settingsStorageProvider),
        options: const StorageOptions(
          cacheTime: StorageCacheTime.unsafe_forever,
        ),
      ).future;
    } on Object catch (error, stack) {
      ref.read(loggerProvider).e(
        '$_themeLogPrefix hydrate failed; keeping last-good prefs',
        error: error,
        stackTrace: stack,
      );
    }
    return state.value ?? _lastGoodThemePrefs;
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

  /// Sets the app-wide UI text scale.
  void setAppTextScale(AppTextScale scale) {
    final prefs = state.value;
    if (prefs == null || scale == prefs.appTextScale) return;
    state = AsyncData(prefs.copyWith(appTextScale: scale));
  }

  /// Toggles the theme mode between light and dark.
  void toggleThemeMode() => setThemeMode(
    state.value?.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
  );
}

/// App-wide text scale multiplier from persisted theme prefs.
@riverpod
double appTextScaleFactor(Ref ref) {
  final prefs = ref.watch(themeProvider).value ?? ThemePrefs.defaults();
  return prefs.appTextScale.scalar;
}
