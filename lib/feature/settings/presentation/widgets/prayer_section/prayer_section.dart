import 'package:flutter/material.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/feature/settings/presentation/widgets/prayer_section/sections/location_section.dart';
import 'package:hasanat/feature/settings/presentation/widgets/prayer_section/sections/time_section.dart';
import 'package:hasanat/feature/settings/presentation/widgets/settings_section.dart';

class PrayerSection extends StatelessWidget {
  const PrayerSection({super.key, this.maxWidth = 800});
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      title: context.l10n.prayerSettingsTitle,
      subtitle: context.l10n.prayerSettingsSubtitle,
      spacing: 16,
      sections: [
        PrayerSettingsLocationSection(
          maxWidth: maxWidth,
        ),
        PrayerSettingsTimeSection(maxWidth: maxWidth),
      ],
    );
  }
}
