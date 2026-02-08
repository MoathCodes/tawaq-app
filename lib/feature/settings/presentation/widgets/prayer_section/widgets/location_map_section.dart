import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:free_map/free_map.dart';
import 'package:hasanat/core/hooks/hooks.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/utils/location_extensions.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/feature/settings/presentation/widgets/prayer_section/widgets/location_helpers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Interactive map section for selecting a location.
class LocationMapSection extends HookConsumerWidget {
  /// Creates a new [LocationMapSection] instance.
  const LocationMapSection({required this.enabled, super.key});

  /// Whether the map is interactive.
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coordinates = ref.watch(
      prayerSettingsProvider.select((v) => v.value?.coordinates),
    );
    final colors = FTheme.of(context).colors;
    final mapController = useMapController();
    final center = coordinates?.latLng ?? kDefaultCenter;

    // Sync map position with coordinates
    useEffect(() {
      if (coordinates == null) return null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          try {
            mapController.move(coordinates.latLng, 12);
          } catch (_) {}
        }
      });
      return null;
    }, [coordinates]);

    Future<void> handleTap(LatLng latlng) async {
      final notifier = ref.read(prayerSettingsProvider.notifier)
        ..setCoordinates(latlng.coordinates);
      mapController.move(latlng, 12);
      try {
        await notifier.updateLocationData(coordinates: latlng.coordinates);
      } catch (_) {}
    }

    Future<void> handleLocate() async {
      final errorAction = context.l10n.gettingLocation;
      try {
        await ref.read(prayerSettingsProvider.notifier).useCurrentLocation();
      } catch (e) {
        if (context.mounted) showLocationError(context, errorAction, e);
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
            LocationMapContainer(
              colors: colors,
              controller: mapController,
              center: center,
              enabled: enabled,
              onTap: handleTap,
              onLocate: handleLocate,
            ),
            InfoRow(
              icon: Icons.place_outlined,
              text:
                  '${coordinates?.latitude.toStringAsFixed(5) ?? '—'}, '
                  '${coordinates?.longitude.toStringAsFixed(5) ?? '—'}',
            ),
            if (enabled)
              const InfoRow(
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

/// The map container with marker and locate button.
class LocationMapContainer extends StatelessWidget {
  /// Creates a new [LocationMapContainer] instance.
  const LocationMapContainer({
    required this.colors,
    required this.controller,
    required this.center,
    required this.enabled,
    required this.onTap,
    required this.onLocate,
    super.key,
  });

  /// Theme colors.
  final FColors colors;

  /// The map controller.
  final MapController controller;

  /// The center point of the map / marker position.
  final LatLng center;

  /// Whether the map is interactive.
  final bool enabled;

  /// Called when the user taps on the map.
  final Future<void> Function(LatLng) onTap;

  /// Called when the user taps the locate button.
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
                initialZoom: 10,
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

/// A small icon + text row used for coordinate display or tips.
class InfoRow extends StatelessWidget {
  /// Creates a new [InfoRow] instance.
  const InfoRow({
    required this.icon,
    this.text,
    this.iconSize = 16,
    this.fontSize = 13,
    super.key,
  });

  /// The leading icon.
  final IconData icon;

  /// The text to display. If null, uses the tip localization.
  final String? text;

  /// The icon size.
  final double iconSize;

  /// The font size.
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
            text ?? context.l10n.tipHoldCtrlToRotate,
            style: TextStyle(color: color, fontSize: fontSize),
          ),
        ),
      ],
    );
  }
}
