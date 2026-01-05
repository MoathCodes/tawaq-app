import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/widgets/animation_entry.dart';
import 'package:hasanat/feature/settings/presentation/widgets/app_theme_selector.dart';
import 'package:hasanat/feature/settings/presentation/widgets/prayer_section/prayer_section.dart';
import 'package:hasanat/feature/settings/presentation/widgets/settings_section.dart';

/// Screen for application settings.
class SettingsScreen extends StatelessWidget {
  /// Creates a new [SettingsScreen] instance.
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        spacing: 12,
        children: [
          AnimationEntry(
            delay: 100.ms,
            child: SettingsCard(
              title: context.l10n.appearance,
              subtitle: context.l10n.about,
              sections: [
                SettingsSection(
                  title: context.l10n.colorTheme,
                  subtitle: context.l10n.colorThemeSubtitle,
                  child: const AppThemeSelector(),
                ),
              ],
            ),
          ),
          AnimationEntry(delay: 250.ms, child: const PrayerSection()),
        ],
      ),
    );
  }
}
