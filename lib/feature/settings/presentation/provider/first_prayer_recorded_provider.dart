import 'package:riverpod_annotation/experimental/json_persist.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/feature/settings/data/repository/settings_storage.dart';

part 'first_prayer_recorded_provider.g.dart';

const _logPrefix = '[FirstPrayerRecordedDate]';

/// Persisted date of the first prayer ever recorded.
///
/// Stored as an ISO 8601 string. This replaces the old Prf-based setting and
/// is used by prayer analytics / completion providers.
@riverpod
@JsonPersist()
class FirstPrayerRecordedDate extends _$FirstPrayerRecordedDate {
  @override
  Future<String?> build() async {
    try {
      await persist(
        ref.watch(settingsStorageProvider.future),
        options: kSettingsPersistForever,
      ).future;
    } on Object catch (error, stack) {
      ref.read(loggerProvider).e(
        '$_logPrefix hydrate failed; treating as unset',
        error: error,
        stackTrace: stack,
      );
    }
    return state.value;
  }

  @override
  String get key => 'first_prayer_recorded_date';

  /// Sets the date only if not already set.
  ///
  /// No-ops while hydrate is still in flight (`!hasValue`) so a mid-load write
  /// cannot race the decode and get overwritten by `null`.
  void setIfNull(DateTime date) {
    if (!state.hasValue) return;
    if (state.value != null) return;
    state = AsyncData(date.toIso8601String());
  }
}
