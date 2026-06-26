import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/widgets/coordinates_row.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/widgets/location_controls_row.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/widgets/location_map_section.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/widgets/use_location_tile.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_section.dart';
import 'package:tawaq/theme/theme.dart';

/// Widget for the prayer location settings section with inline map.
class PrayerSettingsLocationSection extends ConsumerWidget {
  /// Creates a new [PrayerSettingsLocationSection] instance.
  const PrayerSettingsLocationSection({this.embedded = false, super.key});

  /// When true, omits the outer [SettingsSection] chrome for onboarding.
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.lg,
      children: [
        const UseLocationTile(),
        const FDivider(),
        const LocationControlsRow(),
        const FDivider(),
        LocationMapSection(compact: embedded),
        const FDivider(),
        const CoordinatesRow(),
      ],
    );

    if (embedded) return content;

    return SettingsSection(
      crossAxisAlignment: .center,
      title: l10n.locationSectionTitle,
      subtitle: l10n.locationSectionSubtitle,
      child: FCard(child: content),
    );
  }
}
