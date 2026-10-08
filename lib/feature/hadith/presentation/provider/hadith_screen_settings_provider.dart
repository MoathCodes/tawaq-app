import 'package:riverpod_annotation/experimental/json_persist.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/core/storage/settings_storage.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_persisted_settings.dart';

part 'hadith_screen_settings_provider.g.dart';

const _logPrefix = '[HadithScreenSettingsNotifier]';

/// Persisted Hadith screen UI state.
@Riverpod(keepAlive: true)
@JsonPersist()
class HadithScreenSettingsNotifier extends _$HadithScreenSettingsNotifier {
  @override
  Future<HadithPersistedSettings> build() async {
    await persist(
      ref.watch(settingsStorageProvider.future),
      options: const StorageOptions(cacheTime: StorageCacheTime.unsafe_forever),
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

  void setFiltersVisible(bool visible) =>
      _commit((s) => s.copyWith(filtersVisible: visible), 'Filters visible');
  void setFiltersWidth(double width) =>
      _commit((s) => s.copyWith(filtersWidth: width), 'Filters width');
  void setReaderRatio(double ratio) => _commit(
    (s) => s.copyWith(readerRatio: ratio, sidePanelRatio: ratio),
    'Reader ratio',
  );
  void setReaderCollapsed(bool collapsed) => _commit(
    (s) =>
        s.copyWith(readerCollapsed: collapsed, sidePanelCollapsed: collapsed),
    'Reader collapsed',
  );
}
