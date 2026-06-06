// The GoRouter setup reads BuildContext for localization and error widgets.
// ignore_for_file: avoid_build_context_in_providers

import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/widgets/not_found_screen.dart';
import 'package:tawaq/core/widgets/page_shell/page_shell.dart';
import 'package:tawaq/feature/hadith/presentation/screens/hadith_screen.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/screens/muslim_fortress_screen.dart';
import 'package:tawaq/feature/prayer/presentation/screens/prayer_screen.dart';
import 'package:tawaq/feature/quran/presentation/screens/quran_screen.dart';
import 'package:tawaq/feature/settings/presentation/screens/settings_screen.dart';
import 'package:tawaq/feature/settings/presentation/screens/start_wizard.dart';
import 'package:tawaq/l10n/app_localizations.dart';

part 'route_provider.g.dart';

/// Route for the startup wizard screen.
@TypedGoRoute<WizardRoute>(path: '/wizard')
@immutable
class WizardRoute extends GoRouteData with $WizardRoute {
  /// Creates the wizard route.
  const WizardRoute();

  @override
  /// Builds the startup wizard screen.
  Widget build(BuildContext context, GoRouterState state) {
    return const StartedScreen();
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

  /// Whether this route (or one of its nested sub-routes) matches [location].
  bool containsLocation(String? location) {
    if (location == null) return false;
    if (path == location) return true;
    return subRoutes.any((route) => route.containsLocation(location));
  }

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return _buildDesktopTransitionPage(
      state.pageKey,
      build(context, state),
      barrierColor: FTheme.of(context).colors.background,
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
  const SettingsRoute();

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
    return const SettingsScreen();
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
  /// Builds the about screen.
  Widget build(BuildContext context, GoRouterState state) {
    return const QuranScreen();
  }
}

/// Configures the root [GoRouter] used by the application shell.
@riverpod
GoRouter appRouter(Ref ref) {
  final appRouter = GoRouter(
    routes: $appRoutes,
    initialLocation: const PrayerRoute().location,
    errorPageBuilder: (context, state) => NoTransitionPage(
      key: state.pageKey,
      child: NotFoundScreen(
        errorMsg: state.error?.message ?? context.l10n.errorNotFoundPage,
      ),
    ),
  );
  ref.onDispose(appRouter.dispose);
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

/// A desktop-style transition that fades in the content with a subtle slide
/// and scale effect.
CustomTransitionPage<void> _buildDesktopTransitionPage(
  LocalKey key,
  Widget child, {
  required Color barrierColor,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    barrierColor: barrierColor,
    opaque: false,
    transitionDuration: const Duration(milliseconds: 400),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final motion = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final fade = CurvedAnimation(
        parent: animation,
        curve: Curves.linearToEaseOut,
        reverseCurve: Curves.easeIn,
      );

      final slide = Tween<Offset>(
        begin: const Offset(0, 0.02),
        end: Offset.zero,
      ).animate(motion);
      final scale = Tween<double>(begin: 0.985, end: 1).animate(motion);

      return FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(fade),
        child: SlideTransition(
          position: slide,
          child: ScaleTransition(
            scale: scale,
            child: child,
          ),
        ),
      );
    },
  );
}

/// Returns the localized label if available,
///  otherwise returns the initial label.
String _labelLocalization(String? localization, String initialLabel) =>
    localization ?? initialLabel;
