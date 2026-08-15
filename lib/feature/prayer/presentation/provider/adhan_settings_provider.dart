import 'package:adhan_dart/adhan_dart.dart';
import 'package:riverpod_annotation/experimental/json_persist.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/core/storage/settings_storage.dart';
import 'package:tawaq/feature/prayer/domain/models/adhan_settings.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_alert_kind.dart';
import 'package:tawaq/feature/prayer/domain/models/schedule_alert_mode.dart';

part 'adhan_settings_provider.g.dart';

const _logPrefix = '[AdhanSettingsNotifier]';

/// Persisted prayer alert notification and playback settings.
@Riverpod(keepAlive: true)
@JsonPersist()
class AdhanSettingsNotifier extends _$AdhanSettingsNotifier {
  @override
  Future<AdhanSettings> build() async {
    try {
      await persist(
        ref.watch(settingsStorageProvider.future),
        options: const StorageOptions(
          cacheTime: StorageCacheTime.unsafe_forever,
        ),
      ).future;
    } on Object catch (error, stack) {
      ref
          .read(loggerProvider)
          .e(
            '$_logPrefix hydrate failed; using current/default settings',
            error: error,
            stackTrace: stack,
          );
    }
    return state.value ?? AdhanSettings.defaults();
  }

  void _commit(AdhanSettings Function(AdhanSettings) fn, String field) {
    if (!state.hasValue) return;
    final next = fn(state.value!);
    if (next == state.value) return;
    state = AsyncData(next);
    ref.read(loggerProvider).i('$_logPrefix $field updated');
  }

  /// Sets the alert [mode] for [kind] and [prayer].
  void setAlertMode(
    PrayerAlertKind kind,
    Prayer prayer,
    ScheduleAlertMode mode,
  ) => _commit(
    (s) => adhanSettingsWithMode(s, kind, prayer, mode),
    '${kind.name} mode for $prayer',
  );

  /// Sets whether all prayer alert playback is muted.
  void setMuteAll({required bool value}) =>
      _commit((s) => s.copyWith(muteAll: value), 'Mute all');

  /// Sets the bundled adhan sound.
  void setSound(AdhanSound sound) =>
      _commit((s) => s.copyWith(sound: sound), 'Sound');

  /// Sets the bundled iqamah sound.
  void setIqamahSound(IqamahSound sound) =>
      _commit((s) => s.copyWith(iqamahSound: sound), 'Iqamah sound');

  /// Sets playback volume (0–100) and persists immediately.
  void setVolume(double volume) =>
      _commit((s) => s.copyWith(volume: volume.clamp(0, 100)), 'Volume');

  /// Sets whether the in-app alert overlay is shown.
  void setShowAdhanAlert({required bool value}) =>
      _commit((s) => s.copyWith(showAdhanAlert: value), 'Show alert');

  /// Sets whether a companion OS notification is shown from tray.
  void setShowOsNotification({required bool value}) =>
      _commit((s) => s.copyWith(showOsNotification: value), 'OS notification');

  /// Sets compact alert window placement.
  void setAlertPosition(AdhanAlertPosition position) =>
      _commit((s) => s.copyWith(alertPosition: position), 'Alert position');
}
