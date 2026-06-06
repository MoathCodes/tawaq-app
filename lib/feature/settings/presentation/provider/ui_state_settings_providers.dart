import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:riverpod_annotation/experimental/json_persist.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_filters.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_screen_state.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_analytics.dart';
import 'package:tawaq/feature/quran/domain/models/quran_layouts.dart';
import 'package:tawaq/feature/quran/domain/models/quran_screen_state.dart';
import 'package:tawaq/feature/quran/domain/models/quran_text_scale.dart';
import 'package:tawaq/feature/quran/domain/models/tafsir_source.dart';
import 'package:tawaq/feature/quran/domain/models/translation_source.dart';
import 'package:tawaq/feature/settings/data/migration/state_settings_legacy_migration.dart';
import 'package:tawaq/feature/settings/data/models/state_settings.dart';
import 'package:tawaq/feature/settings/data/repository/settings_storage.dart';

part 'ui_state_settings_providers.g.dart';

void _logUiStateUpdate(
  Ref ref,
  String notifier,
  String field,
) {
  ref.read(loggerProvider).i('[$notifier] $field updated');
}

/// Persisted sidebar collapsed state.
@riverpod
@JsonPersist()
class SidebarSettingsNotifier extends _$SidebarSettingsNotifier {
  @override
  Future<bool> build() async {
    await ref.watch(stateSettingsLegacyMigrationProvider.future);
    await persist(
      ref.read(settingsStorageProvider),
      options: const StorageOptions(
        cacheTime: StorageCacheTime.unsafe_forever,
      ),
    ).future;
    return state.value ?? false;
  }

  /// Sets the sidebar collapsed state.
  void setCollapsed({required bool collapsed}) {
    if (!state.hasValue || state.value == collapsed) return;
    state = AsyncData(collapsed);
    _logUiStateUpdate(ref, 'SidebarSettingsNotifier', 'Sidebar');
  }
}

/// Persisted prayer analytics period selection.
@riverpod
@JsonPersist()
class PrayerAnalyticsSettingsNotifier extends _$PrayerAnalyticsSettingsNotifier {
  @override
  Future<PrayerAnalyticsPrefs> build() async {
    await ref.watch(stateSettingsLegacyMigrationProvider.future);
    await persist(
      ref.read(settingsStorageProvider),
      options: const StorageOptions(
        cacheTime: StorageCacheTime.unsafe_forever,
      ),
    ).future;
    return state.value ?? PrayerAnalyticsPrefs.defaults();
  }

  /// Sets the prayer analytics period.
  void setPeriod(PrayerAnalyticsPeriod period) {
    final current = state.value ?? PrayerAnalyticsPrefs.defaults();
    if (current.period == period) return;
    state = AsyncData(current.copyWith(period: period));
    _logUiStateUpdate(ref, 'PrayerAnalyticsSettingsNotifier', 'Period');
  }
}

/// Persisted Quran screen UI state.
@riverpod
@JsonPersist()
class QuranScreenSettingsNotifier extends _$QuranScreenSettingsNotifier {
  @override
  Future<QuranScreenState> build() async {
    await ref.watch(stateSettingsLegacyMigrationProvider.future);
    await persist(
      ref.read(settingsStorageProvider),
      options: const StorageOptions(
        cacheTime: StorageCacheTime.unsafe_forever,
      ),
    ).future;
    return state.value ?? QuranScreenState.initial();
  }

  void _update(
    QuranScreenState Function(QuranScreenState) fn,
    String field,
  ) {
    if (!state.hasValue) return;
    final current = state.value!;
    final next = fn(current);
    if (current == next) return;
    state = AsyncData(next);
    _logUiStateUpdate(ref, 'QuranScreenSettingsNotifier', field);
  }

  /// Sets the last Quran page info.
  void setLastPageInfo(MushafPageInfo info) =>
      _update((s) => s.copyWith(pageInfo: info), 'Last Quran page');

  /// Sets the reading layout.
  void setLayout(QuranReadingLayout layout) =>
      _update((s) => s.copyWith(layout: layout), 'Layout');

  /// Sets the mushaf text scale (independent of app UI scale).
  void setTextScale(QuranTextScale scale) =>
      _update((s) => s.copyWith(quranTextScale: scale), 'Quran text scale');

  /// Sets the selected ayah.
  void selectAyah(Ayah? ayah) =>
      _update((s) => s.copyWith(selectedAyah: ayah), 'Selected ayah');

  /// Sets the Quran side panel width.
  void setSidePanelWidth(double width) =>
      _update((s) => s.copyWith(sidePanelWidth: width), 'Quran side panel width');

  /// Sets the tafsir accordion expanded state.
  void setTafsirEnabled({required bool enabled}) =>
      _update((s) => s.copyWith(tafsirEnabled: enabled), 'Tafsir enabled');

  /// Sets the translation accordion expanded state.
  void setTranslationEnabled({required bool enabled}) => _update(
    (s) => s.copyWith(translationEnabled: enabled),
    'Translation enabled',
  );

  /// Sets the selected translation source.
  void setSelectedTranslation(TranslationId source) => _update(
    (s) => s.copyWith(selectedTranslation: source),
    'Translation source',
  );

  /// Sets the selected tafsir source.
  void setSelectedTafsir(TafsirId source) => _update(
    (s) => s.copyWith(selectedTafsir: source),
    'Tafsir source',
  );
}

/// Persisted Hadith screen UI state.
@riverpod
@JsonPersist()
class HadithScreenSettingsNotifier extends _$HadithScreenSettingsNotifier {
  @override
  Future<HadithScreenState> build() async {
    await ref.watch(stateSettingsLegacyMigrationProvider.future);
    await persist(
      ref.read(settingsStorageProvider),
      options: const StorageOptions(
        cacheTime: StorageCacheTime.unsafe_forever,
      ),
    ).future;
    return state.value ?? HadithScreenState.initial();
  }

  void _update(
    HadithScreenState Function(HadithScreenState) fn,
    String field,
  ) {
    if (!state.hasValue) return;
    final current = state.value!;
    final next = fn(current);
    if (current == next) return;
    state = AsyncData(next);
    _logUiStateUpdate(ref, 'HadithScreenSettingsNotifier', field);
  }

  /// Sets the hadith active panel tab.
  void setActiveTab(HadithPanelTab tab) =>
      _update((s) => s.copyWith(activeTab: tab), 'Hadith tab');

  /// Sets the hadith filters.
  void setFilters(HadithFilters filters) =>
      _update((s) => s.copyWith(filters: filters), 'Hadith filters');

  /// Sets the hadith side panel width.
  void setSidePanelWidth(double width) =>
      _update((s) => s.copyWith(sidePanelWidth: width), 'Hadith side panel width');
}
