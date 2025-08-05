import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hasanat/core/utils/prayer_extensions.dart';
import 'package:hasanat/feature/prayer/data/models/prayer_completion.dart';
import 'package:hasanat/feature/prayer/domain/services/prayer_service.dart';
import 'package:hasanat/feature/settings/data/models/prayer_settings_model.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'prayer_data_providers.g.dart';

/// Provides the current time in the user's selected location.
/// This will automatically update dependents when the settings change.
@riverpod
DateTime currentLocationTime(Ref ref) {
  final location = ref.watch(prayerSettingsNotifierProvider
      .select((settings) => settings.value?.location));

  // Use default location if settings are not loaded yet.
  return DateTime.now()
      .toLocation(location ?? PrayerSettings.defaultSettings().location);
}

/// Watches the prayer completions for a specific date from the database.
/// Using a `.family` allows us to fetch data for any given date.
@Riverpod(keepAlive: true)
Stream<List<PrayerCompletion>> prayerCompletionsForDate(
    Ref ref, DateTime date) {
  final service = ref.watch(prayerServiceProvider);
  // Normalize the date to avoid issues with time components.
  final dateKey = DateTime(date.year, date.month, date.day);
  return service.watchPrayerCompletionByDate(dateKey);
}

/// Provides the prayer times for the current day.
/// It automatically recalculates if the date changes or settings are updated.
@riverpod
PrayerTimesData todaysPrayerTimes(Ref ref) {
  // Depend on the service to get the prayer times.
  final service = ref.watch(prayerServiceProvider);
  return service.getTodaysPrayerTimes();
}
