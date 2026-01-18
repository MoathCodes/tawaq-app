import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:free_map/free_map.dart';
import 'package:hasanat/core/hooks/hooks.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/utils/location_extensions.dart';
import 'package:hasanat/feature/settings/presentation/provider/location_provider.dart';
import 'package:hasanat/theme/theme.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Dialog for picking a location on a map.
class LocationPickerDialog extends HookConsumerWidget {
  /// Creates a new [LocationPickerDialog] instance.
  const LocationPickerDialog({
    required this.onLocationSelected,
    required this.style,
    required this.animation,
    super.key,
  });

  final FDialogStyle Function(FDialogStyle) style;
  final Animation<double> animation;
  final void Function(Coordinates coordinates, String locationName)
  onLocationSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapCtrl = useMapController();
    final colors = FTheme.of(context).colors;
    final loc = ref.watch(locationPickerProvider);
    final notifier = ref.read(locationPickerProvider.notifier);
    final l10n = context.l10n;

    return FDialog(
      animation: animation,
      style: style,
      direction: .horizontal,
      constraints: const BoxConstraints(maxWidth: 850),
      title: Text(
        l10n.chooseLocation,
        style: TextStyle(
          color: colors.foreground,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: Container(
        width: 800,
        height: 500,
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            _Header(
              colors: colors,
              notifier: notifier,
              loc: loc,
              mapCtrl: mapCtrl,
              searchPlaces: (q) => ref.read(searchPlacesProvider(q).future),
            ),
            Expanded(
              child: Row(
                children: [
                  _Map(
                    colors: colors,
                    loc: loc.coords.latLng,
                    notifier: notifier,
                    mapCtrl: mapCtrl,
                  ),
                  _CoordsPanel(colors: colors, loc: loc.coords.latLng),
                ],
              ),
            ),
            _Tip(colors: colors),
          ],
        ),
      ),
      actions: [
        FButton(
          style: FButtonStyle.secondary(),
          onPress: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FButton(
          onPress: () {
            onLocationSelected(loc.coords, loc.name);
            Navigator.of(context).pop();
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.colors,
    required this.notifier,
    required this.loc,
    required this.searchPlaces,
    required this.mapCtrl,
  });
  final FColors colors;
  final LocationPicker notifier;
  final ({Coordinates coords, String name}) loc;
  final Future<List<FmData>> Function(String) searchPlaces;
  final MapController mapCtrl;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const .all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.muted.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: .start,
        spacing: 12,
        children: [
          Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              Text(
                l10n.dragTheMapTip,
                style: TextStyle(color: colors.mutedForeground, fontSize: 14),
              ),
              FButton(
                onPress: () async {
                  try {
                    await notifier.useCurrentLocation(mapCtrl);
                  } catch (e) {
                    if (context.mounted) {
                      showFToast(
                        context: context,
                        title: Text(
                          l10n.errorOccurredWhile(l10n.gettingLocation),
                        ),
                        description: Text(e.toString()),
                      );
                    }
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [
                    const Icon(Icons.my_location, size: 16),
                    Text(l10n.useMyLocation),
                  ],
                ),
              ),
            ],
          ),
          FSelect<FmData>.searchBuilder(
            control: FSelectControl.managed(
              onChange: (p) async {
                if (p != null) {
                  await notifier.selectPlace(p);
                  mapCtrl.move(p.coordinates.latLng, 14);
                }
              },
            ),
            hint: loc.name,
            label: Text(l10n.searchPlaceLabel),
            format: (s) => s.name,
            filter: searchPlaces,
            contentBuilder: (_, _, data) => [
              for (final p in data)
                FSelectItem(
                  title: Text(p.name),
                  subtitle: Text(p.address),
                  value: p,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Map extends StatelessWidget {
  const _Map({
    required this.colors,
    required this.loc,
    required this.notifier,
    required this.mapCtrl,
  });
  final FColors colors;
  final LatLng loc;
  final LocationPicker notifier;
  final MapController mapCtrl;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Expanded(
      flex: 3,
      child: Container(
        margin: const .all(AppSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: FmMap(
            mapController: mapCtrl,
            mapOptions: MapOptions(
              initialCenter: loc,
              initialZoom: 12,
              minZoom: 2,
              maxZoom: 18,
              onTap: (_, ll) async {
                try {
                  await notifier.updateLocation(ll);
                  mapCtrl.move(ll, 14);
                } catch (_) {
                  if (context.mounted) {
                    showFToast(
                      context: context,
                      title: Text(l10n.errorUpdatingLocationTitle),
                      description: Text(l10n.errorUpdatingLocationDescription),
                    );
                  }
                }
              },
            ),
            markers: [
              Marker(
                point: loc,
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
      ),
    );
  }
}

class _CoordsPanel extends StatelessWidget {
  const _CoordsPanel({required this.colors, required this.loc});
  final FColors colors;
  final LatLng loc;

  Widget _field(String label, String value) => Column(
    crossAxisAlignment: .start,
    spacing: 4,
    children: [
      Text(
        label,
        style: TextStyle(
          color: colors.mutedForeground,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      Container(
        width: double.infinity,
        padding: const .symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: colors.border),
        ),
        child: Text(
          value,
          style: TextStyle(color: colors.foreground, fontSize: 13),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      width: 200,
      margin: const .only(top: 16, right: 16, bottom: 16),
      padding: const .all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.muted.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: .start,
        spacing: 16,
        children: [
          Row(
            children: [
              Icon(Icons.place_outlined, color: colors.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.coordinates,
                style: TextStyle(
                  color: colors.foreground,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          _field('${l10n.latitude}: ', loc.latitude.toStringAsFixed(5)),
          _field('${l10n.longitude}: ', loc.longitude.toStringAsFixed(5)),
        ],
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip({required this.colors});
  final FColors colors;

  @override
  Widget build(BuildContext context) => Container(
    padding: const .all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: colors.muted.withValues(alpha: 0.05),
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(12),
        bottomRight: Radius.circular(12),
      ),
    ),
    child: Row(
      children: [
        Icon(Icons.info_outline, color: colors.mutedForeground, size: 16),
        const SizedBox(width: AppSpacing.sm),
        Text(
          context.l10n.tipHoldCtrlToRotate,
          style: TextStyle(color: colors.mutedForeground, fontSize: 13),
        ),
      ],
    ),
  );
}
