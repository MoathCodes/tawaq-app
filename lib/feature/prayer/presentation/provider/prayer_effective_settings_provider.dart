import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_time_inputs.dart';
import 'package:tawaq/feature/settings/data/models/prayer_settings_model.dart';
import 'package:tawaq/feature/settings/presentation/provider/prayer_settings_provider.dart';

part 'prayer_effective_settings_provider.g.dart';

/// Last successfully resolved prayer settings, reused when a (re)build cannot
/// read storage.
///
/// Updated by [PrayerSettingsNotifier] on every good hydrate. Read by
/// [effectivePrayerSettingsProvider] when the async notifier is loading or
/// location is not ready yet.
PrayerSettings lastGoodPrayerSettings = PrayerSettings.defaultSettings();

/// Synchronous prayer settings safe for time math and completions.
///
/// Returns the hydrated settings when location is ready, otherwise the last
/// good stored settings. Null when no valid coordinates exist yet.
@Riverpod(keepAlive: true)
PrayerSettings? effectivePrayerSettings(Ref ref) {
  ref.watch(prayerSettingsProvider);
  final current = ref.read(prayerSettingsProvider).value;
  if (current != null && current.isLocationReady) return current;
  if (lastGoodPrayerSettings.isLocationReady) return lastGoodPrayerSettings;
  return null;
}

/// Whether prayer times can be computed from stored coordinates.
@Riverpod(keepAlive: true)
bool prayerLocationReady(Ref ref) {
  return ref.watch(effectivePrayerSettingsProvider) != null;
}

/// Whether settings have loaded but coordinates are still unset (0,0 sentinel).
@Riverpod(keepAlive: true)
bool prayerLocationSetupNeeded(Ref ref) {
  final settings = ref.watch(prayerSettingsProvider);
  if (settings.isLoading) return false;
  return !ref.watch(prayerLocationReadyProvider);
}

/// Narrow projection of persisted prayer settings used for time math.
@Riverpod(keepAlive: true)
PrayerTimeInputs? prayerTimeInputs(Ref ref) {
  final settings = ref.watch(effectivePrayerSettingsProvider);
  if (settings == null) return null;
  return PrayerTimeInputs(
    method: settings.method,
    coordinates: settings.coordinates,
    location: settings.location,
  );
}
