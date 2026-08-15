import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/app/routing/route_provider.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/onboarding/presentation/models/onboarding_steps.dart';
import 'package:tawaq/feature/onboarding/presentation/providers/onboarding_controller_provider.dart';
import 'package:tawaq/feature/onboarding/presentation/providers/onboarding_state_provider.dart';
import 'package:tawaq/feature/onboarding/presentation/widgets/onboarding_navigation_bar.dart';
import 'package:tawaq/feature/onboarding/presentation/widgets/onboarding_scaffold.dart';
import 'package:tawaq/feature/settings/presentation/provider/iqamah_draft_provider.dart';

/// Full-screen first-run onboarding flow.
class OnboardingScreen extends ConsumerWidget {
  /// Creates [OnboardingScreen].
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final uiState = ref.watch(onboardingControllerProvider);
    final step = uiState.step;
    final controller = ref.read(onboardingControllerProvider.notifier);
    final appName = l10n.appName;
    final stepDef = onboardingStepDefFor(step, l10n);

    // Keep iqamah draft alive across steps so Continue/Back does not drop edits.
    ref.watch(iqamahDraftProvider);

    Future<void> dismissOnboarding() async {
      final finished = await ref
          .read(onboardingStateProvider.notifier)
          .finish();
      if (!finished || !context.mounted) return;
      const PrayerRoute().go(context);
    }

    Future<void> completeOnboarding() async {
      // Draft buffers iqamah text fields; commit without settings toasts.
      ref.read(iqamahDraftProvider.notifier).commitPending();
      final finished = await ref
          .read(onboardingStateProvider.notifier)
          .finish();
      if (!finished || !context.mounted) return;
      const PrayerRoute().go(context);
    }

    void handleContinue() {
      if (step == OnboardingStep.iqamah) {
        ref.read(iqamahDraftProvider.notifier).commitPending();
      }
      if (step.isLast) {
        unawaited(completeOnboarding());
        return;
      }
      controller.next();
    }

    return OnboardingScaffold(
      step: step,
      title: stepDef.title(l10n, appName),
      subtitle: stepDef.subtitle(l10n, appName),
      slideDirection: uiState.slideDirection,
      stepContent: stepDef.builder(appName),
      navigation: OnboardingNavigationBar(
        step: step,
        onContinue: handleContinue,
        onBack: controller.back,
        onDismiss: dismissOnboarding,
      ),
    );
  }
}
