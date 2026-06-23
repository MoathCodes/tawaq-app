import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/onboarding/presentation/providers/onboarding_state_provider.dart';

void main() {
  group('computeOnboardingNeeded', () {
    test('is false while onboarding or prayer settings are loading', () {
      expect(
        computeOnboardingNeeded(
          onboardingLoading: true,
          onboardingCompleted: false,
          prayerLoading: false,
        ),
        isFalse,
      );
      expect(
        computeOnboardingNeeded(
          onboardingLoading: false,
          onboardingCompleted: false,
          prayerLoading: true,
        ),
        isFalse,
      );
    });

    test('is false when onboarding already completed', () {
      expect(
        computeOnboardingNeeded(
          onboardingLoading: false,
          onboardingCompleted: true,
          prayerLoading: false,
        ),
        isFalse,
      );
    });

    test('is true until onboarding is completed', () {
      expect(
        computeOnboardingNeeded(
          onboardingLoading: false,
          onboardingCompleted: false,
          prayerLoading: false,
        ),
        isTrue,
      );
    });
  });
}
