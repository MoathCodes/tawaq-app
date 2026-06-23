import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/layout/centered_viewport_shell.dart';
import 'package:tawaq/core/layout/responsive.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/routing/route_provider.dart';
import 'package:tawaq/core/widgets/directional_content_switcher.dart';
import 'package:tawaq/core/widgets/scroll_overflow_hint_viewport.dart';
import 'package:tawaq/feature/onboarding/presentation/providers/onboarding_controller_provider.dart';
import 'package:tawaq/feature/onboarding/presentation/providers/onboarding_state_provider.dart';
import 'package:tawaq/feature/onboarding/presentation/widgets/onboarding_finish_step.dart';
import 'package:tawaq/feature/onboarding/presentation/widgets/onboarding_locale_step.dart';
import 'package:tawaq/feature/onboarding/presentation/widgets/onboarding_navigation_bar.dart';
import 'package:tawaq/feature/onboarding/presentation/widgets/onboarding_step_shell.dart';
import 'package:tawaq/feature/onboarding/presentation/widgets/onboarding_welcome_step.dart';
import 'package:tawaq/feature/settings/presentation/provider/iqamah_draft_provider.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/sections/adhan_section.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/sections/location_section.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/sections/time_section.dart';
import 'package:tawaq/feature/settings/presentation/widgets/theme/app_theme_selector.dart';
import 'package:tawaq/feature/settings/presentation/widgets/typography/settings_scale_step_picker.dart';
import 'package:tawaq/theme/theme.dart';

/// Full-screen first-run onboarding flow.
class OnboardingScreen extends ConsumerWidget {
  /// Creates [OnboardingScreen].
  const OnboardingScreen({super.key});

  static const _compactMaxWidth = 640.0;
  static const _desktopMaxWidth = 1120.0;
  static const _desktopRailWidth = 340.0;
  static const _compactMinHeight = 600.0;

  static double _maxPanelHeight(double viewportHeight) =>
      math.min(viewportHeight, math.max(480, viewportHeight - AppSpacing.xl));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final uiState = ref.watch(onboardingControllerProvider);
    final step = uiState.step;
    final controller = ref.read(onboardingControllerProvider.notifier);
    final appName = l10n.appName;

    final titles = [
      l10n.onboardingStepWelcome,
      l10n.onboardingStepLanguage,
      l10n.onboardingStepLocation,
      l10n.onboardingStepPrayerTimes,
      l10n.onboardingStepIqamah,
      l10n.onboardingStepNotifications,
      l10n.onboardingStepTheme,
      l10n.onboardingStepFinish,
    ];

    final subtitles = [
      l10n.onboardingStepWelcomeSubtitle(appName),
      l10n.onboardingStepLanguageSubtitle,
      l10n.onboardingStepLocationSubtitle,
      l10n.onboardingStepPrayerTimesSubtitle,
      l10n.onboardingStepIqamahSubtitle,
      l10n.onboardingStepNotificationsSubtitle,
      l10n.onboardingStepThemeSubtitle,
      l10n.onboardingStepFinishSubtitle(appName),
    ];

    Future<void> dismissOnboarding() async {
      await ref.read(onboardingStateProvider.notifier).dismiss();
      if (!context.mounted) return;
      const PrayerRoute().go(context);
    }

    Future<void> completeOnboarding() async {
      ref.read(iqamahDraftProvider.notifier).saveAll(context);
      await ref.read(onboardingStateProvider.notifier).complete();
      if (!context.mounted) return;
      const PrayerRoute().go(context);
    }

    void handleContinue() {
      if (step >= kOnboardingStepCount - 1) {
        unawaited(completeOnboarding());
        return;
      }
      controller.next();
    }

    final header = _OnboardingHeader(
      step: step,
      title: titles[step],
      subtitle: subtitles[step],
    );

    final content = DirectionalContentSwitcher(
      currentKey: step,
      slideDirection: uiState.slideDirection,
      child: _OnboardingStepContent(step: step, appName: appName),
    );

    final navigation = OnboardingNavigationBar(
      step: step,
      onContinue: handleContinue,
      onBack: controller.back,
      onDismiss: dismissOnboarding,
    );

    return FScaffold(
      child: SafeArea(
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = isContainerAtLeast(
                    context,
                    constraints,
                    FBreakpoint.lg,
                  ) &&
                  constraints.maxHeight >= _compactMinHeight;
              final maxWidth = wide ? _desktopMaxWidth : _compactMaxWidth;
              final panelHeight = _maxPanelHeight(constraints.maxHeight);

              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                  maxHeight: panelHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: AppSpacing.xxl,
                          children: [
                            SizedBox(
                              width: _desktopRailWidth,
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    header,
                                    const SizedBox(height: AppSpacing.xxxl),
                                    navigation,
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: ScrollOverflowHintViewport(
                                resetTrigger: step,
                                builder: (controller) =>
                                    centeredViewportScrollTab(
                                  maxContentWidth: maxWidth,
                                  controller: controller,
                                  child: content,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            header,
                            const SizedBox(height: AppSpacing.lg),
                            Flexible(
                              child: ScrollOverflowHintViewport(
                                resetTrigger: step,
                                builder: (controller) =>
                                    centeredViewportScrollTab(
                                  maxContentWidth: maxWidth,
                                  controller: controller,
                                  child: content,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            navigation,
                          ],
                        ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({
    required this.step,
    required this.title,
    required this.subtitle,
  });

  final int step;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        FDeterminateProgress(value: (step + 1) / kOnboardingStepCount),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.xs,
          children: [
            Text(
              title,
              style: theme.typography.body.lg.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              subtitle,
              style: theme.typography.body.sm.copyWith(
                color: theme.colors.mutedForeground,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OnboardingStepContent extends StatelessWidget {
  const _OnboardingStepContent({
    required this.step,
    required this.appName,
  });

  final int step;
  final String appName;

  @override
  Widget build(BuildContext context) {
    return switch (step) {
      0 => OnboardingWelcomeStep(appName: appName),
      1 => const OnboardingLocaleStep(),
      2 => const OnboardingStepShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.md,
          children: [
            OnboardingLocationAlert(),
            PrayerSettingsLocationSection(embedded: true),
          ],
        ),
      ),
      3 => const OnboardingStepShell(
        child: PrayerSettingsTimeSection(
          embedded: true,
          mode: PrayerSettingsTimeSectionMode.calculationOnly,
        ),
      ),
      4 => const OnboardingStepShell(
        child: PrayerSettingsTimeSection(
          embedded: true,
          mode: PrayerSettingsTimeSectionMode.iqamahOnly,
        ),
      ),
      5 => const OnboardingStepShell(
        child: PrayerAdhanSettingsSection(embedded: true),
      ),
      6 => const OnboardingThemeStep(),
      7 => const OnboardingFinishStep(),
      _ => const SizedBox.shrink(),
    };
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

/// Theme and text scale step.
class OnboardingThemeStep extends StatelessWidget {
  /// Creates [OnboardingThemeStep].
  const OnboardingThemeStep({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnboardingStepShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.lg,
        children: [
          ColorThemeSelector(embedded: true),
          FDivider(),
          AppTextScaleStepPicker(),
        ],
      ),
    );
  }
}
