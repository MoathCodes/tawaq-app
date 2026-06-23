import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:free_map/free_map.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/feature/settings/domain/services/timezone_catalog.dart';
import 'package:tawaq/feature/settings/presentation/provider/location_service_provider.dart';
import 'package:tawaq/feature/settings/presentation/provider/prayer_settings_provider.dart';
import 'package:timezone/timezone.dart' as tz;

part 'location_provider.g.dart';

/// Sorted IANA timezone catalog, computed once and filtered in memory.
@Riverpod(keepAlive: true)
List<tz.Location> timezoneCatalog(Ref ref) {
  return sortTimezones(locations: tz.timeZoneDatabase.locations.values);
}

/// Provider that loads and sorts available timezones.
@riverpod
List<tz.Location> loadTimezones(Ref ref) {
  final catalog = ref.watch(timezoneCatalogProvider);
  final selected = ref.watch(
    prayerSettingsProvider.select((settings) => settings.value?.location),
  );
  if (selected == null) return catalog;
  return sortTimezones(locations: catalog, selected: selected);
}

/// Provider that searches for places based on a query string.
@riverpod
Future<List<FmData>> searchPlaces(Ref ref, String query) async {
  if (query.trim().isEmpty) return [];

  final locationService = ref.read(locationServiceProvider);
  return locationService.searchPlaces(query);
}
