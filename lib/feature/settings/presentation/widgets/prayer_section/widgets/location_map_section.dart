import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:free_map/free_map.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/hooks/hooks.dart';
import 'package:tawaq/core/layout/responsive.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/utils/location_extensions.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/widgets/location_controls_row.dart'
    show manualLocationControlsEnabled;
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/widgets/location_helpers.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_semantics.dart';
import 'package:tawaq/theme/theme.dart';

/// Interactive map section for selecting a location.
class LocationMapSection extends HookConsumerWidget {
  /// Creates a new [LocationMapSection] instance.
  const LocationMapSection({this.compact = false, super.key});

  /// When true, uses a shorter map height for embedded layouts (onboarding).
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
              child: LocationMapContainer(compact: compact),
            ),
            SettingsSemantics.readOnlyValue(
              name: '${l10n.latitude}, ${l10n.longitude}',
              value: coordinatesText,
              child: InfoRow(
                icon: Icons.place_outlined,
                text: coordinatesText,
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
class LocationMapContainer extends HookConsumerWidget {
  /// Creates a new [LocationMapContainer] instance.
  const LocationMapContainer({this.compact = false, super.key});

  /// When true, clamps the map to a shorter max height.
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
                        LocationMapCenterOverlay(autoLocation: autoLocation),
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

/// Center overlay for auto-location info or locate-in-progress feedback.
class LocationMapCenterOverlay extends StatelessWidget {
  /// Creates a [LocationMapCenterOverlay].
  const LocationMapCenterOverlay({
    required this.autoLocation,
    super.key,
  });

  /// Whether automatic location is active.
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
