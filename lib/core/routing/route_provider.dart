// The GoRouter setup reads BuildContext for localization and error widgets.
// ignore_for_file: avoid_build_context_in_providers

import 'dart:async';

import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/bootstrap/app_init_providers.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/not_found_screen.dart';
import 'package:tawaq/core/widgets/page_shell/page_shell.dart';
import 'package:tawaq/feature/about/presentation/about_dialog.dart';
import 'package:tawaq/feature/about/presentation/screens/about_screen.dart';
import 'package:tawaq/feature/hadith/presentation/screens/hadith_screen.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/screens/muslim_fortress_screen.dart';
import 'package:tawaq/feature/onboarding/presentation/providers/onboarding_state_provider.dart';
import 'package:tawaq/feature/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:tawaq/feature/prayer/presentation/screens/prayer_screen.dart';
import 'package:tawaq/feature/quran/presentation/screens/quran_screen.dart';
import 'package:tawaq/feature/settings/presentation/models/settings_destination.dart';
import 'package:tawaq/feature/settings/presentation/screens/settings_screen.dart';
import 'package:tawaq/l10n/app_localizations.dart';

part 'route_provider.g.dart';

/// Route for the first-run onboarding screen.
@TypedGoRoute<OnboardingRoute>(path: '/onboarding')
@immutable
class OnboardingRoute extends GoRouteData with $OnboardingRoute {
  /// Creates the onboarding route.
  const OnboardingRoute();

  @override
  /// Builds the onboarding screen.
  Widget build(BuildContext context, GoRouterState state) {
    return const OnboardingScreen();
  }
}

/// Shell route that hosts the app's primary navigation destinations.
@TypedShellRoute<AppShellRoute>(
  routes: [
    TypedGoRoute<PrayerRoute>(path: '/prayer'),
    TypedGoRoute<QuranRoute>(path: '/quran'),
    TypedGoRoute<HadithRoute>(path: '/hadith'),
    TypedGoRoute<MuslimFortressRoute>(path: '/muslim_fortress'),
    TypedGoRoute<SettingsRoute>(path: '/settings'),
    TypedGoRoute<AboutRoute>(path: '/about'),
  ],
)
class AppShellRoute extends ShellRouteData {
  /// Creates the application shell route.
  const AppShellRoute();

  @override
  /// Builds the shell around the nested navigator.
  Widget builder(BuildContext context, GoRouterState state, Widget navigator) {
    return PageShell(child: navigator);
  }
}

/// Shared route base for app navigation metadata and page transitions.
abstract class AppNavigationRoute extends GoRouteData {
  /// Creates a navigation route with optional nested sub-routes.
  const AppNavigationRoute({this.subRoutes = const []});

  /// Nested routes that are considered part of this navigation branch.
  final List<AppNavigationRoute> subRoutes;

  /// The icon shown in navigation chrome for this route.
  IconData get icon;

  /// Returns the localized label for this route.
  String localizedLabel(AppLocalizations? localization);

  /// The current route location.
  String get path => location;

  /// Whether this destination can be activated from shell navigation.
  ///
  /// When false, shell chrome shows the route but disables its control.
  bool get navigationEnabled => true;

  /// Activates this destination from shell navigation.
  ///
  /// Defaults to navigating to the route. Override to run a custom action —
  /// e.g. showing a dialog — instead of changing the current route.
  void activate(BuildContext context) => go(context);

  /// Whether this route (or one of its nested sub-routes) matches [location].
  bool containsLocation(String? location) {
    if (location == null) return false;
    if (path == location) return true;
    return subRoutes.any((route) => route.containsLocation(location));
  }

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return NoTransitionPage<void>(
      key: state.pageKey,
      child: build(context, state),
    );
  }
}

/// Route for the prayer screen.
@immutable
class PrayerRoute extends AppNavigationRoute with $PrayerRoute {
  /// Creates the prayer route.
  const PrayerRoute();

  @override
  /// The prayer route icon.
  IconData get icon => FLucideIcons.clock;

  @override
  /// Returns the localized prayer label.
  String localizedLabel(AppLocalizations? localization) =>
      _labelLocalization(localization?.prayerTimes, 'مواقيت الصلاة');

  @override
  /// Builds the prayer screen.
  Widget build(BuildContext context, GoRouterState state) {
    return const PrayerScreen();
  }
}

/// Route for the Quran screen.
@immutable
class QuranRoute extends AppNavigationRoute with $QuranRoute {
  /// Creates the Quran route.
  const QuranRoute();

  @override
  /// The Quran route icon.
  IconData get icon => FLucideIcons.book;

  @override
  /// Returns the localized Quran label.
  String localizedLabel(AppLocalizations? localization) =>
      _labelLocalization(localization?.quran, 'القرآن');

  @override
  /// Builds the Quran screen.
  Widget build(BuildContext context, GoRouterState state) {
    return const QuranScreen();
  }
}

/// Route for the hadith screen.
@immutable
class HadithRoute extends AppNavigationRoute with $HadithRoute {
  /// Creates the hadith route.
  const HadithRoute({this.$extra});

  /// Extra hadiths used when the route is opened in specific-list mode.
  final List<DetailedHadith>? $extra;

  @override
  /// The hadith route icon.
  IconData get icon => FLucideIcons.mic;

  @override
  /// Returns the localized hadith label.
  String localizedLabel(AppLocalizations? localization) =>
      _labelLocalization(localization?.hadith, 'الأحاديث');

  @override
  /// Builds the hadith page.
  Widget build(BuildContext context, GoRouterState state) {
    return HadithPage(
      initialHadiths: $extra ?? const <DetailedHadith>[],
    );
  }
}

/// Route for the Muslim Fortress screen.
@immutable
class MuslimFortressRoute extends AppNavigationRoute with $MuslimFortressRoute {
  /// Creates the Muslim Fortress route.
  const MuslimFortressRoute();

  @override
  IconData get icon => FLucideIcons.shield;

  @override
  String localizedLabel(AppLocalizations? localization) =>
      _labelLocalization(localization?.muslimFortress, 'حصن المسلم');

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const MuslimFortressScreen();
  }
}

/// Route for the settings screen.
@immutable
class SettingsRoute extends AppNavigationRoute with $SettingsRoute {
  /// Creates the settings route.
  const SettingsRoute({this.$extra});

  /// Optional settings tab to open; null restores the persisted tab.
  final SettingsDestination? $extra;

  @override
  /// The settings route icon.
  IconData get icon => FLucideIcons.settings;

  @override
  /// Returns the localized settings label.
  String localizedLabel(AppLocalizations? localization) =>
      _labelLocalization(localization?.settings, 'الإعدادات');

  @override
  /// Builds the settings screen.
  Widget build(BuildContext context, GoRouterState state) {
    return SettingsScreen(section: $extra);
  }
}

/// Route for the about screen.
@immutable
class AboutRoute extends AppNavigationRoute with $AboutRoute {
  /// Creates the about route.
  const AboutRoute();

  @override
  /// The about route icon.
  IconData get icon => FLucideIcons.info;

  @override
  /// Returns the localized about label.
  String localizedLabel(AppLocalizations? localization) =>
      _labelLocalization(localization?.about, 'عن التطبيق');

  @override
  /// Opens the about dialog instead of navigating to a route.
  void activate(BuildContext context) =>
      unawaited(showAboutAppDialog(context));

  @override
  /// Builds the about screen (fallback for direct `/about` navigation).
  Widget build(BuildContext context, GoRouterState state) {
    return const AboutScreen();
  }
}

/// Configures the root [GoRouter] used by the application shell.
@riverpod
GoRouter appRouter(Ref ref) {
  final refresh = ValueNotifier(0);
  ref
    ..listen(appBootstrapReadyProvider, (_, _) => refresh.value++)
    ..listen(onboardingStateProvider, (_, _) => refresh.value++)
    ..listen(onboardingNeededProvider, (_, _) => refresh.value++);

  final onboardingPath = const OnboardingRoute().location;

  final appRouter = GoRouter(
    routes: $appRoutes,
    initialLocation: const PrayerRoute().location,
    refreshListenable: refresh,
    redirect: (context, state) {
      final bootstrap = ref.read(appBootstrapReadyProvider);
      if (!bootstrap.hasValue) return null;

      final onOnboarding = state.matchedLocation == onboardingPath;
      final needed = ref.read(onboardingNeededProvider);

      if (needed && !onOnboarding) return onboardingPath;
      if (!needed && onOnboarding) return const PrayerRoute().location;
      return null;
    },
    errorPageBuilder: (context, state) => NoTransitionPage(
      key: state.pageKey,
      child: NotFoundScreen(
        errorMsg: state.error?.message ?? context.l10n.errorNotFoundPage,
      ),
    ),
  );
  ref
    ..onDispose(appRouter.dispose)
    ..onDispose(refresh.dispose);
  return appRouter;
}

/// Returns the main navigation destinations shown in the primary shell.
@riverpod
List<AppNavigationRoute> mainRoutes(Ref ref) {
  return const [
    PrayerRoute(),
    QuranRoute(),
    HadithRoute(),
    MuslimFortressRoute(),
  ];
}

/// Returns secondary destinations rendered in the application shell.
@riverpod
List<AppNavigationRoute> secondaryRoutes(Ref ref) {
  return const [
    SettingsRoute(),
    AboutRoute(),
  ];
}

/// Returns the localized label if available,
///  otherwise returns the initial label.
String _labelLocalization(String? localization, String initialLabel) =>
    localization ?? initialLabel;
