import 'package:riverpod_annotation/experimental/json_persist.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/feature/settings/data/repository/settings_storage.dart';
import 'package:tawaq/feature/settings/domain/models/settings_screen_state.dart';

part 'settings_screen_settings_provider.g.dart';

const _logPrefix = '[SettingsScreenSettingsNotifier]';

/// Persisted settings screen tab selection.
@riverpod
@JsonPersist()
class SettingsScreenSettingsNotifier extends _$SettingsScreenSettingsNotifier {
  @override
  Future<SettingsScreenState> build() async {
    await persist(
      ref.read(settingsStorageProvider),
      options: const StorageOptions(
        cacheTime: StorageCacheTime.unsafe_forever,
      ),
    ).future;
    return state.value ?? SettingsScreenState.initial();
  }

  void _commit(
    SettingsScreenState Function(SettingsScreenState) fn,
    String field,
  ) {
    if (!state.hasValue) return;
    final current = state.value!;
    final next = fn(current);
    if (current == next) return;
    state = AsyncData(next);
    ref.read(loggerProvider).i('$_logPrefix $field updated');
  }

  /// Sets the active settings tab.
  void setActiveTabKey(String tabKey) => _commit(
    (s) => s.copyWith(activeTabKey: tabKey),
    'Settings tab',
  );
}
