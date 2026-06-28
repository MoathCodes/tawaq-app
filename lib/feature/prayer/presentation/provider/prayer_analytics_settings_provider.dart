import 'package:riverpod_annotation/experimental/json_persist.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_analytics.dart';
import 'package:tawaq/feature/settings/data/models/prayer_analytics_prefs.dart';
import 'package:tawaq/feature/settings/data/repository/settings_storage.dart';

part 'prayer_analytics_settings_provider.g.dart';

const _logPrefix = '[PrayerAnalyticsSettingsNotifier]';

/// Persisted prayer analytics period selection.
@riverpod
@JsonPersist()
class PrayerAnalyticsSettingsNotifier
    extends _$PrayerAnalyticsSettingsNotifier {
  @override
  Future<PrayerAnalyticsPrefs> build() async {
    await persist(
      ref.read(settingsStorageProvider),
      options: const StorageOptions(
        cacheTime: StorageCacheTime.unsafe_forever,
      ),
    ).future;
    return state.value ?? PrayerAnalyticsPrefs.defaults();
  }

  void _commit(
    PrayerAnalyticsPrefs Function(PrayerAnalyticsPrefs) fn,
    String field,
  ) {
    if (!state.hasValue) return;
    final current = state.value!;
    final next = fn(current);
    if (current == next) return;
    state = AsyncData(next);
    ref.read(loggerProvider).i('$_logPrefix $field updated');
  }

  /// Sets the prayer analytics period.
  void setPeriod(PrayerAnalyticsPeriod period) {
    final current = state.value ?? PrayerAnalyticsPrefs.defaults();
    if (current.period == period) return;
    _commit((s) => s.copyWith(period: period), 'Period');
  }
}
