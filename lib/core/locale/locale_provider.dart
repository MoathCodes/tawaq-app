import 'package:flutter/material.dart';
import 'package:riverpod_annotation/experimental/json_persist.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/feature/settings/data/repository/settings_storage.dart';

part 'locale_provider.g.dart';

const String _localeLogPrefix = '[LocaleNotifier]';

/// Notifier for the application locale.
///
/// Persisted as a plain language-code string via [persist].
@riverpod
@JsonPersist()
class LocaleNotifier extends _$LocaleNotifier {
  @override
  String build() {
    ref.read(loggerProvider).i('$_localeLogPrefix Building...');
    persist(
      ref.read(settingsStorageProvider),
      options: const StorageOptions(
        cacheTime: StorageCacheTime.unsafe_forever,
      ),
    );
    return 'en';
  }

  @override
  String get key => 'locale';

  /// Returns true if the current locale is Arabic.
  bool isArabic() => state == 'ar';

  /// Sets the application locale.
  void setLocale(Locale newLocale) {
    if (newLocale.languageCode == state) return;
    ref.read(loggerProvider).i('$_localeLogPrefix Setting to: $newLocale');
    state = newLocale.languageCode;
  }

  /// Toggles the application locale between English and Arabic.
  void toggleLocale() {
    setLocale(
      state == 'ar' ? const Locale('en') : const Locale('ar'),
    );
  }
}
