import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:forui_hooks/forui_hooks.dart';
import 'package:free_map/free_map.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/layout/responsive_field_row.dart';
import 'package:tawaq/core/layout/viewport_dialog_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/utils/location_extensions.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/core/widgets/select_empty_content.dart';
import 'package:tawaq/feature/settings/data/location_constants.dart';
import 'package:tawaq/feature/settings/domain/models/location_failure.dart';
import 'package:tawaq/feature/settings/domain/services/timezone_catalog.dart';
import 'package:tawaq/feature/settings/presentation/provider/location_provider.dart';
import 'package:tawaq/feature/settings/presentation/provider/prayer_settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_semantics.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/theme.dart';
import 'package:timezone/timezone.dart' as tz;

/// Default map center (Makkah).
const kDefaultCenter = LatLng(21.4362544, 39.6817387);

/// Returns a user-facing label for a persisted [locationName] value.
String resolveLocationDisplayName(AppLocalizations l10n, String locationName) {
  return switch (locationName) {
    LocationConstants.defaultLocationName ||
    LocationConstants.legacyDefaultLocationName => l10n.defaultLocation,
    LocationConstants.unknownLocationName ||
    LocationConstants.legacyUnknownLocationName => l10n.unknownLocation,
    _ => locationName,
  };
}

/// Maps [error] to a localized message when it is a [LocationException].
String localizeLocationFailure(AppLocalizations l10n, Object error) {
  if (error is! LocationException) return error.toString();

  return switch (error.code) {
    LocationFailureCode.servicesDisabled => l10n.locationServicesDisabled,
    LocationFailureCode.permissionDenied => l10n.locationPermissionDenied,
    LocationFailureCode.permissionDeniedForever =>
      l10n.locationPermissionDeniedForever,
    LocationFailureCode.coordinatesLookupFailed =>
      l10n.locationCoordinatesLookupFailed,
    LocationFailureCode.noPlaceFound => l10n.locationNoPlaceFound(
      error.detail ?? '',
    ),
  };
}

/// Shows a location error toast.
void showLocationError(BuildContext context, String action, Object error) {
  if (!context.mounted) return;
  final l10n = context.l10n;
  showFToast(
    context: context,
    title: Text(l10n.errorOccurredWhile(action)),
    description: Text(localizeLocationFailure(l10n, error)),
  );
}

/// Whether manual location controls are editable.
bool manualLocationControlsEnabled(WidgetRef ref) {
  final ready = ref.watch(
    prayerSettingsProvider.select((v) => v.hasValue),
  );
  final autoLocation = ref.watch(
    prayerSettingsProvider.select((v) => v.value?.autoLocation ?? false),
  );
  return ready && !autoLocation;
}

/// City search and timezone controls in a responsive row.
class LocationControlsRow extends ConsumerWidget {
  /// Creates [LocationControlsRow].
  const LocationControlsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const NonSelectable(
      child: ResponsiveFieldRow(
        children: [
          PlaceSearchField(),
          TimezoneSelect(),
        ],
      ),
    );
  }
}

/// Nominatim place search that runs only on explicit submit (Enter / Search).
///
/// Keystroke autocomplete is forbidden by the Nominatim usage policy; this
/// field never queries until the user submits.
class PlaceSearchField extends HookConsumerWidget {
  /// Creates [PlaceSearchField].
  const PlaceSearchField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = manualLocationControlsEnabled(ref);
    final locationName = ref.watch(
      prayerSettingsProvider.select((v) => v.value?.locationName),
    );
    final l10n = context.l10n;
    final colors = context.theme.colors;

    final queryController = useTextEditingController();
    final focusNode = useFocusNode();
    final popoverController = useFPopoverController();
    final searchState = useState<AsyncValue<List<FmData>>?>(null);
    final requestId = useRef(0);
    final inFlight = useRef(false);

    useListenable(queryController);

    final isSearching = searchState.value?.isLoading ?? false;

    void invalidateSearch() {
      requestId.value++;
      inFlight.value = false;
      searchState.value = null;
    }

    Future<void> hideResults() async {
      invalidateSearch();
      await popoverController.hide();
    }

    // Drop open/in-flight results when auto-location locks the controls.
    useEffect(
      () {
        if (enabled) return null;
        if (searchState.value == null &&
            popoverController.status == AnimationStatus.dismissed) {
          return null;
        }
        invalidateSearch();
        unawaited(popoverController.hide());
        return null;
      },
      [enabled],
    );

    Future<void> submit() async {
      if (!enabled || inFlight.value) return;
      final query = queryController.text.trim();
      if (query.isEmpty) return;

      final id = ++requestId.value;
      inFlight.value = true;
      searchState.value = const AsyncLoading();
      await popoverController.show();

      try {
        final results = await ref.read(searchPlacesProvider(query).future);
        if (!context.mounted || id != requestId.value) return;
        inFlight.value = false;
        searchState.value = AsyncData(results);
        // Keep the popover as the user left it — do not reopen after dismiss.
      } catch (e, st) {
        if (!context.mounted || id != requestId.value) return;
        inFlight.value = false;
        searchState.value = AsyncError(e, st);
        await popoverController.hide();
        if (!context.mounted) return;
        showLocationError(context, l10n.searchingPlace, e);
      }
    }

    void onQueryChanged(TextEditingValue value) {
      if (searchState.value == null && !inFlight.value) return;
      // Drop stale results when the query changes; do not re-query.
      unawaited(hideResults());
    }

    void selectPlace(FmData place) {
      if (!manualLocationControlsEnabled(ref)) return;
      invalidateSearch();
      unawaited(popoverController.hide());
      queryController.text = place.name;
      final errorAction = l10n.changingTimezone;
      unawaited(() async {
        try {
          await ref.read(prayerSettingsProvider.notifier).applyLocationBundle(
            coordinates: place.coordinates,
            locationName: place.name,
          );
        } catch (e) {
          if (context.mounted) showLocationError(context, errorAction, e);
        }
      }());
    }

    final hint = locationName == null
        ? l10n.searchPlaceQueryHint
        : resolveLocationDisplayName(l10n, locationName);

    final canSubmit =
        enabled && !inFlight.value && queryController.text.trim().isNotEmpty;

    return FPopover(
      control: .managed(
        controller: popoverController,
        onChange: (shown) {
          // User dismissed (outside tap / Escape) while results or loading
          // were showing — invalidate so a late response cannot reopen.
          if (!shown && (searchState.value != null || inFlight.value)) {
            invalidateSearch();
          }
        },
      ),
      constraints: selectPopoverPortalConstraints(context),
      autofocus: true,
      popoverBuilder: (context, _) => _PlaceSearchResults(
        state: searchState.value,
        onSelect: selectPlace,
      ),
      child: FTextField(
        enabled: enabled,
        focusNode: focusNode,
        control: .managed(
          controller: queryController,
          onChange: onQueryChanged,
        ),
        label: Text(l10n.searchPlaceLabel),
        hint: hint,
        // description: Text(
        //   l10n.searchPlaceSubmitHint,
        //   style: context.theme.textFieldStyles.sm.descriptionTextStyle.base
        //       .copyWith(
        //         fontSize: 12,
        //       ),
        // ),
        textInputAction: TextInputAction.search,
        onSubmit: canSubmit ? (_) => unawaited(submit()) : null,
        clearable: (value) => enabled && value.text.isNotEmpty,
        prefixBuilder: (_, _, _) => Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Icon(
            FLucideIcons.search,
            color: colors.secondaryForeground,
          ),
        ),
        suffixBuilder: (_, _, _) {
          if (isSearching) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.sm),
              child: FCircularProgress(),
            );
          }
          return FTooltip(
            semanticsLabel: l10n.searchPlaceAction,
            tipBuilder: (_, _) => Text(l10n.searchPlaceAction),
            child: SettingsSemantics.iconAction(
              label: l10n.searchPlaceAction,
              enabled: canSubmit,
              child: Padding(
                padding: const EdgeInsets.all(1),
                child: FButton.icon(
                  variant: .ghost,
                  onPress: canSubmit ? () => unawaited(submit()) : null,
                  child: Icon(
                    FLucideIcons.search,
                    color: canSubmit ? colors.primary : colors.mutedForeground,
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

class _PlaceSearchResults extends StatelessWidget {
  const _PlaceSearchResults({
    required this.state,
    required this.onSelect,
  });

  final AsyncValue<List<FmData>>? state;
  final ValueChanged<FmData> onSelect;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      null => const SizedBox.shrink(),
      AsyncLoading() => const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: FCircularProgress()),
      ),
      AsyncError() => const SizedBox.shrink(),
      AsyncData(:final value) when value.isEmpty => buildSelectEmptyContent(
        context,
      ),
      AsyncData(:final value) => FItemGroup(
        maxHeight: 280,
        children: [
          for (final place in value)
            FItem(
              title: Text(place.name),
              subtitle: Text(place.address),
              onPress: () => onSelect(place),
            ),
        ],
      ),
    };
  }
}

/// Timezone select with system-timezone shortcut.
class TimezoneSelect extends ConsumerWidget {
  /// Creates [TimezoneSelect].
  const TimezoneSelect({super.key});

  Future<void> _setTimezone(
    BuildContext context,
    WidgetRef ref, [
    tz.Location? loc,
  ]) async {
    final errorAction = context.l10n.changingTimezone;
    try {
      await ref.read(prayerSettingsProvider.notifier).setSystemTimezone(loc);
    } catch (e) {
      if (context.mounted) showLocationError(context, errorAction, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = manualLocationControlsEnabled(ref);
    final location = ref.watch(
      prayerSettingsProvider.select((v) => v.value?.location),
    );
    final l10n = context.l10n;
    final colors = context.theme.colors;

    final locateButton = FTooltip(
      semanticsLabel: l10n.useSystemTimezone,
      tipBuilder: (_, _) => Text(l10n.useSystemTimezone),
      child: SettingsSemantics.iconAction(
        label: SettingsSemantics.useSystemTimezoneAction(l10n),
        enabled: enabled,
        child: FButton.icon(
          variant: .ghost,
          onPress: enabled ? () => unawaited(_setTimezone(context, ref)) : null,
          child: const Icon(FLucideIcons.locate),
        ),
      ),
    );

    return FSelect<tz.Location>.searchBuilder(
      enabled: enabled,
      contentConstraints: selectPopoverPortalConstraints(context),
      control: .lifted(
        value: location,
        onChange: (v) {
          if (v != null) unawaited(_setTimezone(context, ref, v));
        },
      ),
      label: Text(l10n.timezone),
      format: (loc) => loc.name,
      searchFieldProperties: FSelectSearchFieldProperties(
        hint: l10n.searchForMore,
      ),
      prefixBuilder: (_, _, _) => Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Icon(
          FLucideIcons.clock,
          color: colors.secondaryForeground,
        ),
      ),
      filter: (query) async {
        final catalog = ref.read(timezoneCatalogProvider);
        final locations = location == null
            ? catalog
            : sortTimezones(locations: catalog, selected: location);
        return query.isEmpty
            ? locations
            : locations.where(
                (l) => l.name.toLowerCase().contains(query.toLowerCase()),
              );
      },
      contentBuilder: (_, _, data) => data
          .take(16)
          .map((l) => FSelectItem(title: Text(l.name), value: l))
          .toList(),
      contentEmptyBuilder: (_, _) => buildSelectEmptyContent(context),
      contentLoadingBuilder: (_, _) => const FCircularProgress(),
      suffixBuilder: (_, _, _) => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Icon(FLucideIcons.chevronDown, color: colors.primary),
          locateButton,
        ],
      ),
    );
  }
}

/// Manual latitude/longitude text fields.
class CoordinatesRow extends ConsumerWidget {
  /// Creates [CoordinatesRow].
  const CoordinatesRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coordinates = ref.watch(
      prayerSettingsProvider.select((v) => v.value?.coordinates),
    );
    if (coordinates == null) return const SizedBox.shrink();

    final l10n = context.l10n;
    return NonSelectable(
      child: ResponsiveFieldRow(
        maxColumns: 2,
        children: [
          _CoordinateField(
            isLatitude: true,
            label: l10n.latitude,
            min: -90,
            max: 90,
          ),
          _CoordinateField(
            isLatitude: false,
            label: l10n.longitude,
            min: -180,
            max: 180,
          ),
        ],
      ),
    );
  }
}

class _CoordinateField extends HookConsumerWidget {
  const _CoordinateField({
    required this.isLatitude,
    required this.label,
    required this.min,
    required this.max,
  });

  final bool isLatitude;
  final String label;
  final double min;
  final double max;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = manualLocationControlsEnabled(ref);
    final coordinates = ref.watch(
      prayerSettingsProvider.select((v) => v.value?.coordinates),
    );
    if (coordinates == null) return const SizedBox.shrink();

    final value = isLatitude
        ? coordinates.latitude.toStringAsFixed(7)
        : coordinates.longitude.toStringAsFixed(7);

    final controller = useTextEditingController(text: value);
    final focusNode = useFocusNode();

    useValueChanged<String, void>(value, (_, _) {
      if (!focusNode.hasFocus) controller.text = value;
      return;
    });

    useEffect(
      () {
        void onFocusChanged() {
          if (focusNode.hasFocus) return;
          final parsed = double.tryParse(controller.text);
          if (parsed == null) {
            controller.text = value;
            return;
          }
          final coords = ref.read(
            prayerSettingsProvider.select((s) => s.value?.coordinates),
          );
          if (coords == null) return;

          final newCoords = isLatitude
              ? Coordinates(parsed, coords.longitude)
              : Coordinates(coords.latitude, parsed);
          if (newCoords.latitude == coords.latitude &&
              newCoords.longitude == coords.longitude) {
            return;
          }
          unawaited(() async {
            try {
              await ref
                  .read(prayerSettingsProvider.notifier)
                  .applyLocationBundle(coordinates: newCoords);
            } catch (e) {
              controller.text = value;
              if (context.mounted) {
                showLocationError(
                  context,
                  context.l10n.changingTimezone,
                  e,
                );
              }
            }
          }());
        }

        focusNode.addListener(onFocusChanged);
        return () => focusNode.removeListener(onFocusChanged);
      },
      [focusNode, controller, value, isLatitude],
    );

    return FTextField(
      enabled: enabled,
      focusNode: focusNode,
      control: .managed(
        controller: controller,
      ),
      label: Text(label),
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp('[0-9.-]')),
        _CoordinateRangeFormatter(min: min, max: max),
      ],
    );
  }
}

class _CoordinateRangeFormatter extends TextInputFormatter {
  const _CoordinateRangeFormatter({required this.min, required this.max});

  final double min;
  final double max;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty || text == '-' || text == '.') return newValue;

    final parsed = double.tryParse(text);
    return (parsed != null && parsed >= min && parsed <= max)
        ? newValue
        : oldValue;
  }
}
