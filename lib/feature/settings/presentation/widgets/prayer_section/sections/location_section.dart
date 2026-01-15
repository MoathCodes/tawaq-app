import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:free_map/free_map.dart';
import 'package:hasanat/core/hooks/hooks.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/utils/location_extensions.dart';
import 'package:hasanat/core/utils/text_extensions.dart';
import 'package:hasanat/feature/settings/presentation/provider/location_provider.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/feature/settings/presentation/widgets/settings_section.dart';
import 'package:hasanat/theme/theme.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

// =============================================================================
// Constants & Helpers
// =============================================================================

const _kDefaultCenter = LatLng(21.4362544, 39.6817387);

/// Shared empty state widget for search selects.
Widget _buildEmptyContent(BuildContext context) => Padding(
  padding: const EdgeInsets.all(AppSpacing.sm),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    spacing: 8,
    children: [const Icon(FIcons.searchX), Text(context.l10n.noResults).sm],
  ),
);

/// Shows a location error toast.
void _showLocationError(BuildContext context, String action, Object error) {
  if (!context.mounted) return;
  showFToast(
    context: context,
    title: Text(context.l10n.errorOccurredWhile(action)),
    description: Text(error.toString()),
  );
}

// =============================================================================
// Main Section
// =============================================================================

/// Widget for the prayer location settings section with inline map.
class PrayerSettingsLocationSection extends ConsumerWidget {
  /// Creates a new [PrayerSettingsLocationSection] instance.
  const PrayerSettingsLocationSection({required this.maxWidth, super.key});

  /// The maximum width of the section.
  final double maxWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoLocation = ref.watch(
      prayerSettingsProvider.select((v) => v.value?.autoLocation ?? false),
    );
    final enabled = !autoLocation;

    return SettingsSection(
      crossAxisAlignment: .center,
      title: context.l10n.locationSectionTitle,
      subtitle: context.l10n.locationSectionSubtitle,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: FCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              const _UseLocationTile(),
              const FDivider(),
              _MapSection(enabled: enabled),
              const FDivider(),
              _CoordinatesRow(enabled: enabled),
              const FDivider(),
              _ControlsRow(enabled: enabled),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Use Location Toggle
// =============================================================================

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
      if (context.mounted) _showLocationError(context, errorAction, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoLocation = ref.watch(
      prayerSettingsProvider.select((v) => v.value?.autoLocation ?? false),
    );
    final colors = FTheme.of(context).colors;

    return FTile(
      prefix: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(FIcons.locate, color: colors.primary),
      ),
      title: Text(context.l10n.useMyLocation),
      subtitle: Text(
        autoLocation
            ? context.l10n.autoLocationEnabled
            : context.l10n.autoLocationDisabled,
      ),
      suffix: FSwitch(
        value: autoLocation,
        onChange: (v) => _onToggle(context, ref, v),
      ),
    );
  }
}

// =============================================================================
// Coordinates Input Row
// =============================================================================

class _CoordinatesRow extends ConsumerWidget {
  const _CoordinatesRow({required this.enabled});
  final bool enabled;

  void _updateCoordinate(
    WidgetRef ref,
    Coordinates coords,
    String value,
    bool isLat,
  ) {
    final parsed = double.tryParse(value);
    if (parsed == null) return;

    final newCoords = isLat
        ? Coordinates(parsed, coords.longitude)
        : Coordinates(coords.latitude, parsed);
    ref.read(prayerSettingsProvider.notifier).setCoordinates(newCoords);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coordinates = ref.watch(
      prayerSettingsProvider.select((v) => v.value?.coordinates),
    );
    if (coordinates == null) return const SizedBox.shrink();

    return Row(
      spacing: 12,
      children: [
        Expanded(
          child: _CoordinateField(
            enabled: enabled,
            label: context.l10n.latitude,
            value: coordinates.latitude.toStringAsFixed(7),
            min: -90,
            max: 90,
            onChanged: (v) => _updateCoordinate(ref, coordinates, v, true),
          ),
        ),
        Expanded(
          child: _CoordinateField(
            enabled: enabled,
            label: context.l10n.longitude,
            value: coordinates.longitude.toStringAsFixed(7),
            min: -180,
            max: 180,
            onChanged: (v) => _updateCoordinate(ref, coordinates, v, false),
          ),
        ),
      ],
    );
  }
}

class _CoordinateField extends HookWidget {
  const _CoordinateField({
    required this.enabled,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final bool enabled;
  final String label;
  final String value;
  final double min;
  final double max;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController(text: value);
    final focusNode = useFocusNode();
    final isFocused = useListenableSelector(
      focusNode,
      () => focusNode.hasFocus,
    );

    // Sync external value only when not focused
    useEffect(() {
      if (!isFocused && controller.text != value) controller.text = value;
      return null;
    }, [value, isFocused]);

    return FTextField(
      enabled: enabled,
      focusNode: focusNode,
      control: .managed(
        controller: controller,
        onChange: (v) async {
          if (v.text != value) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => onChanged(v.text),
            );
          }
        },
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

/// Input formatter that validates coordinate ranges.
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

    final value = double.tryParse(text);
    return (value != null && value >= min && value <= max)
        ? newValue
        : oldValue;
  }
}

// =============================================================================
// Map Section
// =============================================================================

class _MapSection extends HookConsumerWidget {
  const _MapSection({required this.enabled});
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coordinates = ref.watch(
      prayerSettingsProvider.select((v) => v.value?.coordinates),
    );
    final colors = FTheme.of(context).colors;
    final mapController = useMapController();
    final center = coordinates?.latLng ?? _kDefaultCenter;

    // Sync map position with coordinates
    useEffect(() {
      if (coordinates == null) return null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          try {
            mapController.move(coordinates.latLng, 15);
          } catch (_) {}
        }
      });
      return null;
    }, [coordinates]);

    Future<void> handleTap(LatLng latlng) async {
      final notifier = ref.read(prayerSettingsProvider.notifier)
        ..setCoordinates(latlng.coordinates);
      mapController.move(latlng, 14);
      try {
        await notifier.updateLocationData(coordinates: latlng.coordinates);
      } catch (_) {}
    }

    Future<void> handleLocate() async {
      final errorAction = context.l10n.gettingLocation;
      try {
        await ref.read(prayerSettingsProvider.notifier).useCurrentLocation();
      } catch (e) {
        if (context.mounted) _showLocationError(context, errorAction, e);
      }
    }

    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            _MapContainer(
              colors: colors,
              controller: mapController,
              center: center,
              enabled: enabled,
              onTap: handleTap,
              onLocate: handleLocate,
            ),
            _InfoRow(
              icon: Icons.place_outlined,
              text:
                  '${coordinates?.latitude.toStringAsFixed(5) ?? '—'}, '
                  '${coordinates?.longitude.toStringAsFixed(5) ?? '—'}',
            ),
            if (enabled)
              _InfoRow(
                icon: Icons.info_outline,
                iconSize: 14,
                text: context.l10n.tipHoldCtrlToRotate,
                fontSize: 12,
              ),
          ],
        ),
      ),
    );
  }
}

class _MapContainer extends StatelessWidget {
  const _MapContainer({
    required this.colors,
    required this.controller,
    required this.center,
    required this.enabled,
    required this.onTap,
    required this.onLocate,
  });

  final FColors colors;
  final MapController controller;
  final LatLng center;
  final bool enabled;
  final Future<void> Function(LatLng) onTap;
  final VoidCallback onLocate;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            FmMap(
              mapController: controller,
              mapOptions: MapOptions(
                initialCenter: center,
                initialZoom: 12,
                minZoom: 2,
                maxZoom: 18,
                onTap: enabled ? (_, latlng) => onTap(latlng) : null,
              ),
              markers: [
                Marker(
                  point: center,
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
            if (enabled)
              Positioned(
                top: 12,
                left: 12,
                child: FTooltip(
                  tipBuilder: (_, _) => Text(context.l10n.useMyLocation),
                  child: FButton.icon(
                    style: FButtonStyle.secondary(),
                    onPress: onLocate,
                    child: const Icon(FIcons.locate),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
    this.iconSize = 16,
    this.fontSize = 13,
  });

  final IconData icon;
  final String text;
  final double iconSize;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final color = FTheme.of(context).colors.mutedForeground;
    return Row(
      children: [
        Icon(icon, color: color, size: iconSize),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: color, fontSize: fontSize),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Controls Row (City Search & Timezone)
// =============================================================================

class _ControlsRow extends ConsumerWidget {
  const _ControlsRow({required this.enabled});
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final children = [
          _CitySearch(enabled: enabled),
          _TimezoneSelector(enabled: enabled),
        ];

        return constraints.maxWidth > 500
            ? Row(
                spacing: 12,
                children: children.map((c) => Expanded(child: c)).toList(),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: children,
              );
      },
    );
  }
}

class _CitySearch extends ConsumerWidget {
  const _CitySearch({required this.enabled});
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationName = ref.watch(
      prayerSettingsProvider.select((v) => v.value?.locationName),
    );

    return FSelect<FmData>.searchBuilder(
      enabled: enabled,
      control: .managed(
        onChange: (place) {
          if (place != null) {
            unawaited(
              ref
                  .read(prayerSettingsProvider.notifier)
                  .updateLocationData(
                    coordinates: place.coordinates,
                    locationName: place.name,
                  ),
            );
          }
        },
      ),
      label: Text(context.l10n.searchPlaceLabel),
      hint: locationName ?? context.l10n.searchForMore,
      format: (s) => s.name,
      filter: (query) => ref.read(searchPlacesProvider(query).future),
      prefixBuilder: (_, _, _) => Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Icon(
          FIcons.search,
          color: context.theme.colors.secondaryForeground,
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
      contentEmptyBuilder: (_, _) => _buildEmptyContent(context),
      contentLoadingBuilder: (_, _) => const FCircularProgress(),
    );
  }
}

class _TimezoneSelector extends ConsumerWidget {
  const _TimezoneSelector({required this.enabled});
  final bool enabled;

  Future<void> _setTimezone(
    BuildContext context,
    WidgetRef ref, [
    tz.Location? loc,
  ]) async {
    final errorAction = context.l10n.changingTimezone;
    try {
      await ref.read(prayerSettingsProvider.notifier).setSystemTimezone(loc);
    } catch (e) {
      if (context.mounted) _showLocationError(context, errorAction, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(
      prayerSettingsProvider.select((v) => v.value?.location),
    );

    return FSelect<tz.Location>.searchBuilder(
      enabled: enabled,
      control: .lifted(
        value: location,
        onChange: (v) {
          if (v != null) unawaited(_setTimezone(context, ref, v));
        },
      ),
      label: Text(context.l10n.timezone),
      format: (loc) => loc.name,
      searchFieldProperties: FSelectSearchFieldProperties(
        hint: context.l10n.searchForMore,
      ),
      prefixBuilder: (_, _, _) => Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Icon(
          FIcons.clock,
          color: context.theme.colors.secondaryForeground,
        ),
      ),
      filter: (query) async {
        final locations = await ref.read(loadTimezonesProvider.future);
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
      contentEmptyBuilder: (_, _) => _buildEmptyContent(context),
      contentLoadingBuilder: (_, _) => const FCircularProgress(),
      suffixBuilder: (_, _, _) => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Icon(FIcons.chevronDown, color: context.theme.colors.primary),
          FTooltip(
            tipBuilder: (_, _) => Text(context.l10n.useSystemTimezone),
            child: FButton.icon(
              style: FButtonStyle.ghost(),
              onPress: () => unawaited(_setTimezone(context, ref)),
              child: const Icon(FIcons.locate),
            ),
          ),
        ],
      ),
    );
  }
}
