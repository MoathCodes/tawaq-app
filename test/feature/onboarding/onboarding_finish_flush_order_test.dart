import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:tawaq/core/bootstrap/app_init_providers.dart';
import 'package:tawaq/core/locale/locale_provider.dart';
import 'package:tawaq/core/storage/settings_storage.dart';
import 'package:tawaq/feature/onboarding/presentation/providers/onboarding_state_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/provider/theme_settings_provider.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Records write order while delegating to an in-memory store.
final class _RecordingStorage extends Storage<String, String> {
  new();

  final Storage<String, String> _inner = Storage.inMemory();
  final List<String> writeKeys = [];

  @override
  FutureOr<PersistedData<String>?> read(String key) => _inner.read(key);

  @override
  FutureOr<void> write(String key, String value, StorageOptions options) async {
    writeKeys.add(key);
    await _inner.write(key, value, options);
  }

  @override
  FutureOr<void> delete(String key) => _inner.delete(key);

  @override
  void deleteOutOfDate() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(tzdata.initializeTimeZones);

  group('onboarding finish flush order', () {
    test('flushes prayer then theme then locale then completed', () async {
      final storage = _RecordingStorage();
      final container = ProviderContainer(
        overrides: [
          hiveCoreInitProvider.overrideWith((ref) async {}),
          settingsStorageProvider.overrideWith((ref) async => storage),
        ],
      );
      addTearDown(container.dispose);

      await container.read(prayerSettingsProvider.future);
      await container.read(themeProvider.future);
      await container.read(localeProvider.future);
      await container.read(onboardingStateProvider.future);

      // Keep autoDispose theme/locale alive across mutations + finish flush.
      final keepAlive = [
        container.listen(prayerSettingsProvider, (_, _) {}),
        container.listen(themeProvider, (_, _) {}),
        container.listen(localeProvider, (_, _) {}),
        container.listen(onboardingStateProvider, (_, _) {}),
      ];
      addTearDown(() {
        for (final sub in keepAlive) {
          sub.close();
        }
      });

      // Mutate prefs during onboarding.
      await container
          .read(prayerSettingsProvider.notifier)
          .applyLocationBundle(
            coordinates: Coordinates(21.4225, 39.8262),
            locationName: 'Makkah',
            location: tz.getLocation('Asia/Riyadh'),
          );
      container.read(themeProvider.notifier).toggleThemeMode();
      container.read(localeProvider.notifier).setLocale(const Locale('ar'));

      // Let JsonPersist background writes settle before measuring finish order.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      storage.writeKeys.clear();

      final finished = await container
          .read(onboardingStateProvider.notifier)
          .finish();
      expect(finished, isTrue);

      expect(storage.writeKeys, contains('PrayerSettingsNotifier'));
      expect(storage.writeKeys, contains('ThemeNotifier'));
      expect(storage.writeKeys, contains('locale'));
      expect(storage.writeKeys, contains('OnboardingStateNotifier'));

      final prayerIdx = storage.writeKeys.indexOf('PrayerSettingsNotifier');
      final themeIdx = storage.writeKeys.indexOf('ThemeNotifier');
      final localeIdx = storage.writeKeys.indexOf('locale');
      final onboardingIdx = storage.writeKeys.indexOf(
        'OnboardingStateNotifier',
      );

      expect(prayerIdx, lessThan(themeIdx));
      expect(themeIdx, lessThan(localeIdx));
      expect(localeIdx, lessThan(onboardingIdx));

      final onboardingDisk = await storage.read('OnboardingStateNotifier');
      expect(onboardingDisk?.data, contains('"completed":true'));

      final prayerDisk = await storage.read('PrayerSettingsNotifier');
      expect(prayerDisk?.data, contains('Makkah'));

      final localeDisk = await storage.read('locale');
      expect(localeDisk?.data, contains('ar'));
    });
  });
}
