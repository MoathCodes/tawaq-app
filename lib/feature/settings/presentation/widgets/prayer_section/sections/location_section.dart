import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/feature/settings/presentation/widgets/prayer_section/widgets/coordinates_row.dart';
import 'package:hasanat/feature/settings/presentation/widgets/prayer_section/widgets/location_controls_row.dart';
import 'package:hasanat/feature/settings/presentation/widgets/prayer_section/widgets/location_map_section.dart';
import 'package:hasanat/feature/settings/presentation/widgets/prayer_section/widgets/use_location_tile.dart';
import 'package:hasanat/feature/settings/presentation/widgets/settings_section.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Widget for the prayer location settings section with inline map.
class PrayerSettingsLocationSection extends ConsumerWidget {
  /// Creates a new [PrayerSettingsLocationSection] instance.
  const PrayerSettingsLocationSection({required this.maxWidth, super.key});

  /// The maximum width of the section.
  final double maxWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoLocation = ref.watch(
      prayerSettingsProvider.select((v) => v.value?.autoLocation ?? false),
    );
    final enabled = !autoLocation;

    return SettingsSection(
      crossAxisAlignment: .center,
      title: context.l10n.locationSectionTitle,
      subtitle: context.l10n.locationSectionSubtitle,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: FCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
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
      ),
    );
  }
}
