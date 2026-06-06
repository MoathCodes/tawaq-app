import 'dart:convert';

import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/feature/settings/data/models/state_settings.dart';
import 'package:tawaq/feature/settings/data/repository/settings_storage.dart';

part 'state_settings_legacy_migration.g.dart';

const _legacyStateSettingsKey = 'StateSettingsNotifier';
const _migrationDoneKey = 'StateSettingsMigration_v1';

const _sidebarSettingsKey = 'SidebarSettingsNotifier';
const _prayerAnalyticsSettingsKey = 'PrayerAnalyticsSettingsNotifier';
const _quranScreenSettingsKey = 'QuranScreenSettingsNotifier';
const _hadithScreenSettingsKey = 'HadithScreenSettingsNotifier';

const _persistOptions = StorageOptions(
  cacheTime: StorageCacheTime.unsafe_forever,
);

/// Migrates the legacy monolithic [StateSettings] blob into feature-scoped keys.
@Riverpod(keepAlive: true)
Future<void> stateSettingsLegacyMigration(Ref ref) async {
  final storage = ref.read(settingsStorageProvider);

  final migrationDone = await storage.read(_migrationDoneKey);
  if (migrationDone != null) return;

  final legacy = await storage.read(_legacyStateSettingsKey);
  if (legacy != null) {
    try {
      final decoded = jsonDecode(legacy.data);
      final settings = StateSettings.fromJson(
        Map<String, dynamic>.from(decoded as Map),
      );

      await storage.write(
        _sidebarSettingsKey,
        jsonEncode(settings.sidebarCollapsed),
        _persistOptions,
      );
      await storage.write(
        _prayerAnalyticsSettingsKey,
        jsonEncode(
          PrayerAnalyticsPrefs(period: settings.prayerAnalyticsPeriod).toJson(),
        ),
        _persistOptions,
      );
      await storage.write(
        _quranScreenSettingsKey,
        jsonEncode(settings.quranState.toJson()),
        _persistOptions,
      );
      await storage.write(
        _hadithScreenSettingsKey,
        jsonEncode(settings.hadithState.toJson()),
        _persistOptions,
      );
      await storage.delete(_legacyStateSettingsKey);
    } catch (_) {
      // Corrupt legacy entry — fall through and mark migration done.
    }
  }

  await storage.write(
    _migrationDoneKey,
    jsonEncode(true),
    _persistOptions,
  );
}
