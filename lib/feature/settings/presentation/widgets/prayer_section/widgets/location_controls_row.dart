import 'dart:async';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:free_map/free_map.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/utils/location_extensions.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/settings/presentation/provider/location_provider.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/widgets/location_display.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/widgets/location_helpers.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_semantics.dart';
import 'package:tawaq/theme/theme.dart';
import 'package:timezone/timezone.dart' as tz;

/// Responsive row containing city search and timezone selector.
class LocationControlsRow extends ConsumerWidget {
  /// Creates a new [LocationControlsRow] instance.
  const LocationControlsRow({required this.enabled, super.key});

  /// Whether the controls are editable.
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final children = [
          CitySearchSelect(enabled: enabled),
          TimezoneSelect(enabled: enabled),
        ];

        return NonSelectable(
          child: constraints.maxWidth > 500
              ? Row(
                  spacing: 12,
                  children: children.map((c) => Expanded(child: c)).toList(),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 12,
                  children: children,
                ),
        );
      },
    );
  }
}

/// Search-based city selection dropdown.
class CitySearchSelect extends ConsumerWidget {
  /// Creates a new [CitySearchSelect] instance.
  const CitySearchSelect({required this.enabled, super.key});

  /// Whether the select is editable.
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationName = ref.watch(
      prayerSettingsProvider.select((v) => v.value?.locationName),
    );
    final l10n = context.l10n;
    final secondaryForeground = context.theme.colors.secondaryForeground;

    return FSelect<FmData>.searchBuilder(
      enabled: enabled,
      control: .managed(
        onChange: (place) {
          if (place != null) {
            unawaited(
              ref
                  .read(prayerSettingsProvider.notifier)
                  .updateLocationData(
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
      contentEmptyBuilder: (_, _) => buildEmptyContent(context),
      contentLoadingBuilder: (_, _) => const FCircularProgress(),
    );
  }
}

/// Search-based timezone selection dropdown.
class TimezoneSelect extends ConsumerWidget {
  /// Creates a new [TimezoneSelect] instance.
  const TimezoneSelect({required this.enabled, super.key});

  /// Whether the select is editable.
  final bool enabled;

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
    final location = ref.watch(
      prayerSettingsProvider.select((v) => v.value?.location),
    );
    final l10n = context.l10n;
    final colors = context.theme.colors;

    return FSelect<tz.Location>.searchBuilder(
      enabled: enabled,
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
        final locations = await ref.read(loadTimezonesProvider.future);
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
      contentEmptyBuilder: (_, _) => buildEmptyContent(context),
      contentLoadingBuilder: (_, _) => const FCircularProgress(),
      suffixBuilder: (_, _, _) => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Icon(FLucideIcons.chevronDown, color: colors.primary),
          FTooltip(
            tipBuilder: (_, _) => Text(l10n.useSystemTimezone),
            child: SettingsSemantics.iconAction(
              label: SettingsSemantics.useSystemTimezoneAction(l10n),
              enabled: enabled,
              child: FButton.icon(
                variant: .ghost,
                onPress: enabled
                    ? () => unawaited(_setTimezone(context, ref))
                    : null,
                child: const Icon(FLucideIcons.locate),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
