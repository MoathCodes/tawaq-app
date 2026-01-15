import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:free_map/free_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hasanat/core/logging/logger_provider.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:lat_lng_to_timezone/lat_lng_to_timezone.dart' as tz_mapper;
import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timezone/timezone.dart';

part 'location_service.g.dart';

/// Provider for the [LocationService].
@riverpod
LocationService locationService(Ref ref) {
  final log = ref.read(loggerProvider);
  final lang = ref.watch(
    localeProvider.select((value) => value.value?.languageCode),
  );
  final service = FmService()
    ..setData(userAgent: 'Tawaq/1.0 (contact: moathaltamimidev@gmail.com)');
  return LocationService(log, service, lang);
}

/// Exception thrown when a location-related error occurs.
class LocationException implements Exception {
  /// Creates a [LocationException] instance.
  LocationException(this.message);

  /// The error message.
  final String message;

  @override
  String toString() => message;
}

/// Service for location-related operations.
class LocationService {
  /// Creates a [LocationService] instance.
  LocationService(this._log, this._service, this.languageCode);

  /// The logger instance.
  final Logger _log;

  /// The language code for localized results.
  final String? languageCode;
  final FmService _service;

  /// Returns the current device position.
  Future<LatLng> getCurrentPosition() async {
    try {
      _log.i('[LocationService] Getting current position...');

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw LocationException('Location services are disabled.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw LocationException('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw LocationException(
          'Location permissions are permanently denied, '
          'we cannot request permissions.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: .high),
      );

      final result = LatLng(position.latitude, position.longitude);
      _log.i('[LocationService] Position obtained: $result');
      return result;
    } catch (e, stackTrace) {
      _log.e(
        '[LocationService] Error getting position',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Returns the timezone location from coordinates using an offline mapper.
  Location? getLocationFromCoordinatesOffline(Coordinates coordinates) {
    try {
      final timezoneName = tz_mapper.latLngToTimezoneString(
        coordinates.latitude,
        coordinates.longitude,
      );

      return getLocation(timezoneName);
    } catch (e, stack) {
      _log.e(
        '[LocationService] Error getting location from coordinates',
        error: e,
        stackTrace: stack,
      );
      throw LocationException('Error getting location from coordinates');
    }
  }

  /// Returns place details for the given coordinates.
  Future<FmData> getPlaceDetails(Coordinates coords) async {
    try {
      _log.i('[LocationService] Getting details for place: $coords');
      final place = await _service.getAddress(
        lat: coords.latitude,
        lng: coords.longitude,
      );
      if (place == null) {
        throw LocationException('No place found for coordinates: $coords');
      }
      _log.i('[LocationService] Place details obtained: $place');
      return place;
    } catch (e, stackTrace) {
      _log.e(
        '[LocationService] Error getting place details',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Searches for places matching the given query.
  Future<List<FmData>> searchPlaces(String query) async {
    try {
      _log.i('[LocationService] Searching for: $query');
      final results = await _service.search(
        q: query,
        p: FmSearchParams(
          langs: [
            'en',
            if (languageCode != 'en' && languageCode != null) languageCode!,
          ],
        ),
      );
      _log.i('[LocationService] Found ${results.length} results');
      return results;
    } catch (e, stackTrace) {
      _log.e(
        '[LocationService] Error searching places',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }
}
