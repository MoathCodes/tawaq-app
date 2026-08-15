import 'package:flutter/material.dart';
import 'package:riverpod_annotation/experimental/json_persist.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/core/storage/settings_storage.dart';
import 'package:tawaq/feature/settings/data/models/app_text_scale.dart';
import 'package:tawaq/feature/settings/data/models/theme_prefs.dart';
import 'package:tawaq/theme/theme_model.dart';

part 'theme_settings_provider.g.dart';

const String _themeLogPrefix = '[ThemeNotifier]';

/// Notifier for theme settings.
///
/// Persisted [ThemePrefs] (palette + mode) via [JsonPersist].
@riverpod
@JsonPersist()
class ThemeNotifier extends _$ThemeNotifier {
  @override
  Future<ThemePrefs> build() async {
    ref.read(loggerProvider).i('$_themeLogPrefix Building...');
    try {
      await persist(
        ref.watch(settingsStorageProvider.future),
        options: kSettingsPersistForever,
      ).future;
    } on Object catch (error, stack) {
      ref
          .read(loggerProvider)
          .e(
            '$_themeLogPrefix hydrate failed; using current/default prefs',
            error: error,
            stackTrace: stack,
          );
    }
    return state.value ?? ThemePrefs.defaults();
  }

  /// Awaits a durable disk write of the current prefs (kill-boundary safe).
  Future<void> flush() async {
    final value = state.value;
    if (value == null) return;
    final storage = await ref.read(settingsStorageProvider.future);
    if (!ref.mounted) return;
    await flushPersistedValue(storage, key, value);
  }

  void _commit(ThemePrefs Function(ThemePrefs) fn, String field) {
    final prefs = state.value;
    if (prefs == null) return;
    final next = fn(prefs);
    if (next == prefs) return;
    state = AsyncData(next);
    ref.read(loggerProvider).i('$_themeLogPrefix $field updated');
  }

  /// Sets the application palette.
  void setPalette(AppPalette p) =>
      _commit((s) => s.copyWith(appPalette: p), 'Palette');

  /// Sets the theme mode.
  void setThemeMode(ThemeMode m) =>
      _commit((s) => s.copyWith(themeMode: m), 'Theme mode');

  /// Sets the app-wide UI text scale.
  void setAppTextScale(AppTextScale scale) =>
      _commit((s) => s.copyWith(appTextScale: scale), 'App text scale');

  /// Toggles the theme mode between light and dark.
  void toggleThemeMode() => setThemeMode(
    state.value?.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
  );
}
