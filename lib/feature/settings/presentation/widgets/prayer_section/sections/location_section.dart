import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:free_map/free_map.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/hooks/hooks.dart';
import 'package:tawaq/core/layout/responsive.dart';
import 'package:tawaq/core/layout/responsive_field_row.dart';
import 'package:tawaq/core/layout/viewport_dialog_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/utils/location_extensions.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/core/widgets/select_empty_content.dart';
import 'package:tawaq/feature/settings/data/location_constants.dart';
import 'package:tawaq/feature/settings/domain/models/location_failure.dart';
import 'package:tawaq/feature/settings/presentation/provider/location_provider.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_section.dart';
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

/// Prayer location controls with optional settings section chrome.
class PrayerLocationSettings extends ConsumerWidget {
  /// Creates [PrayerLocationSettings].
  const PrayerLocationSettings({
    this.chrome = SettingsChrome.section,
    this.compactMap = false,
    super.key,
  });

  /// Outer card chrome for the settings screen.
  final SettingsChrome chrome;

  /// When true, uses a shorter map height (onboarding).
  final bool compactMap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.lg,
      children: [
        const _UseLocationTile(),
        const FDivider(),
        const _LocationControlsRow(),
        const FDivider(),
        _LocationMapSection(compact: compactMap),
        const FDivider(),
        const _CoordinatesRow(),
      ],
    );

    if (chrome == SettingsChrome.none) return content;

    final l10n = context.l10n;
    return SettingsSection(
      crossAxisAlignment: CrossAxisAlignment.center,
      title: l10n.locationSectionTitle,
      subtitle: l10n.locationSectionSubtitle,
      child: content,
    );
  }
}

class _UseLocationTile extends ConsumerWidget {
  const _UseLocationTile();

  Future<void> _onToggle(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    final notifier = ref.read(prayerSettingsProvider.notifier)
      ..setAutoLocation(value: value);
    if (!value) return;

    final errorAction = context.l10n.gettingLocation;
    try {
      await notifier.useCurrentLocation();
      await notifier.setSystemTimezone();
    } catch (e) {
      if (context.mounted) showLocationError(context, errorAction, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoLocation = ref.watch(
      prayerSettingsProvider.select((v) => v.value?.autoLocation ?? false),
    );
    final prayerSettingsReady = ref.watch(
      prayerSettingsProvider.select((v) => v.hasValue),
    );
    final colors = FTheme.of(context).colors;
    final l10n = context.l10n;

    return NonSelectable(
      child: FTile(
        prefix: SettingsSemantics.decorative(
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(FLucideIcons.locate, color: colors.primary),
          ),
        ),
        title: Text(l10n.useMyLocation),
        subtitle: Text(
          autoLocation
              ? l10n.autoLocationEnabled
              : l10n.autoLocationDisabled,
        ),
        suffix: FSwitch(
          enabled: prayerSettingsReady,
          value: autoLocation,
          onChange: (v) => _onToggle(context, ref, v),
        ),
      ),
    );
  }
}

class _LocationControlsRow extends ConsumerWidget {
  const _LocationControlsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const NonSelectable(
      child: ResponsiveFieldRow(
        children: [
          _CitySearchSelect(),
          _TimezoneSelect(),
        ],
      ),
    );
  }
}

class _CitySearchSelect extends ConsumerWidget {
  const _CitySearchSelect();

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

class _TimezoneSelect extends ConsumerWidget {
  const _TimezoneSelect();

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
        final locations = ref.read(loadTimezonesProvider);
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

class _LocationMapSection extends HookConsumerWidget {
  const _LocationMapSection({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = manualLocationControlsEnabled(ref);
    final coordinates = ref.watch(
      prayerSettingsProvider.select((v) => v.value?.coordinates),
    );
    final l10n = context.l10n;
    final mapLabel = enabled
        ? l10n.chooseLocation
        : l10n.autoLocationMapOverlay;

    final coordinatesText =
        '${coordinates?.latitude.toStringAsFixed(5) ?? l10n.unavailableShort}, '
        '${coordinates?.longitude.toStringAsFixed(5) ?? l10n.unavailableShort}';

    return NonSelectable(
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            SettingsSemantics.labeledControl(
              name: mapLabel,
              enabled: enabled,
              excludeChild: true,
              child: _LocationMapContainer(compact: compact),
            ),
            SettingsSemantics.readOnlyValue(
              name: '${l10n.latitude}, ${l10n.longitude}',
              value: coordinatesText,
              child: _InfoRow(
                icon: Icons.place_outlined,
                text: coordinatesText,
              ),
            ),
            if (enabled)
              const _InfoRow(
                icon: Icons.info_outline,
                iconSize: 14,
                fontSize: 12,
              ),
          ],
        ),
      ),
    );
  }
}

class _LocationMapContainer extends HookConsumerWidget {
  const _LocationMapContainer({this.compact = false});

  final bool compact;

  static const double _aspectRatio = 16 / 9;
  static const _maxHeight = 280.0;
  static const _compactMaxHeight = 180.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = manualLocationControlsEnabled(ref);
    final autoLocation = ref.watch(
      prayerSettingsProvider.select((v) => v.value?.autoLocation ?? false),
    );
    final coordinates = ref.watch(
      prayerSettingsProvider.select((v) => v.value?.coordinates),
    );
    final colors = context.theme.colors;
    final l10n = context.l10n;
    final mapController = useMapController();
    final optimisticCenter = useState<LatLng?>(null);
    final isLocating = useState(false);
    final displayCenter =
        optimisticCenter.value ?? coordinates?.latLng ?? kDefaultCenter;

    useEffect(() {
      final optimistic = optimisticCenter.value;
      final persisted = coordinates?.latLng;
      if (optimistic != null &&
          persisted != null &&
          optimistic.latitude == persisted.latitude &&
          optimistic.longitude == persisted.longitude) {
        optimisticCenter.value = null;
      }
      return null;
    }, [coordinates, optimisticCenter.value]);

    useEffect(() {
      if (coordinates == null || isLocating.value) return null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          try {
            mapController.move(coordinates.latLng, 16);
          } catch (_) {}
        }
      });
      return null;
    }, [coordinates, isLocating.value]);

    Future<void> handleLocate() async {
      if (isLocating.value) return;
      isLocating.value = true;
      final errorAction = l10n.gettingLocation;
      try {
        await ref.read(prayerSettingsProvider.notifier).useCurrentLocation();
      } catch (e) {
        if (context.mounted) showLocationError(context, errorAction, e);
      } finally {
        if (context.mounted) isLocating.value = false;
      }
    }

    void handleTap(LatLng latlng) {
      optimisticCenter.value = latlng;
      mapController.move(latlng, 16);
      unawaited(
        ref.read(prayerSettingsProvider.notifier).updateLocation(
          coordinates: latlng.coordinates,
        ),
      );
    }

    final mapInteractive = enabled && !isLocating.value;
    final maxHeight = compact ? _compactMaxHeight : _maxHeight;

    return AbsorbPointer(
      absorbing: !mapInteractive,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final height = responsiveValueForWidth<double>(
            context,
            constraints.maxWidth,
            belowSm: maxHeight * 0.85,
            sm: maxHeight,
          ).clamp(120.0, maxHeight);

          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: height),
            child: AspectRatio(
              aspectRatio: _aspectRatio,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      SettingsSemantics.decorative(
                        FmMap(
                          mapController: mapController,
                          mapOptions: MapOptions(
                            initialCenter: displayCenter,
                            initialZoom: 16,
                            minZoom: 2,
                            maxZoom: 18,
                            onTap: mapInteractive
                                ? (_, latlng) => handleTap(latlng)
                                : null,
                            interactionOptions: InteractionOptions(
                              flags:
                                  InteractiveFlag.all & ~InteractiveFlag.rotate,
                              cursorKeyboardRotationOptions:
                                  CursorKeyboardRotationOptions.disabled(),
                            ),
                          ),
                          markers: [
                            Marker(
                              point: displayCenter,
                              width: 40,
                              height: 40,
                              child: Icon(
                                Icons.location_on,
                                size: 40,
                                color: colors.destructive,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (enabled && !isLocating.value)
                        Positioned(
                          top: 12,
                          left: 12,
                          child: FTooltip(
                            tipBuilder: (_, _) => Text(l10n.useMyLocation),
                            child: SettingsSemantics.iconAction(
                              label: SettingsSemantics.useMyLocationAction(
                                l10n,
                              ),
                              child: FButton.icon(
                                variant: .secondary,
                                onPress: handleLocate,
                                child: const Icon(FLucideIcons.locate),
                              ),
                            ),
                          ),
                        ),
                      if (autoLocation || isLocating.value)
                        _LocationMapCenterOverlay(autoLocation: autoLocation),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LocationMapCenterOverlay extends StatelessWidget {
  const _LocationMapCenterOverlay({required this.autoLocation});

  final bool autoLocation;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return Positioned.fill(
      child: ColoredBox(
        color: colors.barrier.withValues(alpha: autoLocation ? 0.55 : 0.35),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: autoLocation
                ? const _AutoLocationMessage()
                : const FCircularProgress.loader(),
          ),
        ),
      ),
    );
  }
}

class _AutoLocationMessage extends StatelessWidget {
  const _AutoLocationMessage();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;
    final colors = theme.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.sm,
      children: [
        Icon(FLucideIcons.locate, size: 28, color: colors.primary),
        Text(
          l10n.autoLocationMapOverlay,
          textAlign: TextAlign.center,
          style: theme.typography.body.sm.copyWith(color: colors.foreground),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    this.text,
    this.iconSize = 16,
    this.fontSize = 13,
  });

  final IconData icon;
  final String? text;
  final double iconSize;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final color = context.theme.colors.mutedForeground;
    return Row(
      spacing: 8,
      children: [
        SettingsSemantics.decorative(
          Icon(icon, color: color, size: iconSize),
        ),
        Expanded(
          child: Text(
            text ?? l10n.dragTheMapTip,
            style: TextStyle(color: color, fontSize: fontSize),
          ),
        ),
      ],
    );
  }
}

class _CoordinatesRow extends ConsumerWidget {
  const _CoordinatesRow();

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
