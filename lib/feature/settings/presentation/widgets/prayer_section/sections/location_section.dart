import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/hooks/hooks.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/logging/logger_provider.dart';
import 'package:hasanat/core/utils/text_extensions.dart';
import 'package:hasanat/feature/settings/presentation/provider/location_provider.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/feature/settings/presentation/widgets/prayer_section/widgets/location_picker_dialog.dart';
import 'package:hasanat/feature/settings/presentation/widgets/settings_section.dart';
import 'package:hasanat/theme/theme.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

/// Widget for the prayer location settings section.
class PrayerSettingsLocationSection extends HookConsumerWidget {
  /// Creates a new [PrayerSettingsLocationSection] instance.
  const PrayerSettingsLocationSection({required this.maxWidth, super.key});

  /// The maximum width of the section.
  final double maxWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayerSettings = ref.read(prayerSettingsProvider);

    // Controllers
    final latitudeController = useMemoized(
      () => TextEditingController(
        text: prayerSettings.value?.coordinates.latitude.toStringAsFixed(7),
      ),
    );
    final longitudeController = useMemoized(
      () => TextEditingController(
        text: prayerSettings.value?.coordinates.longitude.toStringAsFixed(7),
      ),
    );
    final timezoneController = useFSelectController<tz.Location>(
      initialValue: prayerSettings.value?.location,
    );

    // State
    final lockLat = useState(true);
    final lockLng = useState(true);

    // Dispose memoized controllers
    useEffect(
      () {
        return () {
          latitudeController.dispose();
          longitudeController.dispose();
        };
      },
      const [],
    );

    // Sync controllers when settings change
    ref.listen(
      prayerSettingsProvider,
      (previous, next) {
        if (previous != next) {
          latitudeController.text =
              next.value?.coordinates.latitude.toStringAsFixed(7) ?? '';
          longitudeController.text =
              next.value?.coordinates.longitude.toStringAsFixed(7) ?? '';
          timezoneController.value = next.value?.location;
        }
      },
      onError: (error, stackTrace) {
        ref
            .read(loggerProvider)
            .e(
              'Error loading location settings',
              error: error,
              stackTrace: stackTrace,
            );
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

    Future<void> setTimezone([tz.Location? location]) async {
      try {
        location ??= tz.getLocation(
          await FlutterTimezone.getLocalTimezone().then(
            (value) => value.identifier,
          ),
        );
        ref.read(prayerSettingsProvider.notifier).setLocation(location);
      } catch (e) {
        if (context.mounted) {
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

    Future<void> showLocationPicker() {
      return showFDialog(
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

    return SettingsSection(
      crossAxisAlignment: .center,
      title: context.l10n.locationSectionTitle,
      subtitle: context.l10n.locationSectionSubtitle,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: FCard(
          title: Text(context.l10n.coordinates),
          child: Column(
            spacing: 20,
            children: [
              _buildTimezoneSelector(
                context,
                ref,
                timezoneController,
                setTimezone,
              ),
              _buildCoordinatesDisplay(
                context,
                ref,
                latitudeController,
                longitudeController,
                lockLat,
                lockLng,
              ),
              _buildActionButtons(context, showLocationPicker),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildActionButtons(
  BuildContext context,
  VoidCallback showLocationPicker,
) {
  return Column(
    spacing: 12,
    children: [
      FButton(
        onPress: showLocationPicker,
        child: Row(
          mainAxisAlignment: .center,
          children: [
            const Icon(FIcons.mapPinPen, size: 16),
            const SizedBox(width: AppSpacing.sm),
            Text(context.l10n.autoSelectOrMap),
          ],
        ),
      ),
    ],
  );
}

Widget _buildCoordinateField(
  BuildContext context,
  WidgetRef ref,
  String label,
  TextEditingController controller,
  TextEditingController latitudeController,
  TextEditingController longitudeController,
  bool locked,
  VoidCallback onPress,
) {
  return FTextField(
    control: .managed(controller: controller),
    label: Text(label),
    suffixBuilder: (ctx, value, child) => FTooltip(
      tipBuilder: (ctx, ctrl) => Text(
        locked
            ? context.l10n.unlockToEditCoordinates
            : context.l10n.lockToPreventEdits,
      ),
      child: FButton.icon(
        style: FButtonStyle.ghost(),
        onPress: () {
          if (!locked) {
            final lat = double.tryParse(latitudeController.text);
            final lng = double.tryParse(longitudeController.text);

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
    keyboardType: const TextInputType.numberWithOptions(
      decimal: true,
      signed: true,
    ),
    readOnly: locked,
  );
}

Widget _buildCoordinatesDisplay(
  BuildContext context,
  WidgetRef ref,
  TextEditingController latitudeController,
  TextEditingController longitudeController,
  ValueNotifier<bool> lockLat,
  ValueNotifier<bool> lockLng,
) {
  return Row(
    spacing: 12,
    children: [
      Expanded(
        child: _buildCoordinateField(
          context,
          ref,
          context.l10n.latitude,
          latitudeController,
          latitudeController,
          longitudeController,
          lockLat.value,
          () => lockLat.value = !lockLat.value,
        ),
      ),
      Expanded(
        child: _buildCoordinateField(
          context,
          ref,
          context.l10n.longitude,
          longitudeController,
          latitudeController,
          longitudeController,
          lockLng.value,
          () => lockLng.value = !lockLng.value,
        ),
      ),
    ],
  );
}

Widget _buildEmptyState(BuildContext context) {
  return Padding(
    padding: const .all(AppSpacing.sm),
    child: Row(
      mainAxisAlignment: .center,
      spacing: 8,
      children: [const Icon(FIcons.searchX), Text(context.l10n.noResults).sm],
    ),
  );
}

Widget _buildTimezoneSelector(
  BuildContext context,
  WidgetRef ref,
  FSelectController<tz.Location> timezoneController,
  Future<void> Function([tz.Location?]) setTimezone,
) {
  Future<Iterable<tz.Location>> filterTimezones(String query) async {
    final locations = await ref.read(loadTimezonesProvider.future);
    return query.isEmpty
        ? locations
        : locations.where(
            (loc) => loc.name.toLowerCase().contains(query.toLowerCase()),
          );
  }

  return FSelect<tz.Location>.searchBuilder(
    control: .managed(
      controller: timezoneController,
      onChange: (value) {
        if (value != null) {
          setTimezone(value);
        }
      },
    ),
    label: Text(context.l10n.timezone),
    searchFieldProperties: FSelectSearchFieldProperties(
      hint: context.l10n.searchForMore,
    ),
    suffixBuilder: (ctx, value, child) => Row(
      mainAxisAlignment: .end,
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        Icon(FIcons.chevronDown, color: context.theme.colors.primary),
        FTooltip(
          tipBuilder: (ctx, ctrl) => Text(context.l10n.useSystemTimezone),
          child: FButton.icon(
            style: FButtonStyle.ghost(),
            onPress: setTimezone,
            child: const Icon(FIcons.locate),
          ),
        ),
      ],
    ),
    contentEmptyBuilder: (ctx, style) => _buildEmptyState(context),
    format: (location) => location.name,
    contentBuilder: (ctx, query, data) => data
        .take(16)
        .map((loc) => FSelectItem(title: Text(loc.name), value: loc))
        .toList(),
    contentLoadingBuilder: (ctx, style) => const FCircularProgress(),
    filter: filterTimezones,
  );
}
