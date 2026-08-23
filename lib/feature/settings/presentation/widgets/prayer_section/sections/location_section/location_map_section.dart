import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
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
import 'package:tawaq/feature/prayer/presentation/provider/prayer_settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/sections/location_section/location_controls.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_semantics.dart';
import 'package:tawaq/theme/theme.dart';

/// Map preview with coordinates summary and drag tip.
class LocationMapSection extends HookConsumerWidget {
  /// Creates [LocationMapSection].
  const new({
    this.compact = false,
    this.mapActive = true,
    super.key,
  });

  /// When true, uses a shorter map height (onboarding).
  final bool compact;

  /// When false, unmounts [FmMap] to release tiles/controllers (settings tab).
  final bool mapActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = manualLocationControlsEnabled(ref);
    final autoLocation = ref.watch(
      prayerSettingsProvider.select((v) => v.value?.autoLocation ?? false),
    );
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
              child: LocationMapContainer(
                compact: compact,
                mapActive: mapActive,
                enabled: enabled,
                autoLocation: autoLocation,
                coordinates: coordinates,
              ),
            ),
            SettingsSemantics.readOnlyValue(
              name: '${l10n.latitude}, ${l10n.longitude}',
              value: coordinatesText,
              child: LocationInfoRow(
                icon: Icons.place_outlined,
                text: coordinatesText,
              ),
            ),
            if (enabled)
              const LocationInfoRow(
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

/// Interactive map for picking coordinates.
class LocationMapContainer extends HookConsumerWidget {
  /// Creates [LocationMapContainer].
  const new({
    required this.enabled,
    required this.autoLocation,
    required this.coordinates,
    this.compact = false,
    this.mapActive = true,
    super.key,
  });

  /// When true, uses a shorter map height (onboarding).
  final bool compact;

  /// When false, keeps the map shell but does not build [FmMap].
  final bool mapActive;

  /// Whether manual map interaction is enabled.
  final bool enabled;

  /// Whether auto-location overlay should be shown.
  final bool autoLocation;

  /// Persisted coordinates (single watch owned by [LocationMapSection]).
  final Coordinates? coordinates;

  static const double _aspectRatio = 16 / 9;
  static const _maxHeight = 280.0;
  static const _compactMaxHeight = 180.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colors;
    final l10n = context.l10n;
    final mapController = useMapController();
    final optimisticCenter = useState<LatLng?>(null);
    final isLocating = useState(false);
    final pendingTap = useRef<LatLng?>(null);
    final displayCenter =
        optimisticCenter.value ?? coordinates?.latLng ?? kDefaultCenter;

    // Capture while mounted — never touch WidgetRef in dispose/cleanup.
    final settingsNotifierRef = useRef(
      ref.read(prayerSettingsProvider.notifier),
    );
    settingsNotifierRef.value = ref.read(prayerSettingsProvider.notifier);

    void flushPending() {
      final latlng = pendingTap.value;
      if (latlng == null) return;
      pendingTap.value = null;
      final errorAction = l10n.changingTimezone;
      unawaited(() async {
        try {
          await settingsNotifierRef.value.applyLocationBundle(
            coordinates: latlng.coordinates,
          );
        } catch (e) {
          if (context.mounted) showLocationError(context, errorAction, e);
        }
      }());
    }

    final debouncedPersist = useDebouncedCallback(flushPending);
    final cancelPersistRef = useRef(debouncedPersist.cancel);
    final flushPendingRef = useRef(flushPending);
    cancelPersistRef.value = debouncedPersist.cancel;
    flushPendingRef.value = flushPending;

    // Prefer flushing when the settings tab deactivates the map.
    useEffect(() {
      if (mapActive) return null;
      cancelPersistRef.value();
      flushPendingRef.value();
      return null;
    }, [mapActive]);

    useEffect(() {
      return () {
        cancelPersistRef.value();
        flushPendingRef.value();
      };
    }, const []);

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
      final coords = coordinates;
      if (!mapActive || coords == null || isLocating.value) return null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          try {
            mapController.move(coords.latLng, 16);
          } catch (_) {}
        }
      });
      return null;
    }, [mapActive, coordinates, isLocating.value]);

    Future<void> handleLocate() async {
      if (isLocating.value) return;
      isLocating.value = true;
      try {
        await settingsNotifierRef.value.applyCurrentDeviceLocation();
      } catch (e) {
        if (context.mounted) {
          showLocationError(context, l10n.gettingLocation, e);
        }
      } finally {
        if (context.mounted) isLocating.value = false;
      }
    }

    void handleTap(LatLng latlng) {
      optimisticCenter.value = latlng;
      mapController.move(latlng, 16);
      pendingTap.value = latlng;
      debouncedPersist();
    }

    final mapInteractive = enabled && !isLocating.value;
    final maxHeight = compact ? _compactMaxHeight : _maxHeight;

    return AbsorbPointer(
      absorbing: !mapInteractive || !mapActive,
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
                      if (mapActive)
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
                                    InteractiveFlag.all &
                                    ~InteractiveFlag.rotate,
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
                        )
                      else
                        ColoredBox(color: colors.secondary),
                      if (mapActive && enabled && !isLocating.value)
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
                                semanticsTooltip: l10n.useMyLocation,
                                variant: .secondary,
                                onPress: handleLocate,
                                child: const Icon(FLucideIcons.locate),
                              ),
                            ),
                          ),
                        ),
                      if (mapActive && (autoLocation || isLocating.value))
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

class LocationMapCenterOverlay extends StatelessWidget {
  const new({required this.autoLocation, super.key});

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
                ? const AutoLocationMessage()
                : const FCircularProgress.loader(),
          ),
        ),
      ),
    );
  }
}

class AutoLocationMessage extends StatelessWidget {
  const new({super.key});

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

class LocationInfoRow extends StatelessWidget {
  const new({
    required this.icon,
    this.text,
    this.iconSize = 16,
    this.fontSize = 13,
    super.key,
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
