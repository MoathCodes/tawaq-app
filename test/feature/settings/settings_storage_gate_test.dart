import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:tawaq/core/bootstrap/app_init_providers.dart';
import 'package:tawaq/core/locale/locale_provider.dart';
import 'package:tawaq/core/storage/settings_storage.dart';
import 'package:tawaq/feature/settings/data/models/theme_prefs.dart';
import 'package:tawaq/feature/settings/presentation/provider/theme_settings_provider.dart';
import 'package:tawaq/theme/theme_model.dart';

void main() {
  test(
    'Sage selection and mode restore after a flushed provider restart',
    () async {
      final storage = Storage<String, String>.inMemory();
      ProviderContainer create() => ProviderContainer(
        overrides: [
          hiveCoreInitProvider.overrideWith((ref) async {}),
          settingsStorageProvider.overrideWith((ref) async => storage),
        ],
      );
      final first = create();
      await first.read(themeProvider.future);
      first.read(themeProvider.notifier)
        ..setPalette(AppPalette.sage)
        ..setThemeMode(ThemeMode.dark);
      await first.read(themeProvider.notifier).flush();
      first.dispose();
      final restarted = create();
      addTearDown(restarted.dispose);
      final prefs = await restarted.read(themeProvider.future);
      expect(prefs.appPalette, AppPalette.sage);
      expect(prefs.themeMode, ThemeMode.dark);
    },
  );

  test('all saved palette names remain compatible', () {
    for (final palette in AppPalette.values) {
      for (final key in [palette.name, palette.key]) {
        final prefs = ThemePrefs.fromJson({
          'appPalette': key,
          'themeMode': 'light',
        });
        expect(prefs.appPalette, palette);
        expect(ThemePrefs.fromJson(prefs.toJson()).appPalette, palette);
      }
    }
    expect(appPaletteFromJson('unknown'), AppPalette.manuscript);
    expect(ThemePrefs.defaults().appPalette, AppPalette.manuscript);
  });

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
