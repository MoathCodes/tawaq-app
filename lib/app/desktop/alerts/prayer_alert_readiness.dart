import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tawaq/app/routing/route_provider.dart';
import 'package:tawaq/feature/onboarding/presentation/providers/onboarding_state_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/adhan_settings_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_day.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_settings_provider.dart';

/// App composition owns readiness; feature providers never import the router.
final prayerAlertsReadyProvider = Provider<bool>((ref) {
  final router = ref.watch(appRouterProvider);
  void changed() => ref.invalidateSelf();
  router.routeInformationProvider.addListener(changed);
  ref.onDispose(() => router.routeInformationProvider.removeListener(changed));
  final onboarding = ref.watch(onboardingStateProvider);
  final prayer = ref.watch(prayerSettingsProvider);
  final adhan = ref.watch(adhanSettingsProvider);
  final timelineReady = ref.watch(prayerDayProvider.select((day) => day.asData != null));
  return onboarding.asData?.value.completed == true &&
      !onboarding.isLoading && !prayer.isLoading && !adhan.isLoading &&
      adhan.hasValue && prayer.asData?.value.isLocationReady == true &&
      timelineReady &&
      router.routeInformationProvider.value.uri.path != '/onboarding';
});
