import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:riverpod_annotation/experimental/json_persist.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/core/settings/side_panel_settings_mixin.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_filters.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_screen_state.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_screen_state.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_analytics.dart';
import 'package:tawaq/feature/quran/domain/models/quran_layouts.dart';
import 'package:tawaq/feature/quran/domain/models/quran_screen_state.dart';
import 'package:tawaq/feature/quran/domain/models/quran_text_scale.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_mode.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_settings.dart';
import 'package:tawaq/feature/quran/domain/models/tafsir_source.dart';
import 'package:tawaq/feature/quran/domain/models/translation_source.dart';
import 'package:tawaq/feature/settings/data/migration/state_settings_legacy_migration.dart';
import 'package:tawaq/feature/settings/data/models/state_settings.dart';
import 'package:tawaq/feature/settings/data/repository/settings_storage.dart';
import 'package:tawaq/feature/settings/domain/models/settings_screen_state.dart';
import 'package:tawaq/feature/settings/presentation/models/settings_destination.dart';

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
class QuranScreenSettingsNotifier extends _$QuranScreenSettingsNotifier
    with SidePanelSettingsMixin<QuranScreenState> {
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

  /// Persists only navigation-critical page fields after debounced reading.
  void commitSlimPageInfo(MushafPageInfo info) => _update((s) {
    final current = s.pageInfo;
    if (current.pageNumber == info.pageNumber &&
        current.juzNumber == info.juzNumber &&
        current.primarySurahNumber == info.primarySurahNumber &&
        current.firstAyahId == info.firstAyahId) {
      return s;
    }
    return s.copyWith(pageInfo: info);
  }, 'Slim Quran page');

  /// Sets the reading layout.
  void setLayout(QuranReadingLayout layout) =>
      _update((s) => s.copyWith(layout: layout), 'Layout');

  /// Sets the mushaf text scale (independent of app UI scale).
  void setTextScale(QuranTextScale scale) =>
      _update((s) => s.copyWith(quranTextScale: scale), 'Quran text scale');

  /// Sets the selected ayah.
  void selectAyah(Ayah? ayah) =>
      _update((s) => s.copyWith(selectedAyah: ayah), 'Selected ayah');

  @override
  void updateSidePanelSetting(
    QuranScreenState Function(QuranScreenState) transform,
    String logField,
  ) => _update(transform, logField);

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

/// Persisted Quran recitation preferences.
@riverpod
@JsonPersist()
class RecitationSettingsNotifier extends _$RecitationSettingsNotifier {
  double? _volumePreview;

  /// Ephemeral volume while dragging a slider (not persisted).
  double? get volumePreview => _volumePreview;

  @override
  Future<RecitationSettings> build() async {
    await ref.watch(stateSettingsLegacyMigrationProvider.future);
    await persist(
      ref.read(settingsStorageProvider),
      options: const StorageOptions(
        cacheTime: StorageCacheTime.unsafe_forever,
      ),
    ).future;
    return state.value ?? RecitationSettings.initial();
  }

  void _update(
    RecitationSettings Function(RecitationSettings) fn,
    String field,
  ) {
    if (!state.hasValue) return;
    final current = state.value!;
    final next = fn(current);
    if (current == next) return;
    state = AsyncData(next);
    _logUiStateUpdate(ref, 'RecitationSettingsNotifier', field);
  }

  /// Persists the selected reciter and moshaf.
  void setReciter({required int reciterId, int? moshafId}) => _update(
    (s) => s.copyWith(reciterId: reciterId, moshafId: moshafId),
    'Reciter',
  );

  /// Persists the end-of-selection mode.
  void setMode(RecitationMode mode) =>
      _update((s) => s.copyWith(mode: mode), 'Mode');

  /// Persists the output volume (0-100).
  void setVolume(double volume) {
    _volumePreview = null;
    _update((s) => s.copyWith(volume: volume), 'Volume');
  }

  /// Updates volume in memory during slider drag without persisting.
  void setVolumePreview(double volume) {
    if (!state.hasValue) return;
    _volumePreview = volume.clamp(0, 100);
  }

  /// Persists the final volume after the user releases the slider.
  void commitVolume(double volume) => setVolume(volume);

  /// Persists whether the played ayah is highlighted in the mushaf.
  void setHighlightAyah({required bool value}) =>
      _update((s) => s.copyWith(highlightAyah: value), 'Highlight ayah');

  /// Persists whether the page follows the played ayah.
  void setAutoScroll({required bool value}) =>
      _update((s) => s.copyWith(autoScroll: value), 'Auto scroll');

  /// Persists how many times the selection repeats (clamped 1-99).
  void setRepeatCount(int count) => _update(
    (s) => s.copyWith(repeatCount: count.clamp(1, 99)),
    'Repeat count',
  );
}

/// Persisted Hadith screen UI state.
@riverpod
@JsonPersist()
class HadithScreenSettingsNotifier extends _$HadithScreenSettingsNotifier
    with SidePanelSettingsMixin<HadithScreenState> {
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

  @override
  void updateSidePanelSetting(
    HadithScreenState Function(HadithScreenState) transform,
    String logField,
  ) => _update(transform, logField);
}

/// Persisted Muslim Fortress screen UI state.
@riverpod
@JsonPersist()
class FortressScreenSettingsNotifier extends _$FortressScreenSettingsNotifier
    with SidePanelSettingsMixin<FortressScreenState> {
  @override
  Future<FortressScreenState> build() async {
    await ref.watch(stateSettingsLegacyMigrationProvider.future);
    await persist(
      ref.read(settingsStorageProvider),
      options: const StorageOptions(
        cacheTime: StorageCacheTime.unsafe_forever,
      ),
    ).future;
    return state.value ?? FortressScreenState.initial();
  }

  void _update(
    FortressScreenState Function(FortressScreenState) fn,
    String field,
  ) {
    if (!state.hasValue) return;
    final current = state.value!;
    final next = fn(current);
    if (current == next) return;
    state = AsyncData(next);
    _logUiStateUpdate(ref, 'FortressScreenSettingsNotifier', field);
  }

  /// Sets the fortress sidebar tab.
  void setSidebarTab(FortressSidebarTab tab) =>
      _update((s) => s.copyWith(sidebarTab: tab), 'Fortress sidebar tab');

  /// Toggles a chapter in the favorites list (most recent first).
  void toggleFavorite(int chapterId) => _update((s) {
    final ids = List<int>.from(s.favoriteChapterIds);
    if (ids.contains(chapterId)) {
      ids.remove(chapterId);
    } else {
      ids.insert(0, chapterId);
    }
    return s.copyWith(favoriteChapterIds: ids);
  }, 'Fortress favorite chapter');

  /// Seeds default bookmarks once for new users.
  void ensureDefaultBookmarks(List<int> defaultIds) => _update((s) {
    if (s.defaultBookmarksSeeded) return s;
    return s.copyWith(
      favoriteChapterIds: defaultIds,
      defaultBookmarksSeeded: true,
    );
  }, 'Fortress default bookmarks');

  @override
  void updateSidePanelSetting(
    FortressScreenState Function(FortressScreenState) transform,
    String logField,
  ) => _update(transform, logField);
}

/// Persisted settings screen tab selection.
@riverpod
@JsonPersist()
class SettingsScreenSettingsNotifier extends _$SettingsScreenSettingsNotifier {
  @override
  Future<SettingsScreenState> build() async {
    await ref.watch(stateSettingsLegacyMigrationProvider.future);
    await persist(
      ref.read(settingsStorageProvider),
      options: const StorageOptions(
        cacheTime: StorageCacheTime.unsafe_forever,
      ),
    ).future;
    return state.value ?? SettingsScreenState.initial();
  }

  void _update(
    SettingsScreenState Function(SettingsScreenState) fn,
    String field,
  ) {
    if (!state.hasValue) return;
    final current = state.value!;
    final next = fn(current);
    if (current == next) return;
    state = AsyncData(next);
    _logUiStateUpdate(ref, 'SettingsScreenSettingsNotifier', field);
  }

  /// Sets the active settings tab.
  void setActiveDestination(SettingsDestination destination) => _update(
    (s) => s.copyWith(activeTabKey: destination.labelKey),
    'Settings tab',
  );
}
