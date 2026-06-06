/// Persisted tokens for location names; localize at display time in presentation.
abstract final class LocationConstants {
  /// Stored when no default place has been chosen yet.
  static const defaultLocationName = '@location/default';

  /// Stored when reverse geocoding returns no place name.
  static const unknownLocationName = '@location/unknown';

  /// Legacy English default from older app versions.
  static const legacyDefaultLocationName = 'Default Location';

  /// Legacy English fallback from older app versions.
  static const legacyUnknownLocationName = 'Unknown Location';
}

