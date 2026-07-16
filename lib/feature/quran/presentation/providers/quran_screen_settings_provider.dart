import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:riverpod_annotation/experimental/json_persist.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/feature/quran/domain/models/quran_screen_state.dart';
import 'package:tawaq/feature/quran/domain/models/quran_text_scale.dart';
import 'package:tawaq/feature/quran/domain/models/quran_ui_models.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_models.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_settings.dart';
import 'package:tawaq/feature/quran/domain/models/tafsir_source.dart';
import 'package:tawaq/feature/quran/domain/models/translation_source.dart';
import 'package:tawaq/feature/quran/domain/services/reciter_tags.dart';
import 'package:tawaq/feature/settings/data/repository/settings_storage.dart';

part 'quran_screen_settings_provider.g.dart';

const _quranLogPrefix = '[QuranScreenSettingsNotifier]';
const _recitationLogPrefix = '[RecitationSettingsNotifier]';

/// Persisted Quran screen UI state.
@riverpod
@JsonPersist()
class QuranScreenSettingsNotifier extends _$QuranScreenSettingsNotifier {
  @override
  Future<QuranScreenState> build() async {
    await persist(
      ref.read(settingsStorageProvider),
      options: const StorageOptions(
        cacheTime: StorageCacheTime.unsafe_forever,
      ),
    ).future;
    return state.value ?? QuranScreenState.initial();
  }

  void _commit(
    QuranScreenState Function(QuranScreenState) fn,
    String field,
  ) {
    if (!state.hasValue) return;
    final current = state.value!;
    final next = fn(current);
    if (current == next) return;
    state = AsyncData(next);
    ref.read(loggerProvider).i('$_quranLogPrefix $field updated');
  }

  /// Persists only navigation-critical page fields after debounced reading.
  void commitSlimPageInfo(MushafPageInfo info) => _commit((s) {
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
      _commit((s) => s.copyWith(layout: layout), 'Layout');

  /// Sets the mushaf text scale (independent of app UI scale).
  void setTextScale(QuranTextScale scale) =>
      _commit((s) => s.copyWith(quranTextScale: scale), 'Quran text scale');

  /// Sets the selected ayah.
  void selectAyah(Ayah? ayah) =>
      _commit((s) => s.copyWith(selectedAyah: ayah), 'Selected ayah');

  /// Sets the side panel width ratio (0..1).
  void setSidePanelRatio(double ratio) =>
      _commit((s) => s.copyWith(sidePanelRatio: ratio), 'Side panel ratio');

  /// Sets whether the side panel is collapsed.
  void setSidePanelCollapsed({required bool collapsed}) => _commit(
    (s) => s.copyWith(sidePanelCollapsed: collapsed),
    'Side panel collapsed',
  );

  /// Sets the tafsir accordion expanded state.
  void setTafsirEnabled({required bool enabled}) =>
      _commit((s) => s.copyWith(tafsirEnabled: enabled), 'Tafsir enabled');

  /// Sets the translation accordion expanded state.
  void setTranslationEnabled({required bool enabled}) => _commit(
    (s) => s.copyWith(translationEnabled: enabled),
    'Translation enabled',
  );

  /// Sets the selected translation source.
  void setSelectedTranslation(TranslationId source) => _commit(
    (s) => s.copyWith(selectedTranslation: source),
    'Translation source',
  );

  /// Sets the selected tafsir source.
  void setSelectedTafsir(TafsirId source) => _commit(
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
    await persist(
      ref.read(settingsStorageProvider),
      options: const StorageOptions(
        cacheTime: StorageCacheTime.unsafe_forever,
      ),
    ).future;
    return state.value ?? RecitationSettings.initial();
  }

  void _commit(
    RecitationSettings Function(RecitationSettings) fn,
    String field,
  ) {
    if (!state.hasValue) return;
    final current = state.value!;
    final next = fn(current);
    if (current == next) return;
    state = AsyncData(next);
    ref.read(loggerProvider).i('$_recitationLogPrefix $field updated');
  }

  /// Persists the selected reciter and moshaf.
  ///
  /// When [moshafName] is provided, ayah highlighting is turned on for Hafs
  /// riwayat and off for all other recognized non-Hafs riwayat.
  ///
  /// Returns whether highlighting was auto-changed (`true` enabled, `false`
  /// disabled), or `null` when unchanged or [moshafName] is unrecognized.
  bool? setReciter({
    required int reciterId,
    int? moshafId,
    String? moshafName,
  }) {
    if (!state.hasValue) return null;
    final current = state.value!;
    var next = current.copyWith(reciterId: reciterId, moshafId: moshafId);
    bool? autoHighlight;
    if (moshafName != null) {
      final riwayah = moshafTags(moshafName).riwayah;
      if (riwayah != null) {
        final highlightAyah = riwayah == 'حفص';
        if (highlightAyah != current.highlightAyah) {
          autoHighlight = highlightAyah;
        }
        next = next.copyWith(highlightAyah: highlightAyah);
      }
    }
    if (current == next) return null;
    state = AsyncData(next);
    ref.read(loggerProvider).i('$_recitationLogPrefix Reciter updated');
    return autoHighlight;
  }

  /// Persists the output volume (0-100).
  void setVolume(double volume) {
    _volumePreview = null;
    _commit((s) => s.copyWith(volume: volume), 'Volume');
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
      _commit((s) => s.copyWith(highlightAyah: value), 'Highlight ayah');

  /// Persists whether the page follows the played ayah.
  void setAutoScroll({required bool value}) =>
      _commit((s) => s.copyWith(autoScroll: value), 'Auto scroll');

  /// Persists how many times each ayah repeats (clamped 1-99).
  void setAyahRepeatCount(int count) => _commit(
    (s) => s.copyWith(ayahRepeatCount: count.clamp(1, 99)),
    'Ayah repeat count',
  );

  /// Persists how many times the whole selection repeats (clamped 1-99).
  void setRangeRepeatCount(int count) => _commit(
    (s) => s.copyWith(rangeRepeatCount: count.clamp(1, 99)),
    'Range repeat count',
  );

  /// Persists the current playback state (surah/range) for session restore.
  void setPlaybackState({
    int? surah,
    int? rangeStart,
    int? rangeEnd,
    int? rangeFromSurah,
    int? rangeFromAyah,
    int? rangeToSurah,
    int? rangeToAyah,
  }) => _commit(
    (s) => s.copyWith(
      lastSurah: surah,
      lastRangeStart: rangeStart,
      lastRangeEnd: rangeEnd,
      lastRangeFromSurah: rangeFromSurah,
      lastRangeFromAyah: rangeFromAyah,
      lastRangeToSurah: rangeToSurah,
      lastRangeToAyah: rangeToAyah,
    ),
    'Playback state',
  );

  /// Persists surah/range metadata and playback position in one write.
  void persistPlaybackCheckpoint({
    required int surah,
    required int positionMs,
    int? rangeStart,
    int? rangeEnd,
    int? rangeFromSurah,
    int? rangeFromAyah,
    int? rangeToSurah,
    int? rangeToAyah,
  }) => _commit(
    (s) => s.copyWith(
      lastSurah: surah,
      lastRangeStart: rangeStart,
      lastRangeEnd: rangeEnd,
      lastRangeFromSurah: rangeFromSurah,
      lastRangeFromAyah: rangeFromAyah,
      lastRangeToSurah: rangeToSurah,
      lastRangeToAyah: rangeToAyah,
      lastPlaybackPositionMs: positionMs,
    ),
    'Playback checkpoint',
  );

  /// Clears the saved playback position without touching surah/range metadata.
  void clearPlaybackPosition() => _commit(
    (s) => s.copyWith(lastPlaybackPositionMs: null),
    'Playback position',
  );

  /// Persists the last range scope preset selected in the dialog.
  void setLastRangePreset(RangeScopePreset? preset) =>
      _commit((s) => s.copyWith(lastRangePreset: preset), 'Range preset');
}
