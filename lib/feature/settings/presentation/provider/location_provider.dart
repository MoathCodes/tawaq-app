import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:free_map/free_map.dart';
import 'package:hasanat/core/utils/location_extensions.dart';
import 'package:hasanat/feature/settings/service/location_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'location_provider.g.dart';

@riverpod
Future<List<FmData>> searchPlaces(Ref ref, String query) async {
  if (query.trim().isEmpty) return [];

  final locationService = ref.read(locationServiceProvider);
  return locationService.searchPlaces(query);
}

@riverpod
class LocationPicker extends _$LocationPicker {
  @override
  LatLng build(Coordinates initialLocation) {
    return initialLocation.latLng;
  }

  Future<FmData?> getSelectedPlace() async {
    final locationService = ref.read(locationServiceProvider);
    return locationService.getPlaceDetails(state.coordinates);
  }

  Future<void> selectPlace(FmData place) async {
    state = LatLng(
      place.lat,
      place.lng,
    );
  }

  void updateLocation(LatLng location) {
    state = location;
  }

  Future<void> useCurrentLocation() async {
    try {
      final locationService = ref.read(locationServiceProvider);
      final currentLocation = await locationService.getCurrentPosition();
      state = currentLocation;
    } catch (e) {
      // Handle error appropriately - maybe show a snackbar
      rethrow;
    }
  }
}
