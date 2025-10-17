import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/logging/talker_provider.dart';
import 'package:hasanat/core/utils/text_extensions.dart';
import 'package:hasanat/feature/settings/presentation/provider/location_provider.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/feature/settings/presentation/widgets/prayer_section/widgets/location_picker_dialog.dart';
import 'package:hasanat/feature/settings/presentation/widgets/settings_section.dart';
import 'package:timezone/timezone.dart' as tz;

class PrayerSettingsLocationSection extends ConsumerStatefulWidget {
  const PrayerSettingsLocationSection({required this.maxWidth, super.key});
  final double maxWidth;

  @override
  ConsumerState<PrayerSettingsLocationSection> createState() =>
      _PrayerSettingsLocationSectionState();
}

class _PrayerSettingsLocationSectionState
    extends ConsumerState<PrayerSettingsLocationSection>
    with TickerProviderStateMixin {
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;

  late FSelectController<tz.Location> _timezoneController;

  bool _lockLat = true;
  bool _lockLng = true;

  @override
  Widget build(BuildContext context) {
    ref.listen(
      prayerSettingsProvider,
      (previous, next) {
        if (previous != next) {
          _latitudeController.text =
              next.value?.coordinates.latitude.toStringAsFixed(7) ?? '';
          _longitudeController.text =
              next.value?.coordinates.longitude.toStringAsFixed(7) ?? '';
          _timezoneController.value = next.value?.location;
        }
      },
      onError: (error, stackTrace) {
        ref.read(talkerProvider).handle(error, stackTrace);
        showFToast(
          context: context,
          title: Text(
            context.l10n.errorOccurredWhile(
              context.l10n.loadingLocationSettings,
            ),
          ),
          description: Text(error.toString()),
        );
      },
    );
    return SettingsSection(
      crossAxisAlignment: CrossAxisAlignment.center,
      title: context.l10n.locationSectionTitle,
      subtitle: context.l10n.locationSectionSubtitle,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.maxWidth),
        child: FCard(
          title: Text(context.l10n.coordinates),
          child: Column(
            spacing: 20,
            children: [
              _buildSelectors(),
              _buildCoordinatesDisplay(),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    _timezoneController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final prayerSettings = ref.read(prayerSettingsProvider);
    _latitudeController = TextEditingController(
      text: prayerSettings.value?.coordinates.latitude.toStringAsFixed(7),
    );
    _longitudeController = TextEditingController(
      text: prayerSettings.value?.coordinates.longitude.toStringAsFixed(7),
    );
    _timezoneController = FSelectController(
      vsync: this,
      value: prayerSettings.value?.location,
    );
  }

  Widget _buildActionButtons() {
    return Column(
      spacing: 12,
      children: [
        FButton(
          onPress: _showLocationPicker,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(FIcons.mapPinPen, size: 16),
              const SizedBox(width: 8),
              Text(context.l10n.autoSelectOrMap),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCoordinateField(
    String label,
    TextEditingController controller,
    bool locked,
    VoidCallback onPress,
  ) {
    return FTextField(
      label: Text(label),
      suffixBuilder: (context, value, child) => FTooltip(
        tipBuilder: (context, controller) => Text(
          locked
              ? context.l10n.unlockToEditCoordinates
              : context.l10n.lockToPreventEdits,
        ),
        child: FButton.icon(
          style: FButtonStyle.ghost(),
          onPress: () {
            if (!locked) {
              final lat = double.tryParse(_latitudeController.text);
              final lng = double.tryParse(_longitudeController.text);

              if (lat != null && lng != null) {
                ref
                    .read(prayerSettingsProvider.notifier)
                    .setCoordinates(Coordinates(lat, lng));
                showFToast(
                  context: context,
                  title: Text(context.l10n.editsSavedTitle),
                  description: Text(context.l10n.editsSavedDescription),
                );
              } else {
                showFToast(
                  context: context,
                  title: Text(context.l10n.invalidCoordinatesTitle),
                  description: Text(context.l10n.invalidCoordinatesDescription),
                );
                return;
              }
            }
            onPress();
          },
          child: Icon(locked ? FIcons.lock : FIcons.lockOpen),
        ),
      ),
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      readOnly:
          locked, // Made read-only since coordinates are set via location picker
    );
  }

  Widget _buildCoordinatesDisplay() {
    return Row(
      spacing: 12,
      children: [
        Expanded(
          child: _buildCoordinateField(
            context.l10n.latitude,
            _latitudeController,
            _lockLat,
            () => setState(() {
              _lockLat = !_lockLat;
            }),
          ),
        ),
        Expanded(
          child: _buildCoordinateField(
            context.l10n.longitude,
            _longitudeController,
            _lockLng,
            () => setState(() {
              _lockLng = !_lockLng;
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 8,
        children: [const Icon(FIcons.searchX), Text(context.l10n.noResults).sm],
      ),
    );
  }

  Widget _buildSelectors() {
    return _buildTimezoneSelector();
  }

  Widget _buildTimezoneSelector() {
    return FSelect<tz.Location>.searchBuilder(
      controller: _timezoneController,
      label: Text(context.l10n.timezone),
      searchFieldProperties: FSelectSearchFieldProperties(
        hint: context.l10n.searchForMore,
      ),
      suffixBuilder: (context, value, child) => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Icon(FIcons.chevronDown, color: context.theme.colors.primary),
          FTooltip(
            tipBuilder: (context, controller) =>
                Text(context.l10n.useSystemTimezone),
            child: FButton.icon(
              style: FButtonStyle.ghost(),
              onPress: _setTimezone,
              child: const Icon(FIcons.locate),
            ),
          ),
        ],
      ),
      contentEmptyBuilder: (context, style) => _buildEmptyState(context),
      onChange: (value) {
        if (value != null) {
          _setTimezone(value);
        }
      },
      format: (location) => location.name,
      contentBuilder: (context, query, data) => data
          .take(16)
          .map((loc) => FSelectItem(title: Text(loc.name), value: loc))
          .toList(),
      contentLoadingBuilder: (context, style) => const FCircularProgress(),
      filter: _filterTimezones,
    );
  }

  Future<Iterable<tz.Location>> _filterTimezones(String query) async {
    final locations = await ref.read(loadTimezonesProvider.future);
    return query.isEmpty
        ? locations
        : locations.where(
            (loc) => loc.name.toLowerCase().contains(query.toLowerCase()),
          );
  }

  Future<void> _setTimezone([tz.Location? location]) async {
    try {
      location ??= tz.getLocation(
        await FlutterTimezone.getLocalTimezone().then(
          (value) => value.identifier,
        ),
      );
      ref.read(prayerSettingsProvider.notifier).setLocation(location);
    } catch (e) {
      if (mounted) {
        showFToast(
          context: context,
          title: Text(
            context.l10n.errorOccurredWhile(context.l10n.changingTimezone),
          ),
          description: Text(e.toString()),
        );
      }
    }
  }

  void _showLocationPicker() {
    showFDialog(
      context: context,
      builder: (context, style, animation) => LocationPickerDialog(
        style: style.call,
        animation: animation,
        onLocationSelected: (coordinates, locationName) {
          ref
              .read(prayerSettingsProvider.notifier)
              .updateLocationData(
                coordinates: coordinates,
                locationName: locationName,
              );
        },
      ),
    );
  }
}
