import 'package:free_map/free_map.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/settings/data/location_constants.dart';
import 'package:tawaq/feature/settings/domain/models/location_failure.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:forui/forui.dart';
import 'package:flutter/material.dart';

/// Default map center (Makkah).
const kDefaultCenter = LatLng(21.4362544, 39.6817387);

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

/// Maps [error] to a localized message when it is a [LocationException].
String localizeLocationFailure(AppLocalizations l10n, Object error) {
  if (error is! LocationException) return error.toString();

  return switch (error.code) {
    LocationFailureCode.servicesDisabled => l10n.locationServicesDisabled,
    LocationFailureCode.permissionDenied => l10n.locationPermissionDenied,
    LocationFailureCode.permissionDeniedForever =>
      l10n.locationPermissionDeniedForever,
    LocationFailureCode.coordinatesLookupFailed =>
      l10n.locationCoordinatesLookupFailed,
    LocationFailureCode.noPlaceFound =>
      l10n.locationNoPlaceFound(error.detail ?? ''),
  };
}

/// Shows a location error toast.
void showLocationError(BuildContext context, String action, Object error) {
  if (!context.mounted) return;
  final l10n = context.l10n;
  showFToast(
    context: context,
    title: Text(l10n.errorOccurredWhile(action)),
    description: Text(localizeLocationFailure(l10n, error)),
  );
}

/// Whether manual location controls are editable.
bool manualLocationControlsEnabled(WidgetRef ref) {
  final ready = ref.watch(
    prayerSettingsProvider.select((v) => v.hasValue),
  );
  final autoLocation = ref.watch(
    prayerSettingsProvider.select((v) => v.value?.autoLocation ?? false),
  );
  return ready && !autoLocation;
}
