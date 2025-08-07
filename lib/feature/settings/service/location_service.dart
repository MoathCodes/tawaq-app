import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:free_map/free_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hasanat/core/logging/talker_provider.dart';
import 'package:lat_lng_to_timezone/lat_lng_to_timezone.dart' as tzMapper;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:timezone/timezone.dart';

part 'location_service.g.dart';

@riverpod
LocationService locationService(Ref ref) {
  final talker = ref.read(talkerNotifierProvider);
  final service = FmService();
  return LocationService(talker, service);
}

class LocationException implements Exception {
  final String message;
  LocationException(this.message);

  @override
  String toString() => message;
}

class LocationService {
  final Talker _talker;
  final FmService _service;
  LocationService(this._talker, this._service);

  Future<LatLng> getCurrentPosition() async {
    try {
      _talker.info('[LocationService] Getting current position...');

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw LocationException('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw LocationException('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw LocationException(
            'Location permissions are permanently denied, we cannot request permissions.');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final result = LatLng(position.latitude, position.longitude);
      _talker.info('[LocationService] Position obtained: $result');
      return result;
    } catch (e, stackTrace) {
      _talker.handle(e, stackTrace, '[LocationService] Error getting position');
      rethrow;
    }
  }

  Location? getLocationFromCoordinatesOffline(Coordinates coordinates) {
    try {
      final timezoneName = tzMapper.latLngToTimezoneString(
          coordinates.latitude, coordinates.longitude);

      return getLocation(timezoneName);
    } catch (e, stack) {
      _talker.handle(e, stack,
          '[LocationService] Error getting location from coordinates');
      throw LocationException('Error getting location from coordinates');
    }
  }

  Future<FmData> getPlaceDetails(Coordinates coords) async {
    try {
      _talker.info('[LocationService] Getting details for place: $coords');
      final place = await _service.getAddress(
          lat: coords.latitude, lng: coords.longitude);
      if (place == null) {
        throw LocationException('No place found for coordinates: $coords');
      }
      _talker.info('[LocationService] Place details obtained: $place');
      return place;
    } catch (e, stackTrace) {
      _talker.handle(
          e, stackTrace, '[LocationService] Error getting place details');
      rethrow;
    }
  }

  Future<List<FmData>> searchPlaces(String query) async {
    try {
      _talker.info('[LocationService] Searching for: $query');
      final results = await _service.search(
        q: query,
        p: const FmSearchParams(),
      );
      _talker.info('[LocationService] Found ${results.length} results');
      return results;
    } catch (e, stackTrace) {
      _talker.handle(e, stackTrace, '[LocationService] Error searching places');
      return [];
    }
  }
}
