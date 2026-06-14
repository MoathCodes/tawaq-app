import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/widgets/coordinates_row.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/widgets/location_controls_row.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/widgets/location_map_section.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/widgets/use_location_tile.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_section.dart';
import 'package:tawaq/theme/theme.dart';

/// Widget for the prayer location settings section with inline map.
class PrayerSettingsLocationSection extends ConsumerWidget {
  /// Creates a new [PrayerSettingsLocationSection] instance.
  const PrayerSettingsLocationSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoLocation = ref.watch(
      prayerSettingsProvider.select((v) => v.value?.autoLocation ?? false),
    );
    final prayerSettingsReady = ref.watch(
      prayerSettingsProvider.select((v) => v.hasValue),
    );
    final enabled = prayerSettingsReady && !autoLocation;
    final l10n = context.l10n;

    return SettingsSection(
      crossAxisAlignment: .center,
      title: l10n.locationSectionTitle,
      subtitle: l10n.locationSectionSubtitle,
      child: FCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.lg,
          children: [
            const UseLocationTile(),
            const FDivider(),
            LocationMapSection(enabled: enabled),
            const FDivider(),
            CoordinatesRow(enabled: enabled),
            const FDivider(),
            LocationControlsRow(enabled: enabled),
          ],
        ),
      ),
    );
  }
}
