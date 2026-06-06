import 'package:tawaq/feature/settings/data/location_constants.dart';
import 'package:tawaq/l10n/app_localizations.dart';

/// Returns a user-facing label for a persisted [locationName] value.
String resolveLocationDisplayName(AppLocalizations l10n, String locationName) {
  return switch (locationName) {
    LocationConstants.defaultLocationName ||
    LocationConstants.legacyDefaultLocationName =>
      l10n.defaultLocation,
    LocationConstants.unknownLocationName ||
    LocationConstants.legacyUnknownLocationName =>
      l10n.unknownLocation,
    _ => locationName,
  };
}
