import 'package:riverpod_annotation/experimental/json_persist.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_persisted_settings.dart';
import 'package:tawaq/feature/settings/data/repository/settings_storage.dart';

part 'hadith_screen_settings_provider.g.dart';

const _logPrefix = '[HadithScreenSettingsNotifier]';

/// Persisted Hadith screen UI state.
@riverpod
@JsonPersist()
class HadithScreenSettingsNotifier extends _$HadithScreenSettingsNotifier {
  @override
  Future<HadithPersistedSettings> build() async {
    await persist(
      ref.watch(settingsStorageProvider.future),
      options: const StorageOptions(
        cacheTime: StorageCacheTime.unsafe_forever,
      ),
    ).future;
    return state.value ?? HadithPersistedSettings.initial();
  }

  void _commit(
    HadithPersistedSettings Function(HadithPersistedSettings) fn,
    String field,
  ) {
    if (!state.hasValue) return;
    final current = state.value!;
    final next = fn(current);
    if (current == next) return;
    state = AsyncData(next);
    ref.read(loggerProvider).i('$_logPrefix $field updated');
  }

  /// Sets the hadith active panel tab.
  void setActiveTab(HadithPanelTab tab) =>
      _commit((s) => s.copyWith(activeTab: tab), 'Hadith tab');

  /// Sets the side panel width ratio (0..1).
  void setSidePanelRatio(double ratio) =>
      _commit((s) => s.copyWith(sidePanelRatio: ratio), 'Side panel ratio');

  /// Sets whether the side panel is collapsed.
  void setSidePanelCollapsed({required bool collapsed}) => _commit(
    (s) => s.copyWith(sidePanelCollapsed: collapsed),
    'Side panel collapsed',
  );
}
