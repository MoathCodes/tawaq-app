import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/feature/settings/data/models/prayer_settings_model.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';

part 'onboarding_controller_provider.g.dart';

/// Total onboarding steps (welcome through finish).
const int kOnboardingStepCount = 8;

/// Location step index — Continue is blocked until coordinates are set.
const int kOnboardingLocationStep = 2;

/// UI state for the onboarding stepper.
class OnboardingControllerState {
  /// Creates [OnboardingControllerState].
  const OnboardingControllerState({
    required this.step,
    required this.slideDirection,
  });

  /// Active step index (0–[kOnboardingStepCount] - 1).
  final int step;

  /// `1` = backward, `-1` = forward (for directional step transitions).
  final int slideDirection;

  /// Initial step.
  static const initial = OnboardingControllerState(step: 0, slideDirection: -1);
}

/// Ephemeral onboarding navigation state.
@riverpod
class OnboardingController extends _$OnboardingController {
  @override
  OnboardingControllerState build() => OnboardingControllerState.initial;

  /// Whether the user can advance from the current step.
  bool canContinue() {
    if (state.step == kOnboardingLocationStep) {
      final settings = ref.read(prayerSettingsProvider).value;
      return settings?.isLocationReady ?? false;
    }
    return true;
  }

  /// Advances to the next step.
  void next() {
    if (state.step >= kOnboardingStepCount - 1) return;
    state = OnboardingControllerState(
      step: state.step + 1,
      slideDirection: -1,
    );
  }

  /// Goes back one step.
  void back() {
    if (state.step <= 0) return;
    state = OnboardingControllerState(
      step: state.step - 1,
      slideDirection: 1,
    );
  }
}
