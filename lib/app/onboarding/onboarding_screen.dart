import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/app/onboarding/onboarding_scaffold.dart';
import 'package:tawaq/app/routing/route_provider.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/locale/locale_select_tile_group.dart';
import 'package:tawaq/core/utils/prayer_extensions.dart';
import 'package:tawaq/core/widgets/animation_entry.dart';
import 'package:tawaq/core/widgets/custom_cards.dart';
import 'package:tawaq/core/widgets/semantics_scale_step_picker.dart';
import 'package:tawaq/feature/onboarding/presentation/providers/onboarding_state_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/date_formatter.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_day.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_settings_provider.dart';
import 'package:tawaq/feature/settings/data/models/app_text_scale.dart';
import 'package:tawaq/feature/settings/presentation/provider/iqamah_draft_provider.dart';
import 'package:tawaq/feature/settings/presentation/provider/theme_settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/sections/adhan_section.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/sections/location_section/prayer_location_settings.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/sections/time_section.dart';
import 'package:tawaq/feature/settings/presentation/widgets/settings_section.dart';
import 'package:tawaq/feature/settings/presentation/widgets/theme/app_theme_selector.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/theme.dart';

part 'onboarding_screen.g.dart';

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
      stepKey: step,
      stepIndex: step.index,
      stepCount: OnboardingStep.values.length,
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

/// UI state for the onboarding stepper.
class OnboardingControllerState {
  /// Creates [OnboardingControllerState].
  const OnboardingControllerState({
    required this.step,
    required this.slideDirection,
  });

  /// Active onboarding step.
  final OnboardingStep step;

  /// `1` = backward, `-1` = forward (for directional step transitions).
  final int slideDirection;

  /// Initial step.
  static const initial = OnboardingControllerState(
    step: OnboardingStep.welcome,
    slideDirection: -1,
  );
}

/// Ephemeral onboarding navigation state.
@riverpod
class OnboardingController extends _$OnboardingController {
  @override
  OnboardingControllerState build() => OnboardingControllerState.initial;

  /// Advances to the next step.
  void next() {
    if (state.step.isLast) return;
    final nextStep = OnboardingStep.values[state.step.index + 1];
    state = OnboardingControllerState(
      step: nextStep,
      slideDirection: -1,
    );
  }

  /// Goes back one step.
  void back() {
    if (state.step == OnboardingStep.welcome) return;
    final previousStep = OnboardingStep.values[state.step.index - 1];
    state = OnboardingControllerState(
      step: previousStep,
      slideDirection: 1,
    );
  }
}

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

  /// Active step.
  final OnboardingStep step;

  /// Called when the user taps Continue / Finish.
  final VoidCallback onContinue;

  /// Called when the user taps Back.
  final VoidCallback onBack;

  /// Called when the user taps Set up later.
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final canContinue =
        !step.requiresLocation ||
        ref.watch(
          prayerSettingsProvider.select(
            (s) => s.value?.isLocationReady ?? false,
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.md,
      children: [
        Row(
          spacing: AppSpacing.sm,
          children: [
            if (step != OnboardingStep.welcome)
              Expanded(
                child: FButton(
                  variant: .ghost,
                  onPress: onBack,
                  child: Text(l10n.back),
                ),
              ),
            Expanded(
              flex: step != OnboardingStep.welcome ? 2 : 1,
              child: FButton(
                onPress: canContinue ? onContinue : null,
                child: Text(
                  step.isLast ? l10n.onboardingFinishAction : l10n.next,
                ),
              ),
            ),
          ],
        ),
        if (!step.isLast)
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

/// Language selection step.
class OnboardingLocaleStep extends StatelessWidget {
  /// Creates [OnboardingLocaleStep].
  const OnboardingLocaleStep({super.key});

  @override
  Widget build(BuildContext context) {
    return const LocaleSelectTileGroup();
  }
}

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

/// Theme palette and app text scale onboarding step.
class OnboardingThemeStep extends ConsumerWidget {
  /// Creates [OnboardingThemeStep].
  const OnboardingThemeStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final appTextScale = ref.watch(
      themeProvider.select((t) => t.value?.appTextScale ?? AppTextScale.normal),
    );
    final themeReady = ref.watch(themeProvider.select((t) => t.hasValue));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.lg,
      children: [
        const ColorThemeSelectorContent(),
        const FDivider(),
        SettingsGroup(
          title: l10n.appTextSize,
          subtitle: l10n.appTextSizeSubtitle,
          child: SemanticsScaleStepPicker(
            groupLabel: l10n.appTextSize,
            enabled: themeReady,
            previewSizes: AppTextScale.values
                .map((s) => 14 * s.scalar)
                .toList(),
            labels: [
              l10n.appTextSizeCompact,
              l10n.appTextSizeNormal,
              l10n.appTextSizeLarge,
              l10n.appTextSizeShortExtraLarge,
            ],
            selectedIndex: appTextScale.index,
            onChanged: (i) => ref
                .read(themeProvider.notifier)
                .setAppTextScale(AppTextScale.values[i]),
          ),
        ),
      ],
    );
  }
}

/// Final onboarding step showing today's prayer schedule preview.
class OnboardingFinishStep extends ConsumerWidget {
  /// Creates [OnboardingFinishStep].
  const OnboardingFinishStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = context.theme;
    final day = ref.watch(prayerDayProvider).value;
    final bundle = day?.bundle;
    final formatter = ref.watch(timeFormatterProvider);

    if (bundle == null) {
      final loading = ref.watch(prayerDayIsLoadingProvider);
      if (loading) {
        return const Center(child: FCircularProgress.loader());
      }
      return FAlert(
        icon: const Icon(FLucideIcons.triangleAlert),
        title: Text(l10n.onboardingFinishPreviewUnavailable),
      );
    }

    final prayers = <Prayer>[
      Prayer.fajr,
      Prayer.dhuhr,
      Prayer.asr,
      Prayer.maghrib,
      Prayer.isha,
    ];

    return StaticCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.sm,
        children: [
          Text(
            l10n.todaysSchedule,
            style: theme.typography.body.sm.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colors.mutedForeground,
            ),
          ),
          for (final prayer in prayers)
            _PrayerPreviewRow(
              label: prayer.getLocaleName(l10n, date: day?.now),
              time: formatter.format(bundle.today.timeForPrayer(prayer)),
            ),
        ],
      ),
    );
  }
}

class _PrayerPreviewRow extends StatelessWidget {
  const _PrayerPreviewRow({
    required this.label,
    required this.time,
  });

  final String label;
  final String time;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            time,
            style: theme.typography.body.sm.copyWith(
              fontWeight: FontWeight.w500,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
