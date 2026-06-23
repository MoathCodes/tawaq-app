import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/animation_entry.dart';
import 'package:tawaq/feature/onboarding/presentation/widgets/onboarding_step_shell.dart';
import 'package:tawaq/theme/theme.dart';

/// Welcome hero for the first onboarding step.
class OnboardingWelcomeStep extends StatelessWidget {
  /// Creates [OnboardingWelcomeStep].
  const OnboardingWelcomeStep({required this.appName, super.key});

  /// Localized product name (e.g. توّاق).
  final String appName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;

    return OnboardingStepShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.lg,
        children: [
          AnimationEntry(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.lg,
              children: [
                Icon(
                  FLucideIcons.sparkles,
                  size: 48,
                  color: theme.colors.primary,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: AppSpacing.sm,
                    children: [
                      Text(
                        l10n.onboardingWelcomeTitle(appName),
                        style: theme.typography.body.xl.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        l10n.onboardingWelcomeSubtitle,
                        style: theme.typography.body.md.copyWith(
                          color: theme.colors.mutedForeground,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          FAlert(
            icon: const Icon(FLucideIcons.info),
            title: Text(l10n.onboardingWelcomeTipTitle),
            subtitle: Text(l10n.onboardingWelcomeTipSubtitle),
          ),
        ],
      ),
    );
  }
}
