import 'dart:async';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:free_map/free_map.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/layout/responsive.dart';
import 'package:tawaq/core/layout/responsive_field_row.dart';
import 'package:tawaq/core/layout/viewport_dialog_constraints.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/utils/location_extensions.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/core/widgets/select_empty_content.dart';
import 'package:tawaq/feature/settings/presentation/provider/location_provider.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/widgets/location_display.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/widgets/location_helpers.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_semantics.dart';
import 'package:tawaq/theme/theme.dart';
import 'package:timezone/timezone.dart' as tz;

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

/// Responsive row containing city search and timezone selector.
class LocationControlsRow extends ConsumerWidget {
  /// Creates a new [LocationControlsRow] instance.
  const LocationControlsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const NonSelectable(
      child: ResponsiveFieldRow(
        children: [
          CitySearchSelect(),
          TimezoneSelect(),
        ],
      ),
    );
  }
}

/// Search-based city selection dropdown.
class CitySearchSelect extends ConsumerWidget {
  /// Creates a new [CitySearchSelect] instance.
  const CitySearchSelect({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = manualLocationControlsEnabled(ref);
    final locationName = ref.watch(
      prayerSettingsProvider.select((v) => v.value?.locationName),
    );
    final l10n = context.l10n;
    final secondaryForeground = context.theme.colors.secondaryForeground;

    return FSelect<FmData>.searchBuilder(
      enabled: enabled,
      contentConstraints: selectPopoverPortalConstraints(context),
      control: .managed(
        onChange: (place) {
          if (place != null) {
            unawaited(
              ref
                  .read(prayerSettingsProvider.notifier)
                  .updateLocation(
                    coordinates: place.coordinates,
                    locationName: place.name,
                  ),
            );
          }
        },
      ),
      label: Text(l10n.searchPlaceLabel),
      hint: locationName == null
          ? l10n.searchForMore
          : resolveLocationDisplayName(l10n, locationName),
      format: (s) => s.name,
      filter: (query) => ref.read(searchPlacesProvider(query).future),
      prefixBuilder: (_, _, _) => Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Icon(
          FLucideIcons.search,
          color: secondaryForeground,
        ),
      ),
      contentBuilder: (_, _, data) => [
        for (final place in data)
          FSelectItem(
            title: Text(place.name),
            subtitle: Text(place.address),
            value: place,
          ),
      ],
      contentEmptyBuilder: (_, _) => buildSelectEmptyContent(context),
      contentLoadingBuilder: (_, _) => const FCircularProgress(),
    );
  }
}

/// Search-based timezone selection dropdown.
class TimezoneSelect extends ConsumerWidget {
  /// Creates a new [TimezoneSelect] instance.
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final stackSuffix = !isContainerAtLeast(
          context,
          constraints,
          FBreakpoint.sm,
        );

        final select = FSelect<tz.Location>.searchBuilder(
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
            final locations = ref.read(loadTimezonesProvider);
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
          suffixBuilder: (_, _, _) => stackSuffix
              ? Icon(FLucideIcons.chevronDown, color: colors.primary)
              : Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  spacing: 4,
                  children: [
                    Icon(FLucideIcons.chevronDown, color: colors.primary),
                    locateButton,
                  ],
                ),
        );

        if (!stackSuffix) return select;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.sm,
          children: [
            select,
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: locateButton,
            ),
          ],
        );
      },
    );
  }
}
