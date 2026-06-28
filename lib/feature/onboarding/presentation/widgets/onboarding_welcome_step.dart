import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/animation_entry.dart';
import 'package:tawaq/theme/theme.dart';

/// Welcome hero for the first onboarding step.
class OnboardingWelcomeStep extends StatelessWidget {
  /// Creates [OnboardingWelcomeStep].
  const OnboardingWelcomeStep({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.lg,
      children: [
        AnimationEntry(
          child: Icon(
            FLucideIcons.sparkles,
            size: 48,
            color: theme.colors.primary,
          ),
        ),
        FAlert(
          icon: const Icon(FLucideIcons.info),
          title: Text(l10n.onboardingWelcomeTipTitle),
          subtitle: Text(l10n.onboardingWelcomeTipSubtitle),
        ),
      ],
    );
  }
}
