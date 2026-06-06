import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:free_map/free_map.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/hooks/hooks.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/utils/location_extensions.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/widgets/location_helpers.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/widgets/use_location_tile.dart'
    show UseLocationTile;
import 'package:tawaq/feature/settings/presentation/widgets/settings_semantics.dart';
import 'package:tawaq/theme/theme.dart';

/// Interactive map section for selecting a location.
class LocationMapSection extends HookConsumerWidget {
  /// Creates a new [LocationMapSection] instance.
  const LocationMapSection({required this.enabled, super.key});

  /// Whether the map is interactive.
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoLocation = ref.watch(
      prayerSettingsProvider.select((v) => v.value?.autoLocation ?? false),
    );
    final coordinates = ref.watch(
      prayerSettingsProvider.select((v) => v.value?.coordinates),
    );
    final colors = FTheme.of(context).colors;
    final l10n = context.l10n;
    final mapController = useMapController();
    final optimisticCenter = useState<LatLng?>(null);
    final isLocating = useState(false);
    final displayCenter =
        optimisticCenter.value ?? coordinates?.latLng ?? kDefaultCenter;

    // Clear optimistic pin once persisted coordinates match.
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

    // Sync map position with coordinates (skip while locating to avoid jumps).
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

    void handleTap(LatLng latlng) {
      optimisticCenter.value = latlng;
      mapController.move(latlng, 16);
      final notifier = ref.read(prayerSettingsProvider.notifier)
        ..setCoordinates(latlng.coordinates);
      unawaited(
        notifier.updateLocationData(coordinates: latlng.coordinates),
      );
    }

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

    final mapLabel = enabled
        ? l10n.chooseLocation
        : l10n.autoLocationMapOverlay;

    return NonSelectable(
      child: Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          SettingsSemantics.labeledControl(
            name: mapLabel,
            enabled: enabled && !isLocating.value,
            excludeChild: true,
            child: AbsorbPointer(
            absorbing: !enabled || isLocating.value,
            child: LocationMapContainer(
              colors: colors,
              controller: mapController,
              center: displayCenter,
              enabled: enabled,
              autoLocation: autoLocation,
              isLocating: isLocating.value,
              onTap: handleTap,
              onLocate: handleLocate,
            ),
            ),
          ),
          SettingsSemantics.readOnlyValue(
            name: '${l10n.latitude}, ${l10n.longitude}',
            value:
                '${coordinates?.latitude.toStringAsFixed(5) ?? l10n.unavailableShort}, '
                '${coordinates?.longitude.toStringAsFixed(5) ?? l10n.unavailableShort}',
            child: InfoRow(
              icon: Icons.place_outlined,
              text:
                  '${coordinates?.latitude.toStringAsFixed(5) ?? l10n.unavailableShort}, '
                  '${coordinates?.longitude.toStringAsFixed(5) ?? l10n.unavailableShort}',
            ),
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
    required this.autoLocation,
    required this.isLocating,
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

  /// Whether manual map interaction is allowed.
  final bool enabled;

  /// Whether automatic location is enabled via [UseLocationTile].
  final bool autoLocation;

  /// Whether a locate request is in progress.
  final bool isLocating;

  /// Called when the user taps on the map.
  final void Function(LatLng) onTap;

  /// Called when the user taps the locate button.
  final VoidCallback onLocate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
            SettingsSemantics.decorative(
              FmMap(
              mapController: controller,
              mapOptions: MapOptions(
                initialCenter: center,
                initialZoom: 16,
                minZoom: 2,
                maxZoom: 18,
                onTap: enabled ? (_, latlng) => onTap(latlng) : null,
                interactionOptions: InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  cursorKeyboardRotationOptions:
                      CursorKeyboardRotationOptions.disabled(),
                ),
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
            ),
            if (enabled && !isLocating)
              Positioned(
                top: 12,
                left: 12,
                child: FTooltip(
                  tipBuilder: (_, _) => Text(l10n.useMyLocation),
                  child: SettingsSemantics.iconAction(
                    label: SettingsSemantics.useMyLocationAction(l10n),
                    child: FButton.icon(
                      variant: .secondary,
                      onPress: onLocate,
                      child: const Icon(FLucideIcons.locate),
                    ),
                  ),
                ),
              ),
            if (autoLocation || isLocating)
              LocationMapCenterOverlay(
                colors: colors,
                autoLocation: autoLocation,
              ),
          ],
        ),
      ),
    );
  }
}

/// Center overlay for auto-location info or locate-in-progress feedback.
class LocationMapCenterOverlay extends StatelessWidget {
  /// Creates a [LocationMapCenterOverlay].
  const LocationMapCenterOverlay({
    required this.colors,
    required this.autoLocation,
    super.key,
  });

  /// Theme colors.
  final FColors colors;

  /// Whether automatic location is active.
  final bool autoLocation;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: colors.barrier.withValues(alpha: autoLocation ? 0.55 : 0.35),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: autoLocation
                ? _AutoLocationMessage(colors: colors)
                : const FCircularProgress.loader(),
          ),
        ),
      ),
    );
  }
}

class _AutoLocationMessage extends StatelessWidget {
  const _AutoLocationMessage({required this.colors});

  final FColors colors;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final typography = FTheme.of(context).typography;
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.sm,
      children: [
        Icon(FLucideIcons.locate, size: 28, color: colors.primary),
        Text(
          l10n.autoLocationMapOverlay,
          textAlign: TextAlign.center,
          style: typography.sm.copyWith(color: colors.foreground),
        ),
      ],
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
    final l10n = context.l10n;
    final color = FTheme.of(context).colors.mutedForeground;
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
