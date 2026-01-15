import 'package:adhan_dart/adhan_dart.dart';
import 'package:free_map/free_map.dart';
import 'package:hasanat/core/logging/logger_provider.dart';
import 'package:hasanat/core/utils/location_extensions.dart';
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

/// Notifier for the location picker state.
@riverpod
class LocationPicker extends _$LocationPicker {
  @override
  ({Coordinates coords, String name}) build() {
    final settings = ref.read(prayerSettingsProvider).value;
    final coords =
        settings?.coordinates ?? const Coordinates(21.4362544, 39.6817387);
    final name = settings?.locationName ?? 'مكة المكرمة';
    return (coords: coords, name: name);
  }

  /// Selects a place and updates the state.
  Future<void> selectPlace(FmData place) async {
    state = (coords: place.coordinates, name: place.name);
  }

  /// Updates the location based on coordinates and fetches the place name.
  Future<void> updateLocation(LatLng location) async {
    state = (coords: location.coordinates, name: 'Loading...');
    try {
      final data = await _getSelectedPlace(location);
      if (!ref.mounted) return;
      state = (coords: location.coordinates, name: _getAvailableName(data));
    } catch (e, stack) {
      if (!ref.mounted) rethrow;
      ref
          .read(loggerProvider)
          .e('Error updating location', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Uses the current device location and updates the map controller.
  Future<void> useCurrentLocation(MapController mapController) async {
    if (!ref.mounted) return;
    try {
      final locationService = ref.read(locationServiceProvider);
      final currentLocation = await locationService.getCurrentPosition();
      if (!ref.mounted) return;
      state = (coords: currentLocation.coordinates, name: 'Loading...');
      mapController.move(currentLocation, 14);
      final data = await _getSelectedPlace(currentLocation);
      if (!ref.mounted) return;
      state = (
        coords: currentLocation.coordinates,
        name: _getAvailableName(data),
      );
    } catch (e, stack) {
      if (!ref.mounted) rethrow;
      ref
          .read(loggerProvider)
          .e('Error getting current location', error: e, stackTrace: stack);
      rethrow;
    }
  }

  String _getAvailableName(FmData? data) {
    if (data == null) return 'Unknown Location';
    if (data.name.isNotEmpty) {
      return data.name;
    }
    if (data.rawAddress != null) {
      final address = data.rawAddress!;
      if (address.city != null && address.city!.isNotEmpty) {
        return address.city!;
      }
      if (address.state != null && address.state!.isNotEmpty) {
        return address.state!;
      }
      if (address.country != null && address.country!.isNotEmpty) {
        return address.country!;
      }
    }
    return 'Unknown Location';
  }

  Future<FmData?> _getSelectedPlace(LatLng location) async {
    if (!ref.mounted) return null;
    try {
      final locationService = ref.read(locationServiceProvider);
      return locationService.getPlaceDetails(location.coordinates);
    } catch (e) {
      return null;
    }
  }
}
