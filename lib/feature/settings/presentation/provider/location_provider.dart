import 'package:free_map/free_map.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/feature/settings/domain/services/timezone_catalog.dart';
import 'package:tawaq/feature/settings/presentation/provider/location_service_provider.dart';
import 'package:tawaq/feature/settings/presentation/provider/prayer_settings_provider.dart';
import 'package:timezone/timezone.dart' as tz;

part 'location_provider.g.dart';

/// Provider that loads and sorts available timezones.
@riverpod
Future<List<tz.Location>> loadTimezones(Ref ref) async {
  return Future.microtask(() {
    final database = tz.timeZoneDatabase;
    final currentLocation = ref.read(prayerSettingsProvider).value?.location;

    return sortTimezones(
      locations: database.locations.values,
      selected: currentLocation,
    );
  });
}

/// Provider that searches for places based on a query string.
@riverpod
Future<List<FmData>> searchPlaces(Ref ref, String query) async {
  if (query.trim().isEmpty) return [];

  final locationService = ref.read(locationServiceProvider);
  return locationService.searchPlaces(query);
}
