import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/locale/locale_select_tile_group.dart';
import 'package:tawaq/feature/onboarding/presentation/widgets/onboarding_step_shell.dart';
import 'package:tawaq/theme/theme.dart';

/// Language selection step.
class OnboardingLocaleStep extends StatelessWidget {
  /// Creates [OnboardingLocaleStep].
  const OnboardingLocaleStep({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return OnboardingStepShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.lg,
        children: [
          Text(
            l10n.onboardingLanguageStepHint,
            style: TextStyle(color: context.theme.colors.mutedForeground),
          ),
          const LocaleSelectTileGroup(),
        ],
      ),
    );
  }
}
