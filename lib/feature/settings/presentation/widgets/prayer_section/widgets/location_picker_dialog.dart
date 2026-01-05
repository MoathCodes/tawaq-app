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

  /// The style of the dialog.
  final FDialogStyle Function(FDialogStyle) style;

  /// The animation of the dialog.
  final Animation<double> animation;

  /// Callback when a location is selected.
  final void Function(Coordinates coordinates, String locationName)
  onLocationSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapController = useMapController();
    final theme = FTheme.of(context);
    final colors = theme.colors;

    final selectedLocation = ref.watch(locationPickerProvider);
    final notifierController = ref.read(locationPickerProvider.notifier);
    Future<List<FmData>> searchPlaces(String query) =>
        ref.read(searchPlacesProvider(query).future);
    return FDialog(
      animation: animation,
      style: style,
      direction: Axis.horizontal,
      constraints: const BoxConstraints(maxWidth: 850),
      title: Text(
        context.l10n.chooseLocation,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(
              context,
              colors,
              notifierController,
              selectedLocation,
              searchPlaces,
              mapController,
            ),
            _buildMapSection(
              context,
              colors,
              selectedLocation,
              notifierController,
              mapController,
            ),
            _buildTipSection(context, colors),
          ],
        ),
      ),
      actions: [
        FButton(
          style: FButtonStyle.secondary(),
          onPress: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancel),
        ),
        FButton(
          onPress: () async {
            onLocationSelected(selectedLocation.coords, selectedLocation.name);

            Navigator.of(context).pop();
          },
          child: Text(context.l10n.save),
        ),
      ],
    );
  }

  Widget _buildCoordinateField({
    required String label,
    required String value,
    required FColors colors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
  }

  Widget _buildCoordinatesPanel(
    BuildContext context,
    FColors colors,
    LatLng selectedLocation,
  ) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(top: 16, right: 16, bottom: 16),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.muted.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          Row(
            children: [
              Icon(Icons.place_outlined, color: colors.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                context.l10n.coordinates,
                style: TextStyle(
                  color: colors.foreground,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          _buildCoordinateField(
            label: '${context.l10n.latitude}: ',
            value: selectedLocation.latitude.toStringAsFixed(5),
            colors: colors,
          ),
          _buildCoordinateField(
            label: '${context.l10n.longitude}: ',
            value: selectedLocation.longitude.toStringAsFixed(5),
            colors: colors,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    FColors colors,
    LocationPicker notifierController,
    ({Coordinates coords, String name}) selectedLocation,
    Future<List<FmData>> Function(String) searchPlaces,
    MapController mapController,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.muted.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.dragTheMapTip,
                style: TextStyle(color: colors.mutedForeground, fontSize: 14),
              ),
              FButton(
                onPress: () async {
                  try {
                    notifierController.useCurrentLocation(mapController);
                  } catch (e) {
                    // Show error snackbar
                    if (context.mounted) {
                      showFToast(
                        context: context,
                        title: Text(
                          context.l10n.errorOccurredWhile(
                            context.l10n.gettingLocation,
                          ),
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
                    Text(context.l10n.useMyLocation),
                  ],
                ),
              ),
            ],
          ),
          _buildSearchField(
            context,
            selectedLocation,
            notifierController,
            searchPlaces,
            mapController,
          ),
        ],
      ),
    );
  }

  Widget _buildMap(
    BuildContext context,
    FColors colors,
    LatLng selectedLocation,
    LocationPicker notifierController,
    MapController mapController,
  ) {
    return Expanded(
      flex: 3,
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: FmMap(
            mapController: mapController,
            mapOptions: MapOptions(
              initialCenter: selectedLocation,
              initialZoom: 12,
              minZoom: 2,
              maxZoom: 18,
              onTap: (tapPos, latlng) {
                try {
                  notifierController.updateLocation(latlng);
                  mapController.move(latlng, 14);
                } catch (e) {
                  if (context.mounted) {
                    showFToast(
                      context: context,
                      title: Text(context.l10n.errorUpdatingLocationTitle),
                      description: Text(
                        context.l10n.errorUpdatingLocationDescription,
                      ),
                    );
                  }
                }
              },
            ),
            markers: [
              Marker(
                point: selectedLocation,
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

  Widget _buildMapSection(
    BuildContext context,
    FColors colors,
    ({Coordinates coords, String name}) selectedLocation,
    LocationPicker notifierController,
    MapController mapController,
  ) {
    return Expanded(
      child: Row(
        children: [
          _buildMap(
            context,
            colors,
            selectedLocation.coords.latLng,
            notifierController,
            mapController,
          ),
          _buildCoordinatesPanel(
            context,
            colors,
            selectedLocation.coords.latLng,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(
    BuildContext context,
    ({Coordinates coords, String name}) selectedLocation,
    LocationPicker notifierController,
    Future<List<FmData>> Function(String) searchPlaces,
    MapController mapController,
  ) {
    return FSelect<FmData>.searchBuilder(
      control: FSelectControl.managed(
        onChange: (place) {
          if (place != null) {
            notifierController.selectPlace(place);
            mapController.move(place.coordinates.latLng, 14);
          }
        },
      ),
      hint: selectedLocation.name,
      label: Text(context.l10n.searchPlaceLabel),
      format: (s) => s.name,
      filter: searchPlaces,
      contentBuilder: (context, query, data) {
        return [
          for (final place in data)
            FSelectItem(
              title: Text(place.name),
              subtitle: Text(place.address),
              value: place,
            ),
        ];
      },
    );
  }

  Widget _buildTipSection(BuildContext context, FColors colors) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
}
