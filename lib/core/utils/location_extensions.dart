import 'package:adhan_dart/adhan_dart.dart';
import 'package:free_map/free_map.dart';

/// Adds conversions from Adhan [Coordinates] to `LatLng`.
extension CoordinatesExtensions on Coordinates {
  /// Returns a Flutter `LatLng` with the same latitude/longitude.
  LatLng get latLng => LatLng(latitude, longitude);
}

/// Convenience utilities bridging between Free Map and Adhan coordinate types.
extension FmExtensions on FmData {
  /// Converts the Free Map record to an [Coordinates] instance.
  Coordinates get coordinates => Coordinates(lat, lng);

  /// Converts the Free Map record to a Flutter `LatLng`.
  LatLng get latLng => LatLng(lat, lng);
}

/// Adds conversions from Flutter `LatLng` to Adhan [Coordinates].
extension LatLngExtensions on LatLng {
  /// Returns Adhan [Coordinates] representing this point.
  Coordinates get coordinates => Coordinates(latitude, longitude);
}
