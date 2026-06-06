import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:free_map/free_map.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/utils/text_extensions.dart';
import 'package:tawaq/feature/settings/domain/models/location_failure.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/theme.dart';

/// Default map center (Makkah).
const kDefaultCenter = LatLng(21.4362544, 39.6817387);

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

/// Shared empty state widget for search selects.
Widget buildEmptyContent(BuildContext context) => Padding(
  padding: const EdgeInsets.all(AppSpacing.sm),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    spacing: 8,
    children: [const Icon(FLucideIcons.searchX), Text(context.l10n.noResults).sm],
  ),
);

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
