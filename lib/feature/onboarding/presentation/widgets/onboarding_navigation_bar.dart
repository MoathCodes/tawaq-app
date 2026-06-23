import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/onboarding/presentation/providers/onboarding_controller_provider.dart';
import 'package:tawaq/feature/settings/data/models/prayer_settings_model.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/theme/theme.dart';

/// Bottom navigation for onboarding steps.
class OnboardingNavigationBar extends ConsumerWidget {
  /// Creates [OnboardingNavigationBar].
  const OnboardingNavigationBar({
    required this.step,
    required this.onContinue,
    required this.onBack,
    required this.onDismiss,
    super.key,
  });

  /// Active step index.
  final int step;

  /// Called when the user taps Continue / Finish.
  final VoidCallback onContinue;

  /// Called when the user taps Back.
  final VoidCallback onBack;

  /// Called when the user taps Set up later.
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isLastStep = step >= kOnboardingStepCount - 1;
    if (step == kOnboardingLocationStep) {
      ref.watch(
        prayerSettingsProvider.select((s) => s.value?.isLocationReady),
      );
    }
    final canContinue =
        ref.read(onboardingControllerProvider.notifier).canContinue();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        Row(
          spacing: AppSpacing.sm,
          children: [
            if (step > 0)
              Expanded(
                child: FButton(
                  variant: .ghost,
                  onPress: onBack,
                  child: Text(l10n.back),
                ),
              ),
            Expanded(
              flex: step > 0 ? 2 : 1,
              child: FButton(
                onPress: canContinue ? onContinue : null,
                child: Text(
                  isLastStep ? l10n.onboardingFinishAction : l10n.next,
                ),
              ),
            ),
          ],
        ),
        if (!isLastStep)
          Align(
            alignment: AlignmentDirectional.center,
            child: FButton(
              variant: .ghost,
              onPress: onDismiss,
              child: Text(l10n.onboardingSetUpLater),
            ),
          ),
      ],
    );
  }
}
