import 'package:free_map/free_map.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/feature/settings/service/location_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timezone/timezone.dart' as tz;

part 'location_provider.g.dart';

/// Provider that loads and sorts available timezones.
@riverpod
Future<List<tz.Location>> loadTimezones(Ref ref) async {
  final commonTimezones = [
    'Asia/Riyadh',
    'Asia/Dubai',
    'Asia/Kuwait',
    'Asia/Qatar',
    'Asia/Bahrain',
    'Africa/Cairo',
    'Asia/Baghdad',
    'Asia/Damascus',
    'Asia/Amman',
    'Asia/Beirut',
    'Europe/Istanbul',
    'Europe/London',
    'Europe/Paris',
    'America/New_York',
    'America/Los_Angeles',
    'Asia/Tokyo',
    'Australia/Sydney',
  ];

  return Future.microtask(() {
    final database = tz.timeZoneDatabase;
    final allLocations = database.locations.values.toList();
    final currentLocation = ref.read(prayerSettingsProvider).value?.location;

    // Sort with selected location first, then common timezones, then
    // alphabetically
    allLocations.sort((a, b) {
      // Selected location always comes first
      if (currentLocation != null) {
        if (a.name == currentLocation.name) return -1;
        if (b.name == currentLocation.name) return 1;
      }

      // Then common timezones (excluding the selected one to avoid duplication)
      final aIsCommon =
          commonTimezones.contains(a.name) && a.name != currentLocation?.name;
      final bIsCommon =
          commonTimezones.contains(b.name) && b.name != currentLocation?.name;

      if (aIsCommon && !bIsCommon) return -1;
      if (!aIsCommon && bIsCommon) return 1;

      return a.name.compareTo(b.name);
    });

    return allLocations;
  });
}

/// Provider that searches for places based on a query string.
@riverpod
Future<List<FmData>> searchPlaces(Ref ref, String query) async {
  if (query.trim().isEmpty) return [];

  final locationService = ref.read(locationServiceProvider);
  return locationService.searchPlaces(query);
}
