import 'dart:async';
import 'dart:convert';

import 'package:riverpod_annotation/experimental/json_persist.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/core/storage/settings_storage.dart';
import 'package:tawaq/feature/settings/presentation/models/settings_tabs.dart';

part 'settings_screen_settings_provider.g.dart';

const _logPrefix = '[SettingsScreenSettingsNotifier]';
const _defaultTabKey = 'appearance';

/// Persisted settings screen tab selection (`activeTabKey` string).
@Riverpod(keepAlive: true)
@JsonPersist()
class SettingsScreenSettingsNotifier extends _$SettingsScreenSettingsNotifier {
  /// Tab key chosen while hydrate is still in flight.
  String? _pendingTabKey;

  @override
  Future<String> build() async {
    try {
      await persist(
        ref.watch(settingsStorageProvider.future),
        options: kSettingsPersistForever,
        decode: _decodeActiveTabKey,
      ).future;
    } on Object catch (error, stack) {
      ref
          .read(loggerProvider)
          .e(
            '$_logPrefix hydrate failed; using default tab',
            error: error,
            stackTrace: stack,
          );
    }
    final pending = _pendingTabKey;
    _pendingTabKey = null;
    if (pending != null) {
      state = AsyncData(pending);
      unawaited(flush());
      return pending;
    }
    return state.value ?? _defaultTabKey;
  }

  /// Awaits a durable disk write of the active tab key.
  Future<void> flush() async {
    final value = state.value;
    if (value == null) return;
    final storage = await ref.read(settingsStorageProvider.future);
    if (!ref.mounted) return;
    await flushPersistedValue(storage, key, value);
  }

  /// Sets the active settings tab.
  void setActiveTabKey(String tabKey) {
    if (!state.hasValue) {
      _pendingTabKey = tabKey;
      return;
    }
    if (state.value == tabKey) return;
    state = AsyncData(tabKey);
    ref.read(loggerProvider).i('$_logPrefix Settings tab updated');
    unawaited(flush());
  }
}

String _decodeActiveTabKey(String encoded) {
  final decoded = jsonDecode(encoded);
  if (decoded is String) {
    return settingsTabIdFromWire(decoded)?.wireValue ?? _defaultTabKey;
  }
  if (decoded is Map) {
    final key = decoded['activeTabKey'];
    if (key is String && key.isNotEmpty) {
      return settingsTabIdFromWire(key)?.wireValue ?? _defaultTabKey;
    }
  }
  return _defaultTabKey;
}
