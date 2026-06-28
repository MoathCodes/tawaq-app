import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/sections/location_section/coordinates_section.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/sections/location_section/location_controls.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/sections/location_section/location_map_section.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/sections/location_section/use_location_tile.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_section.dart';
import 'package:tawaq/theme/theme.dart';

/// Prayer location controls with optional settings section chrome.
class PrayerLocationSettings extends ConsumerWidget {
  /// Creates [PrayerLocationSettings].
  const PrayerLocationSettings({
    this.chrome = SettingsChrome.section,
    this.compactMap = false,
    super.key,
  });

  /// Outer card chrome for the settings screen.
  final SettingsChrome chrome;

  /// When true, uses a shorter map height (onboarding).
  final bool compactMap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.lg,
      children: [
        const UseLocationTile(),
        const FDivider(),
        const LocationControlsRow(),
        const FDivider(),
        LocationMapSection(compact: compactMap),
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
