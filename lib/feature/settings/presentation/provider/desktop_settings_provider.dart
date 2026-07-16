import 'package:riverpod_annotation/experimental/json_persist.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/desktop/launch_at_login_service.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/core/utils/platform.dart';
import 'package:tawaq/feature/settings/data/models/desktop_settings.dart';
import 'package:tawaq/feature/settings/data/repository/settings_storage.dart';

part 'desktop_settings_provider.g.dart';

const _logPrefix = '[DesktopSettingsNotifier]';

/// Persisted desktop tray and window behaviour.
@Riverpod(keepAlive: true)
@JsonPersist()
class DesktopSettingsNotifier extends _$DesktopSettingsNotifier {
  @override
  Future<DesktopSettings> build() async {
    await persist(
      ref.read(settingsStorageProvider),
      options: const StorageOptions(
        cacheTime: StorageCacheTime.unsafe_forever,
      ),
    ).future;
    if (!ref.mounted) return DesktopSettings.defaults();
    return state.value ?? DesktopSettings.defaults();
  }

  void _commit(DesktopSettings Function(DesktopSettings) fn, String field) {
    if (!state.hasValue) return;
    final next = fn(state.value!);
    if (next == state.value) return;
    state = AsyncData(next);
    ref.read(loggerProvider).i('$_logPrefix $field updated');
  }

  /// Sets whether closing the window hides to tray instead of quitting.
  void setMinimizeToTrayOnClose({required bool value}) => _commit(
    (s) => s.copyWith(minimizeToTrayOnClose: value),
    'Minimize to tray on close',
  );

  /// Sets whether the minimize button hides to tray.
  void setMinimizeToTray({required bool value}) =>
      _commit((s) => s.copyWith(minimizeToTray: value), 'Minimize to tray');

  /// Sets whether the app starts hidden in the tray.
  void setLaunchToTray({required bool value}) =>
      _commit((s) => s.copyWith(launchToTray: value), 'Launch to tray');

  /// Sets whether the app starts automatically at login.
  ///
  /// Returns `true` when the one-time tray hint should be shown.
  Future<bool> setLaunchAtLogin({required bool value}) async {
    if (!state.hasValue) return false;

    final current = state.value!;
    final showHint = value && !current.launchAtLoginHintSeen;

    var next = current.copyWith(
      launchAtLogin: value,
      launchAtLoginHintSeen: current.launchAtLoginHintSeen || value,
    );
    if (value && !current.launchToTray) {
      next = next.copyWith(launchToTray: true);
    }

    if (next == current) return false;

    _commit((_) => next, 'Launch at login');

    if (isDesktopPlatform) {
      await LaunchAtLoginService.setEnabled(value: value);
    }

    return showHint;
  }

  /// Sets whether the app forces macOS-style window controls.
  void setForceMacStyleWindowControls({required bool value}) => _commit(
    (s) => s.copyWith(forceMacStyleWindowControls: value),
    'Force macOS style window controls',
  );
}
