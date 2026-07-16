import 'dart:convert';

import 'package:riverpod_annotation/experimental/json_persist.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/feature/settings/data/repository/settings_storage.dart';

part 'settings_screen_settings_provider.g.dart';

const _logPrefix = '[SettingsScreenSettingsNotifier]';
const _defaultTabKey = 'appearance';

/// Persisted settings screen tab selection (`activeTabKey` string).
@riverpod
@JsonPersist()
class SettingsScreenSettingsNotifier extends _$SettingsScreenSettingsNotifier {
  @override
  Future<String> build() async {
    try {
      await persist(
        ref.read(settingsStorageProvider),
        options: const StorageOptions(
          cacheTime: StorageCacheTime.unsafe_forever,
        ),
        decode: _decodeActiveTabKey,
      ).future;
    } on Object catch (error, stack) {
      ref.read(loggerProvider).e(
        '$_logPrefix hydrate failed; using default tab',
        error: error,
        stackTrace: stack,
      );
    }
    return state.value ?? _defaultTabKey;
  }

  /// Sets the active settings tab.
  void setActiveTabKey(String tabKey) {
    if (!state.hasValue) return;
    if (state.value == tabKey) return;
    state = AsyncData(tabKey);
    ref.read(loggerProvider).i('$_logPrefix Settings tab updated');
  }
}

String _decodeActiveTabKey(String encoded) {
  final decoded = jsonDecode(encoded);
  if (decoded is String) return decoded;
  if (decoded is Map) {
    final key = decoded['activeTabKey'];
    if (key is String && key.isNotEmpty) return key;
  }
  return _defaultTabKey;
}
