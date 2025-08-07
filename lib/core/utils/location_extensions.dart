import 'package:adhan_dart/adhan_dart.dart';
import 'package:free_map/free_map.dart';

extension FmExtensions on FmData {
  Coordinates get coordinates => Coordinates(lat, lng);

  LatLng get latLng => LatLng(lat, lng);
}

extension CoordinatesExtensions on Coordinates {
  LatLng get latLng => LatLng(latitude, longitude);
}

extension LatLngExtensions on LatLng {
  Coordinates get coordinates => Coordinates(latitude, longitude);
}
