import 'package:riverpod_annotation/experimental/json_persist.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/feature/onboarding/data/models/onboarding_state.dart';
import 'package:tawaq/feature/settings/data/repository/settings_storage.dart';
import 'package:tawaq/feature/settings/presentation/provider/prayer_settings_provider.dart';

part 'onboarding_state_provider.g.dart';

/// Persisted onboarding completion flag.
@Riverpod(keepAlive: true)
@JsonPersist()
class OnboardingStateNotifier extends _$OnboardingStateNotifier {
  @override
  Future<OnboardingState> build() async {
    await persist(
      ref.read(settingsStorageProvider),
      options: const StorageOptions(
        cacheTime: StorageCacheTime.unsafe_forever,
      ),
    ).future;
    if (!ref.mounted) return const OnboardingState();
    return state.value ?? const OnboardingState();
  }

  /// Marks onboarding as finished (complete flow or "Set up later").
  Future<void> finish() async {
    if (!state.hasValue) return;
    state = AsyncData(
      state.value!.copyWith(
        completed: true,
        completedAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  /// Clears completion so onboarding can run again from Settings.
  Future<void> reset() async {
    if (!state.hasValue) return;
    state = const AsyncData(OnboardingState());
  }
}

/// Pure onboarding gate used by [onboardingNeeded].
bool computeOnboardingNeeded({
  required bool onboardingLoading,
  required bool onboardingCompleted,
  required bool prayerLoading,
}) {
  if (onboardingLoading) return false;
  if (onboardingCompleted) return false;
  if (prayerLoading) return false;
  return true;
}

/// Whether first-run onboarding should be shown.
@Riverpod(keepAlive: true)
bool onboardingNeeded(Ref ref) {
  final onboarding = ref.watch(onboardingStateProvider);
  final prayer = ref.watch(prayerSettingsProvider);
  return computeOnboardingNeeded(
    onboardingLoading: onboarding.isLoading,
    onboardingCompleted: onboarding.value?.completed == true,
    prayerLoading: !prayer.hasValue,
  );
}
