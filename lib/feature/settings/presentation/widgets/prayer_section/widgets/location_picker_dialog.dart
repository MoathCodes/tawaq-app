import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:free_map/free_map.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/utils/location_extensions.dart';
import 'package:hasanat/feature/settings/presentation/provider/location_provider.dart';

class LocationPickerDialog extends ConsumerStatefulWidget {

  const LocationPickerDialog({
    required this.onLocationSelected, required this.style, required this.animation, super.key,
  });
  final FDialogStyle Function(FDialogStyle) style;
  final Animation<double> animation;
  final void Function(Coordinates coordinates, String locationName)
  onLocationSelected;

  @override
  ConsumerState<LocationPickerDialog> createState() =>
      _LocationPickerDialogState();
}

class _LocationPickerDialogState extends ConsumerState<LocationPickerDialog> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final colors = theme.colors;

    final selectedLocation = ref.watch(locationPickerProvider);
    final notifierController = ref.read(locationPickerProvider.notifier);

    return FDialog(
      animation: widget.animation,
      style: widget.style,
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
            _buildHeader(colors, notifierController, selectedLocation),
            _buildMapSection(colors, selectedLocation, notifierController),
            _buildTipSection(colors),
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
            widget.onLocationSelected(selectedLocation.$1, selectedLocation.$2);

            Navigator.of(context).pop();
          },
          child: Text(context.l10n.save),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
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

  Widget _buildCoordinatesPanel(FColors colors, LatLng selectedLocation) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(top: 16, right: 16, bottom: 16),
      padding: const EdgeInsets.all(16),
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
              const SizedBox(width: 8),
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
    FColors colors,
    LocationPicker notifierController,
    (Coordinates coords, String name) selectedLocation,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                    notifierController.useCurrentLocation(_mapController);
                  } catch (e) {
                    // Show error snackbar
                    if (mounted) {
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
          _buildSearchField(selectedLocation, notifierController),
        ],
      ),
    );
  }

  Widget _buildMap(
    FColors colors,
    LatLng selectedLocation,
    LocationPicker notifierController,
  ) {
    return Expanded(
      flex: 3,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: FmMap(
            mapController: _mapController,
            mapOptions: MapOptions(
              initialCenter: selectedLocation,
              initialZoom: 12,
              minZoom: 2,
              maxZoom: 18,
              onTap: (tapPos, latlng) {
                try {
                  notifierController.updateLocation(latlng);
                  _mapController.move(latlng, 14);
                } catch (e) {
                  if (mounted) {
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
    FColors colors,
    (Coordinates coords, String name) selectedLocation,
    LocationPicker notifierController,
  ) {
    return Expanded(
      child: Row(
        children: [
          _buildMap(colors, selectedLocation.$1.latLng, notifierController),
          _buildCoordinatesPanel(colors, selectedLocation.$1.latLng),
        ],
      ),
    );
  }

  Widget _buildSearchField(
    (Coordinates coords, String name) selectedLocation,
    LocationPicker notifierController,
  ) {
    return FSelect<FmData>.searchBuilder(
      hint: selectedLocation.$2,
      label: Text(context.l10n.searchPlaceLabel),
      format: (s) => s.name,
      filter: (query) => ref.read(searchPlacesProvider(query).future),
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
      onChange: (place) {
        if (place != null) {
          notifierController.selectPlace(place);
          _mapController.move(place.coordinates.latLng, 14);
        }
      },
    );
  }

  Widget _buildTipSection(FColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          const SizedBox(width: 8),
          Text(
            context.l10n.tipHoldCtrlToRotate,
            style: TextStyle(color: colors.mutedForeground, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
