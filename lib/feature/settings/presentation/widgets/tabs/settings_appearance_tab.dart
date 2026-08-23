import 'package:flutter/material.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/locale/locale_select_tile_group.dart';
import 'package:tawaq/feature/onboarding/presentation/widgets/onboarding_rerun_tile.dart';
import 'package:tawaq/feature/settings/presentation/widgets/desktop_settings_section.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_section.dart';
import 'package:tawaq/feature/settings/presentation/widgets/theme/app_theme_selector.dart';
import 'package:tawaq/feature/settings/presentation/widgets/typography/typography_settings_section.dart';
import 'package:tawaq/theme/theme.dart';

/// Appearance settings tab body.
class SettingsAppearanceTab extends StatelessWidget {
  /// Creates [SettingsAppearanceTab].
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.lg,
      children: [
        const OnboardingRerunTile(),
        const DesktopSettingsSection(),
        SettingsSection(
          title: l10n.languageLabel,
          subtitle: l10n.onboardingLanguageStepHint,
          child: const LocaleSelectTileGroup(),
        ),
        SettingsSection(
          title: l10n.appearance,
          subtitle: l10n.colorThemeSubtitle,
          child: const ColorThemeSelectorContent(),
        ),
        SettingsSection(
          title: l10n.typographySectionTitle,
          subtitle: l10n.typographySectionSubtitle,
          child: const TypographySettingsSection(),
        ),
      ],
    );
  }
}
