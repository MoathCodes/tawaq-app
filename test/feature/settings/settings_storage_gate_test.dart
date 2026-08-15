import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:tawaq/core/bootstrap/app_init_providers.dart';
import 'package:tawaq/core/locale/locale_provider.dart';
import 'package:tawaq/core/storage/settings_storage.dart';
import 'package:tawaq/feature/settings/presentation/provider/theme_settings_provider.dart';

void main() {
  group('settingsStorage gate', () {
    test(
      'locale hydrate awaits storage decode (not sync default race)',
      () async {
        final storage = Storage<String, String>.inMemory();
        await storage.write(
          'locale',
          '"ar"',
          const StorageOptions(cacheTime: StorageCacheTime.unsafe_forever),
        );

        final container = ProviderContainer(
          overrides: [
            hiveCoreInitProvider.overrideWith((ref) async {}),
            settingsStorageProvider.overrideWith((ref) async => storage),
          ],
        );
        addTearDown(container.dispose);

        final locale = await container.read(localeProvider.future);
        expect(locale, 'ar');
      },
    );

    test('theme hydrate awaits storage decode', () async {
      final storage = Storage<String, String>.inMemory();
      await storage.write(
        'ThemeNotifier',
        '{"appPalette":"blue","themeMode":"dark","appTextScale":"normal"}',
        const StorageOptions(cacheTime: StorageCacheTime.unsafe_forever),
      );

      final container = ProviderContainer(
        overrides: [
          hiveCoreInitProvider.overrideWith((ref) async {}),
          settingsStorageProvider.overrideWith((ref) async => storage),
        ],
      );
      addTearDown(container.dispose);

      final prefs = await container.read(themeProvider.future);
      expect(prefs.themeMode.name, 'dark');
      // Legacy "blue" (removed in forui 0.24) migrates to manuscript.
      expect(prefs.appPalette.name, 'manuscript');
    });

    test('settingsStorage waits on hiveCoreInit before create', () async {
      var hiveReady = false;
      final container = ProviderContainer(
        overrides: [
          hiveCoreInitProvider.overrideWith((ref) async {
            await Future<void>.delayed(Duration.zero);
            hiveReady = true;
          }),
          settingsStorageProvider.overrideWith((ref) async {
            await ref.watch(hiveCoreInitProvider.future);
            expect(hiveReady, isTrue);
            return Storage<String, String>.inMemory();
          }),
        ],
      );
      addTearDown(container.dispose);

      await container.read(settingsStorageProvider.future);
      expect(hiveReady, isTrue);
    });
  });
}
