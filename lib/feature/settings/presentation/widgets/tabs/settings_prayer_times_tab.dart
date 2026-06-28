import 'package:flutter/material.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/sections/adhan_section.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/sections/time_section.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_section.dart';
import 'package:tawaq/theme/theme.dart';

/// Prayer times settings tab body.
class SettingsPrayerTimesTab extends StatelessWidget {
  /// Creates [SettingsPrayerTimesTab].
  const SettingsPrayerTimesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.lg,
      children: [
        PrayerTimeSettings(),
        PrayerAdhanSettings(chrome: SettingsChrome.section),
      ],
    );
  }
}
