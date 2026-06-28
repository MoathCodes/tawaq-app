import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/sections/location_section.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_section.dart';
import 'package:tawaq/theme/theme.dart';

/// Location selection step with setup tip.
class OnboardingLocationStep extends StatelessWidget {
  /// Creates [OnboardingLocationStep].
  const OnboardingLocationStep({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        OnboardingLocationAlert(),
        PrayerLocationSettings(
          chrome: SettingsChrome.none,
          compactMap: true,
        ),
      ],
    );
  }
}

/// Contextual alert for the location step.
class OnboardingLocationAlert extends StatelessWidget {
  /// Creates [OnboardingLocationAlert].
  const OnboardingLocationAlert({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return FAlert(
      icon: const Icon(FLucideIcons.mapPin),
      title: Text(l10n.onboardingLocationTipTitle),
      subtitle: Text(l10n.onboardingLocationTipSubtitle),
    );
  }
}
