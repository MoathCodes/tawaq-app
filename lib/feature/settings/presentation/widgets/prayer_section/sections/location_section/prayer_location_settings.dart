import 'dart:async';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:free_map/fm_map.dart' show FmMap;
import 'package:free_map/free_map.dart' show FmMap;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/settings/presentation/models/settings_tabs.dart';
import 'package:tawaq/feature/settings/presentation/provider/prayer_settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_screen_settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/sections/location_section/location_controls.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/sections/location_section/location_map_section.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_section.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_semantics.dart';
import 'package:tawaq/theme/theme.dart';

/// Prayer location controls with optional settings section chrome.
class PrayerLocationSettings extends ConsumerWidget {
  /// Creates [PrayerLocationSettings].
  const PrayerLocationSettings({
    this.chrome = SettingsChrome.section,
    this.compactMap = false,
    this.gateMapToSettingsTab = false,
    super.key,
  });

  /// Outer card chrome for the settings screen.
  final SettingsChrome chrome;

  /// When true, uses a shorter map height (onboarding).
  final bool compactMap;

  /// When true, builds [FmMap] only while the Settings Location tab is active.
  ///
  /// Avoids keeping the map (and its tile/controller retention) alive after
  /// the settings tab panel has activated once. Onboarding leaves this false
  /// so the map stays mounted for the location step.
  final bool gateMapToSettingsTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapActive = !gateMapToSettingsTab ||
        ref.watch(
          settingsScreenSettingsProvider.select(
            (s) => s.value == kSettingsLocationTabKey,
          ),
        );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.lg,
      children: [
        const _UseLocationTile(),
        const FDivider(),
        const LocationControlsRow(),
        const FDivider(),
        LocationMapSection(compact: compactMap, mapActive: mapActive),
        const FDivider(),
        const CoordinatesRow(),
      ],
    );

    if (chrome == SettingsChrome.none) return content;

    final l10n = context.l10n;
    return SettingsSection(
      crossAxisAlignment: CrossAxisAlignment.center,
      title: l10n.locationSectionTitle,
      subtitle: l10n.locationSectionSubtitle,
      child: content,
    );
  }
}

/// Auto-detect location toggle tile.
class _UseLocationTile extends ConsumerWidget {
  const _UseLocationTile();

  Future<void> _onToggle(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    final notifier = ref.read(prayerSettingsProvider.notifier);
    final errorAction = context.l10n.gettingLocation;

    if (!value) {
      await notifier.applyLocationBundle(autoLocation: false);
      return;
    }

    // Commit autoLocation only after GPS (+ TZ) succeeds — one bundle write.
    try {
      await notifier.applyCurrentDeviceLocation(autoLocation: true);
    } catch (e) {
      if (context.mounted) showLocationError(context, errorAction, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoLocation = ref.watch(
      prayerSettingsProvider.select((v) => v.value?.autoLocation ?? false),
    );
    final prayerSettingsReady = ref.watch(
      prayerSettingsProvider.select((v) => v.hasValue),
    );
    final colors = FTheme.of(context).colors;
    final l10n = context.l10n;

    return NonSelectable(
      child: FTile(
        prefix: SettingsSemantics.decorative(
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(FLucideIcons.locate, color: colors.primary),
          ),
        ),
        title: Text(l10n.useMyLocation),
        subtitle: Text(
          autoLocation
              ? l10n.autoLocationEnabled
              : l10n.autoLocationDisabled,
        ),
        suffix: FSwitch(
          enabled: prayerSettingsReady,
          value: autoLocation,
          onChange: (v) => _onToggle(context, ref, v),
        ),
      ),
    );
  }
}
