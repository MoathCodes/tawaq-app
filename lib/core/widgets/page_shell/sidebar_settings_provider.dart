import 'package:riverpod_annotation/experimental/json_persist.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/core/storage/settings_storage.dart';

part 'sidebar_settings_provider.g.dart';

/// Persisted sidebar collapsed state.
@riverpod
@JsonPersist()
class SidebarSettingsNotifier extends _$SidebarSettingsNotifier {
  @override
  Future<bool> build() async {
    await persist(
      ref.watch(settingsStorageProvider.future),
      options: const StorageOptions(
        cacheTime: StorageCacheTime.unsafe_forever,
      ),
    ).future;
    return state.value ?? false;
  }

  void _commit(bool collapsed) {
    if (!state.hasValue || state.value == collapsed) return;
    state = AsyncData(collapsed);
    ref.read(loggerProvider).i('[SidebarSettingsNotifier] Sidebar updated');
  }

  /// Sets the sidebar collapsed state.
  void setCollapsed({required bool collapsed}) => _commit(collapsed);
}
