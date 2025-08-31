import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:free_map/free_map.dart';
import 'package:hasanat/core/utils/location_extensions.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/feature/settings/service/location_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timezone/timezone.dart' as tz;

part 'location_provider.g.dart';

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
    final currentLocation =
        ref.read(prayerSettingsNotifierProvider).valueOrNull?.location;

    // Sort with selected location first, then common timezones, then alphabetically
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

@riverpod
Future<List<FmData>> searchPlaces(Ref ref, String query) async {
  if (query.trim().isEmpty) return [];

  final locationService = ref.read(locationServiceProvider);
  return locationService.searchPlaces(query);
}

@riverpod
class LocationPicker extends _$LocationPicker {
  @override
  (Coordinates coords, String name) build() {
    final settings = ref.read(prayerSettingsNotifierProvider).value;
    final coords =
        settings?.coordinates ?? const Coordinates(21.4362544, 39.6817387);
    final name = settings?.locationName ?? 'مكة المكرمة';
    return (coords, name);
  }

  Future<void> selectPlace(FmData place) async {
    state = (place.coordinates, place.name);
  }

  void updateLocation(LatLng location) async {
    final data = await _getSelectedPlace(location);
    state = (location.coordinates, data?.name ?? 'Unknown Location');
  }

  Future<void> useCurrentLocation() async {
    try {
      final locationService = ref.read(locationServiceProvider);
      final currentLocation = await locationService.getCurrentPosition();
      final data = await _getSelectedPlace(currentLocation);
      state = (currentLocation.coordinates, data?.name ?? 'Unknown Location');
    } catch (e) {
      rethrow;
    }
  }

  Future<FmData?> _getSelectedPlace(LatLng location) async {
    try {
      final locationService = ref.read(locationServiceProvider);
      return locationService.getPlaceDetails(location.coordinates);
    } catch (e) {
      return null;
    }
  }
}
