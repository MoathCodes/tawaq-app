import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/feature/onboarding/presentation/models/onboarding_steps.dart';

part 'onboarding_controller_provider.g.dart';

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
