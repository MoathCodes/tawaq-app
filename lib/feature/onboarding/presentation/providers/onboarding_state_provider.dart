import 'package:riverpod_annotation/experimental/json_persist.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/locale/locale_provider.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/core/storage/settings_storage.dart';
import 'package:tawaq/feature/onboarding/data/models/onboarding_state.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/provider/theme_settings_provider.dart';

part 'onboarding_state_provider.g.dart';

const String _onboardingLogPrefix = '[OnboardingStateNotifier]';

/// Persisted onboarding completion flag.
@Riverpod(keepAlive: true)
@JsonPersist()
class OnboardingStateNotifier extends _$OnboardingStateNotifier {
  @override
  Future<OnboardingState> build() async {
    try {
      await persist(
        ref.watch(settingsStorageProvider.future),
        options: kSettingsPersistForever,
      ).future;
    } on Object catch (error, stack) {
      ref
          .read(loggerProvider)
          .e(
            '$_onboardingLogPrefix hydrate failed; using empty state',
            error: error,
            stackTrace: stack,
          );
    }
    if (!ref.mounted) return const OnboardingState();
    return state.value ?? const OnboardingState();
  }

  /// Marks onboarding as finished (complete flow or "Set up later").
  ///
  /// Returns `false` when state is not yet hydrated — callers must not
  /// navigate on a no-op (avoids redirect bounce). Flushes prayer/theme/locale
  /// first so kill-after-finish still sees those prefs, then writes
  /// `completed` last.
  Future<bool>? _finishing;

  Future<bool> finish() => _finishing ??= _finish().whenComplete(() {
    _finishing = null;
  });

  Future<bool> _finish() async {
    if (!state.hasValue) return false;
    // Every preference edited in setup is required, including appearance.
    // A failed write propagates to the recoverable setup UI.
    await ref.read(prayerSettingsProvider.future);
    if (!ref.mounted) return false;
    await ref.read(prayerSettingsProvider.notifier).flush();
    await ref.read(themeProvider.future);
    if (!ref.mounted) return false;
    await ref.read(themeProvider.notifier).flush();
    await ref.read(localeProvider.future);
    if (!ref.mounted) return false;
    await ref.read(localeProvider.notifier).flush();
    if (!ref.mounted) return false;
    final next = state.requireValue.copyWith(
      completed: true,
      completedAt: DateTime.now().toIso8601String(),
    );
    final storage = await ref.read(settingsStorageProvider.future);
    if (!ref.mounted) return false;
    await flushPersistedValue(storage, key, next);
    if (!ref.mounted) return false;
    state = AsyncData(next);
    return true;
  }

  /// Clears completion so onboarding can run again.
  ///
  /// This is the **only** reopen API — the prayer location setup alert and
  /// the settings rerun tile must call [reset] before navigating to
  /// `/onboarding`. Returns `false` when state is not yet hydrated — callers
  /// must not navigate.
  Future<bool> reset() async {
    if (_finishing != null) await _finishing;
    if (!ref.mounted) return false;
    if (!state.hasValue) return false;
    const next = OnboardingState();
    final storage = await ref.read(settingsStorageProvider.future);
    if (!ref.mounted) return false;
    await flushPersistedValue(storage, key, next);
    if (!ref.mounted) return false;
    state = const AsyncData(next);
    return true;
  }

  /// Awaits a durable disk write of the current onboarding state.
  ///
  /// Do not use `await persist().future` — that waits for decode on first
  /// build, not a mutation write flush.
  Future<void> flush() async {
    final value = state.value;
    if (value == null) return;
    final storage = await ref.read(settingsStorageProvider.future);
    if (!ref.mounted) return;
    await flushPersistedValue(storage, key, value);
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
///
/// Soft location recovery stays on the prayer alert + explicit
/// [OnboardingStateNotifier.reset] — completing onboarding (including
/// "Set up later") does not force `/onboarding` every launch when
/// coordinates are still missing.
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
