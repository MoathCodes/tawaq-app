import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:free_map/free_map.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/layout/responsive_field_row.dart';
import 'package:tawaq/core/layout/viewport_dialog_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/utils/location_extensions.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/core/widgets/select_empty_content.dart';
import 'package:tawaq/feature/settings/data/location_constants.dart';
import 'package:tawaq/feature/settings/domain/models/location_failure.dart';
import 'package:tawaq/feature/settings/domain/services/timezone_catalog.dart';
import 'package:tawaq/feature/settings/presentation/provider/location_provider.dart';
import 'package:tawaq/feature/settings/presentation/provider/prayer_settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_semantics.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/theme.dart';
import 'package:timezone/timezone.dart' as tz;

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

/// City search and timezone controls in a responsive row.
class LocationControlsRow extends ConsumerWidget {
  /// Creates [LocationControlsRow].
  const LocationControlsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const NonSelectable(
      child: ResponsiveFieldRow(
        children: [
          CitySearchSelect(),
          TimezoneSelect(),
        ],
      ),
    );
  }
}

/// Place search select for manual location.
class CitySearchSelect extends ConsumerWidget {
  /// Creates [CitySearchSelect].
  const CitySearchSelect({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = manualLocationControlsEnabled(ref);
    final locationName = ref.watch(
      prayerSettingsProvider.select((v) => v.value?.locationName),
    );
    final l10n = context.l10n;
    final secondaryForeground = context.theme.colors.secondaryForeground;

    return FSelect<FmData>.searchBuilder(
      enabled: enabled,
      contentConstraints: selectPopoverPortalConstraints(context),
      control: .managed(
        onChange: (place) {
          if (place != null) {
            unawaited(
              ref
                  .read(prayerSettingsProvider.notifier)
                  .updateLocation(
                    coordinates: place.coordinates,
                    locationName: place.name,
                  ),
            );
          }
        },
      ),
      label: Text(l10n.searchPlaceLabel),
      hint: locationName == null
          ? l10n.searchForMore
          : resolveLocationDisplayName(l10n, locationName),
      format: (s) => s.name,
      filter: (query) => ref.read(searchPlacesProvider(query).future),
      prefixBuilder: (_, _, _) => Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Icon(
          FLucideIcons.search,
          color: secondaryForeground,
        ),
      ),
      contentBuilder: (_, _, data) => [
        for (final place in data)
          FSelectItem(
            title: Text(place.name),
            subtitle: Text(place.address),
            value: place,
          ),
      ],
      contentEmptyBuilder: (_, _) => buildSelectEmptyContent(context),
      contentLoadingBuilder: (_, _) => const FCircularProgress(),
    );
  }
}

/// Timezone select with system-timezone shortcut.
class TimezoneSelect extends ConsumerWidget {
  /// Creates [TimezoneSelect].
  const TimezoneSelect({super.key});

  Future<void> _setTimezone(
    BuildContext context,
    WidgetRef ref, [
    tz.Location? loc,
  ]) async {
    final errorAction = context.l10n.changingTimezone;
    try {
      await ref.read(prayerSettingsProvider.notifier).setSystemTimezone(loc);
    } catch (e) {
      if (context.mounted) showLocationError(context, errorAction, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = manualLocationControlsEnabled(ref);
    final location = ref.watch(
      prayerSettingsProvider.select((v) => v.value?.location),
    );
    final l10n = context.l10n;
    final colors = context.theme.colors;

    final locateButton = FTooltip(
      tipBuilder: (_, _) => Text(l10n.useSystemTimezone),
      child: SettingsSemantics.iconAction(
        label: SettingsSemantics.useSystemTimezoneAction(l10n),
        enabled: enabled,
        child: FButton.icon(
          variant: .ghost,
          onPress: enabled ? () => unawaited(_setTimezone(context, ref)) : null,
          child: const Icon(FLucideIcons.locate),
        ),
      ),
    );

    return FSelect<tz.Location>.searchBuilder(
      enabled: enabled,
      contentConstraints: selectPopoverPortalConstraints(context),
      control: .lifted(
        value: location,
        onChange: (v) {
          if (v != null) unawaited(_setTimezone(context, ref, v));
        },
      ),
      label: Text(l10n.timezone),
      format: (loc) => loc.name,
      searchFieldProperties: FSelectSearchFieldProperties(
        hint: l10n.searchForMore,
      ),
      prefixBuilder: (_, _, _) => Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Icon(
          FLucideIcons.clock,
          color: colors.secondaryForeground,
        ),
      ),
      filter: (query) async {
        final catalog = ref.read(timezoneCatalogProvider);
        final locations = location == null
            ? catalog
            : sortTimezones(locations: catalog, selected: location);
        return query.isEmpty
            ? locations
            : locations.where(
                (l) => l.name.toLowerCase().contains(query.toLowerCase()),
              );
      },
      contentBuilder: (_, _, data) => data
          .take(16)
          .map((l) => FSelectItem(title: Text(l.name), value: l))
          .toList(),
      contentEmptyBuilder: (_, _) => buildSelectEmptyContent(context),
      contentLoadingBuilder: (_, _) => const FCircularProgress(),
      suffixBuilder: (_, _, _) => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Icon(FLucideIcons.chevronDown, color: colors.primary),
          locateButton,
        ],
      ),
    );
  }
}

/// Manual latitude/longitude text fields.
class CoordinatesRow extends ConsumerWidget {
  /// Creates [CoordinatesRow].
  const CoordinatesRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coordinates = ref.watch(
      prayerSettingsProvider.select((v) => v.value?.coordinates),
    );
    if (coordinates == null) return const SizedBox.shrink();

    final l10n = context.l10n;
    return NonSelectable(
      child: ResponsiveFieldRow(
        maxColumns: 2,
        children: [
          _CoordinateField(
            isLatitude: true,
            label: l10n.latitude,
            min: -90,
            max: 90,
          ),
          _CoordinateField(
            isLatitude: false,
            label: l10n.longitude,
            min: -180,
            max: 180,
          ),
        ],
      ),
    );
  }
}

class _CoordinateField extends HookConsumerWidget {
  const _CoordinateField({
    required this.isLatitude,
    required this.label,
    required this.min,
    required this.max,
  });

  final bool isLatitude;
  final String label;
  final double min;
  final double max;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = manualLocationControlsEnabled(ref);
    final coordinates = ref.watch(
      prayerSettingsProvider.select((v) => v.value?.coordinates),
    );
    if (coordinates == null) return const SizedBox.shrink();

    final value = isLatitude
        ? coordinates.latitude.toStringAsFixed(7)
        : coordinates.longitude.toStringAsFixed(7);

    final controller = useTextEditingController(text: value);
    final focusNode = useFocusNode();

    useValueChanged<String, void>(value, (_, _) {
      if (!focusNode.hasFocus) controller.text = value;
      return;
    });

    useEffect(
      () {
        void onFocusChanged() {
          if (focusNode.hasFocus) return;
          final parsed = double.tryParse(controller.text);
          if (parsed == null) {
            controller.text = value;
            return;
          }
          final coords = ref.read(
            prayerSettingsProvider.select((s) => s.value?.coordinates),
          );
          if (coords == null) return;

          final newCoords = isLatitude
              ? Coordinates(parsed, coords.longitude)
              : Coordinates(coords.latitude, parsed);
          if (newCoords.latitude == coords.latitude &&
              newCoords.longitude == coords.longitude) {
            return;
          }
          unawaited(
            ref.read(prayerSettingsProvider.notifier).updateLocation(
              coordinates: newCoords,
            ),
          );
        }

        focusNode.addListener(onFocusChanged);
        return () => focusNode.removeListener(onFocusChanged);
      },
      [focusNode, controller, value, isLatitude],
    );

    return FTextField(
      enabled: enabled,
      focusNode: focusNode,
      control: .managed(
        controller: controller,
      ),
      label: Text(label),
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp('[0-9.-]')),
        _CoordinateRangeFormatter(min: min, max: max),
      ],
    );
  }
}

class _CoordinateRangeFormatter extends TextInputFormatter {
  const _CoordinateRangeFormatter({required this.min, required this.max});

  final double min;
  final double max;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty || text == '-' || text == '.') return newValue;

    final parsed = double.tryParse(text);
    return (parsed != null && parsed >= min && parsed <= max)
        ? newValue
        : oldValue;
  }
}
