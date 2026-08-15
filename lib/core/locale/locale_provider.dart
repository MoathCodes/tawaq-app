import 'package:flutter/material.dart';
import 'package:riverpod_annotation/experimental/json_persist.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/core/storage/settings_storage.dart';

part 'locale_provider.g.dart';

const String _localeLogPrefix = '[LocaleNotifier]';

/// Notifier for the application locale.
///
/// Persisted as a plain language-code string via [persist].
@riverpod
@JsonPersist()
class LocaleNotifier extends _$LocaleNotifier {
  @override
  Future<String> build() async {
    ref.read(loggerProvider).i('$_localeLogPrefix Building...');
    try {
      await persist(
        ref.watch(settingsStorageProvider.future),
        options: kSettingsPersistForever,
      ).future;
    } on Object catch (error, stack) {
      ref
          .read(loggerProvider)
          .e(
            '$_localeLogPrefix hydrate failed; using default locale',
            error: error,
            stackTrace: stack,
          );
    }
    return state.value ?? 'en';
  }

  @override
  String get key => 'locale';

  /// Awaits a durable disk write of the current locale (kill-boundary safe).
  Future<void> flush() async {
    final value = state.value;
    if (value == null) return;
    final storage = await ref.read(settingsStorageProvider.future);
    if (!ref.mounted) return;
    await flushPersistedValue(storage, key, value);
  }

  /// Returns true if the current locale is Arabic.
  bool isArabic() => state.value == 'ar';

  /// Sets the application locale.
  void setLocale(Locale newLocale) {
    if (!state.hasValue) return;
    if (newLocale.languageCode == state.value) return;
    ref.read(loggerProvider).i('$_localeLogPrefix Setting to: $newLocale');
    state = AsyncData(newLocale.languageCode);
  }

  /// Toggles the application locale between English and Arabic.
  void toggleLocale() {
    setLocale(
      state.value == 'ar' ? const Locale('en') : const Locale('ar'),
    );
  }
}
