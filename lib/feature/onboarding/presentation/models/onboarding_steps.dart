import 'package:flutter/material.dart';
import 'package:tawaq/feature/onboarding/presentation/widgets/onboarding_finish_step.dart';
import 'package:tawaq/feature/onboarding/presentation/widgets/onboarding_locale_step.dart';
import 'package:tawaq/feature/onboarding/presentation/widgets/onboarding_location_step.dart';
import 'package:tawaq/feature/onboarding/presentation/widgets/onboarding_theme_step.dart';
import 'package:tawaq/feature/onboarding/presentation/widgets/onboarding_welcome_step.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/sections/adhan_section.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/sections/time_section.dart';
import 'package:tawaq/l10n/app_localizations.dart';

/// Ordered onboarding steps.
enum OnboardingStep {
  /// Welcome hero.
  welcome,

  /// Language selection.
  locale,

  /// Prayer location.
  location,

  /// Calculation method and time format.
  prayerTimes,

  /// Iqamah offsets.
  iqamah,

  /// Adhan notifications (desktop).
  notifications,

  /// Theme and text scale.
  theme,

  /// Schedule preview and finish.
  finish;

  /// Whether this is the last step.
  bool get isLast => index == OnboardingStep.values.length - 1;

  /// When true, Continue is blocked until prayer location is ready.
  bool get requiresLocation => this == OnboardingStep.location;
}

/// Metadata and builder for a single onboarding step.
class OnboardingStepDef {
  /// Creates [OnboardingStepDef].
  const OnboardingStepDef({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.builder,
  });

  /// Step identifier.
  final OnboardingStep step;

  /// Header title for this step.
  final String Function(AppLocalizations l10n, String appName) title;

  /// Header subtitle for this step.
  final String Function(AppLocalizations l10n, String appName) subtitle;

  /// Step body widget.
  final Widget Function(String appName) builder;
}

/// All onboarding steps in display order.
List<OnboardingStepDef> onboardingStepDefs(AppLocalizations l10n) {
  return [
    OnboardingStepDef(
      step: OnboardingStep.welcome,
      title: (l10n, _) => l10n.onboardingStepWelcome,
      subtitle: (l10n, appName) => l10n.onboardingStepWelcomeSubtitle(appName),
      builder: (_) => const OnboardingWelcomeStep(),
    ),
    OnboardingStepDef(
      step: OnboardingStep.locale,
      title: (l10n, _) => l10n.onboardingStepLanguage,
      subtitle: (l10n, _) => l10n.onboardingStepLanguageSubtitle,
      builder: (_) => const OnboardingLocaleStep(),
    ),
    OnboardingStepDef(
      step: OnboardingStep.location,
      title: (l10n, _) => l10n.onboardingStepLocation,
      subtitle: (l10n, _) => l10n.onboardingStepLocationSubtitle,
      builder: (_) => const OnboardingLocationStep(),
    ),
    OnboardingStepDef(
      step: OnboardingStep.prayerTimes,
      title: (l10n, _) => l10n.onboardingStepPrayerTimes,
      subtitle: (l10n, _) => l10n.onboardingStepPrayerTimesSubtitle,
      builder: (_) => const PrayerCalculationSettings(),
    ),
    OnboardingStepDef(
      step: OnboardingStep.iqamah,
      title: (l10n, _) => l10n.onboardingStepIqamah,
      subtitle: (l10n, _) => l10n.onboardingStepIqamahSubtitle,
      builder: (_) => const PrayerIqamahSettings(),
    ),
    OnboardingStepDef(
      step: OnboardingStep.notifications,
      title: (l10n, _) => l10n.onboardingStepNotifications,
      subtitle: (l10n, _) => l10n.onboardingStepNotificationsSubtitle,
      builder: (_) => const PrayerAdhanSettings(),
    ),
    OnboardingStepDef(
      step: OnboardingStep.theme,
      title: (l10n, _) => l10n.onboardingStepTheme,
      subtitle: (l10n, _) => l10n.onboardingStepThemeSubtitle,
      builder: (_) => const OnboardingThemeStep(),
    ),
    OnboardingStepDef(
      step: OnboardingStep.finish,
      title: (l10n, _) => l10n.onboardingStepFinish,
      subtitle: (l10n, appName) => l10n.onboardingStepFinishSubtitle(appName),
      builder: (_) => const OnboardingFinishStep(),
    ),
  ];
}

/// Lookup for [step] in [onboardingStepDefs].
OnboardingStepDef onboardingStepDefFor(
  OnboardingStep step,
  AppLocalizations l10n,
) {
  return onboardingStepDefs(l10n).firstWhere((def) => def.step == step);
}
