import 'package:riverpod_annotation/experimental/json_persist.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/feature/settings/data/repository/settings_storage.dart';

part 'first_prayer_recorded_provider.g.dart';

/// Persisted date of the first prayer ever recorded.
///
/// Stored as an ISO 8601 string. This replaces the old Prf-based setting and
/// is used by prayer analytics / completion providers.
@riverpod
@JsonPersist()
class FirstPrayerRecordedDate extends _$FirstPrayerRecordedDate {
  @override
  String? build() {
    persist(
      ref.read(settingsStorageProvider),
      options: const StorageOptions(
        cacheTime: StorageCacheTime.unsafe_forever,
      ),
    );
    return null;
  }

  @override
  String get key => 'first_prayer_recorded_date';

  /// Sets the date only if not already set.
  void setIfNull(DateTime date) {
    if (state != null) return;
    state = date.toIso8601String();
  }
}
