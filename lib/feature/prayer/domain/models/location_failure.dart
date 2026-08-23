/// Known location failures surfaced to the user.
enum LocationFailureCode {
  /// Device location services are turned off.
  servicesDisabled,

  /// The user denied location permission.
  permissionDenied,

  /// Location permission was permanently denied.
  permissionDeniedForever,

  /// Offline timezone lookup from coordinates failed.
  coordinatesLookupFailed,

  /// Reverse geocoding returned no place for the coordinates.
  noPlaceFound,
}

/// Exception thrown when a location-related error occurs.
class LocationException implements Exception {
  /// Creates a [LocationException] for [code].
  const new(this.code, {this.detail});

  /// The failure category.
  final LocationFailureCode code;

  /// Optional detail (e.g. coordinates) for parameterized messages.
  final String? detail;

  @override
  String toString() => detail == null ? code.name : '${code.name}: $detail';
}
