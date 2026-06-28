import 'dart:async';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/sections/location_section/location_helpers.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_semantics.dart';

/// Auto-detect location toggle tile.
class UseLocationTile extends ConsumerWidget {
  /// Creates [UseLocationTile].
  const UseLocationTile({super.key});

  Future<void> _onToggle(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    final notifier = ref.read(prayerSettingsProvider.notifier)
      ..setAutoLocation(value: value);
    if (!value) return;

    final errorAction = context.l10n.gettingLocation;
    try {
      await notifier.useCurrentLocation();
      await notifier.setSystemTimezone();
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
