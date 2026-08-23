import 'package:freezed_annotation/freezed_annotation.dart';

part 'onboarding_state.freezed.dart';
part 'onboarding_state.g.dart';

/// Persisted onboarding completion state.
@freezed
abstract class OnboardingState with _$OnboardingState {
  /// Creates [OnboardingState].
  const factory({
    @Default(false) bool completed,
    String? completedAt,
  }) = _OnboardingState;

  /// Parses from JSON persisted in Hive.
  factory fromJson(Map<String, dynamic> json) =>
      _$OnboardingStateFromJson(json);
}
