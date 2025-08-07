import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:free_map/free_map.dart';
import 'package:hasanat/core/utils/location_extensions.dart';
import 'package:hasanat/feature/settings/data/models/prayer_settings_model.dart';
import 'package:hasanat/feature/settings/presentation/provider/location_provider.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';

class LocationPickerDialog extends ConsumerStatefulWidget {
  final FDialogStyle Function(FDialogStyle) style;
  final Animation<double> animation;
  final void Function(Coordinates coordinates) onLocationSelected;

  const LocationPickerDialog({
    super.key,
    required this.onLocationSelected,
    required this.style,
    required this.animation,
  });

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
    final coords = ref.watch(prayerSettingsNotifierProvider.select(
      (value) => value.value?.coordinates,
    ));
    final selectedLocation = ref.watch(locationPickerProvider(
        coords ?? PrayerSettings.defaultSettings().coordinates));
    final notifierController = ref.read(locationPickerProvider(
            coords ?? PrayerSettings.defaultSettings().coordinates)
        .notifier);
      WidgetsBinding.instance.addPostFrameCallback((_) {

      _mapController.move(selectedLocation, 12);
      });
    
    return FDialog(
      animation: widget.animation,
      style: widget.style,
      direction: Axis.horizontal,
      constraints: const BoxConstraints(maxWidth: 850),
      title: Text(
        "Choose Location",
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
            _buildHeader(colors, notifierController),
            _buildMapSection(colors, selectedLocation, notifierController),
            _buildTipSection(colors),
          ],
        ),
      ),
      actions: [
        FButton(
          style: FButtonStyle.secondary(),
          onPress: () => Navigator.of(context).pop(),
          child: const Text("Cancel"),
        ),
        FButton(
          onPress: () {
            widget.onLocationSelected(selectedLocation.coordinates);
            Navigator.of(context).pop();
          },
          child: const Text("Save"),
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
            style: TextStyle(
              color: colors.foreground,
              fontSize: 13,
              fontFamily: 'monospace',
            ),
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
              Icon(
                Icons.place_outlined,
                color: colors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "Coordinates",
                style: TextStyle(
                  color: colors.foreground,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          _buildCoordinateField(
            label: "Lat:",
            value: selectedLocation.latitude.toStringAsFixed(5),
            colors: colors,
          ),
          _buildCoordinateField(
            label: "Lng:",
            value: selectedLocation.longitude.toStringAsFixed(5),
            colors: colors,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(FColors colors, LocationPicker notifierController) {
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
                'Drag the map to position the pin',
                style: TextStyle(
                  color: colors.mutedForeground,
                  fontSize: 14,
                ),
              ),
              FButton(
                onPress: () async {
                  try {
                    await notifierController.useCurrentLocation();
                  } catch (e) {
                    // Show error snackbar

                    showFToast(
                        context: context,
                        title:
                            const Text("Error Occurred While Getting Location"),
                        description: Text(e.toString()));
                  }
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [
                    Icon(Icons.my_location, size: 16),
                    Text("Use My Location"),
                  ],
                ),
              ),
            ],
          ),
          FutureBuilder(
            future: notifierController.getSelectedPlace(),
            builder: (context, asyncSnapshot) =>
                asyncSnapshot.connectionState == ConnectionState.waiting
                    ? const Center(child: FProgress.circularIcon())
                    : asyncSnapshot.hasError
                        ? Text(
                            'Error: ${asyncSnapshot.error}',
                            style: TextStyle(color: colors.destructive),
                          )
                        : asyncSnapshot.hasData
                            ? _buildSearchField(
                                asyncSnapshot.data!, notifierController)
                            : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(FColors colors, LatLng selectedLocation,
      LocationPicker notifierController) {
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
              initialZoom: 12.0,
              minZoom: 2.0,
              maxZoom: 18.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              onTap: (tapPos, latlng) {
                notifierController.updateLocation(latlng);
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

  Widget _buildMapSection(FColors colors, LatLng selectedLocation,
      LocationPicker notifierController) {
    return Expanded(
      child: Row(
        children: [
          _buildMap(colors, selectedLocation, notifierController),
          _buildCoordinatesPanel(colors, selectedLocation),
        ],
      ),
    );
  }

  Widget _buildSearchField(
      FmData initialValue, LocationPicker notifierController) {
    print("Building search field with initial value: ${initialValue.geoJson}");
    return SizedBox(
      height: 48,
      child: FSelect<FmData>.search(
        initialValue: initialValue,
        hint: initialValue.address,
        format: (s) => s.name,
        filter: (query) => ref.read(searchPlacesProvider(query).future),
        contentBuilder: (context, data) {
          return [
            for (final place in data.values.nonNulls)
              FSelectItem.from(
                  title: Text(place.name),
                  subtitle: Text(place.address),
                  value: place)
          ];
        },
        onChange: (place) {
          if (place != null) {
            notifierController.selectPlace(place);
          }
        },
      ),
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
          Icon(
            Icons.info_outline,
            color: colors.mutedForeground,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'Tip: Hold Shift and drag to rotate and tilt the map.',
            style: TextStyle(
              color: colors.mutedForeground,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
