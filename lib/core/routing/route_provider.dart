// The GoRouter setup reads BuildContext for localization and error widgets.
// ignore_for_file: avoid_build_context_in_providers
// import 'dart:ui';
// raghad is so wow

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/logging/logger_provider.dart';
import 'package:hasanat/core/routing/route.dart';
import 'package:hasanat/core/widgets/not_found_screen.dart';
import 'package:hasanat/core/widgets/page_shell/page_shell.dart';
import 'package:hasanat/feature/prayer/presentation/screens/prayer_screen.dart';
import 'package:hasanat/feature/quran/presentation/screens/quran_screen.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/feature/settings/presentation/screens/settings_screen.dart';
import 'package:hasanat/feature/settings/presentation/screens/start_wizard.dart';
import 'package:hasanat/l10n/app_localizations.dart';
import 'package:hasanat/theme/theme_model.dart';
import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'route_provider.g.dart';

/// Configures the root [GoRouter] used by the application shell.
@riverpod
GoRouter appRouter(Ref ref) {
  final routes = [
    ...ref.read(mainRoutesProvider(null)),
    ...ref.read(secondaryRoutesProvider(null)),
  ];
  final themeData = ref.read(themeSettingsFromPrefsProvider);
  final log = ref.read(loggerProvider);
  final appRouter = GoRouter(
    routes: _generateRoutes(routes, themeData, log),
    initialLocation: routes.first.path,
    // initialLocation: '/settings',
    // errorPageBuilder: (context, state) =>
    //     _buildErrorPage(context, state, themeData),
    // errorBuilder: (context, state) => NotFoundPage(
    //   errorMsg: state.error?.message ?? context.l10n.errorNotFoundPage,
    // ),
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
List<AppRoute> mainRoutes(Ref ref, AppLocalizations? localization) {
  return [
    AppRoute(
      path: '/prayer',
      label: _labelLocalization(localization?.prayerTimes, 'مواقيت الصلاة'),
      icon: FIcons.clock,
      child: const PrayerScreen(),
    ),
    AppRoute(
      path: '/quran',
      label: _labelLocalization(localization?.quran, 'القرآن'),
      icon: FIcons.book,
      child: const QuranScreen(),
    ),
    // AppRoute(
    //   path: '/muslim_fortress',
    //   label: _labelLocalization(localization?.muslimFortress, 'الحصن'),
    //   icon: FIcons.building,
    //   child: const QuranScreen(),
    // ),
    // AppRoute(
    //   path: '/thkr',
    //   label: _labelLocalization(localization?.remembrance, 'الأذكار'),
    //   icon: FIcons.bell,
    //   child: const QuranScreen(),
    // ),
    AppRoute(
      path: '/hadith',
      label: _labelLocalization(localization?.hadith, 'الحديث'),
      icon: FIcons.mic,
      child: const QuranScreen(),
    ),
  ];
}

/// Returns secondary destinations rendered in the application shell.
@riverpod
List<AppRoute> secondaryRoutes(Ref ref, AppLocalizations? localization) {
  return [
    AppRoute(
      path: '/settings',
      label: _labelLocalization(localization?.settings, 'الإعدادات'),
      icon: FIcons.settings,
      child: const SettingsScreen(),
    ),
    AppRoute(
      path: '/about',
      label: _labelLocalization(localization?.about, 'عن التطبيق'),
      icon: FIcons.info,
      child: const QuranScreen(),
    ),
  ];
}

/// Builds a GoRoute for a given AppRoute
GoRoute _buildGoRoute(AppRoute route, ThemeSettings themeData) => GoRoute(
  path: route.path,
  name: route.label,
  // pageBuilder: (context, state) => _buildCustomTransitionPage(
  //   state.pageKey,
  //   route.child,
  //   themeData,
  // ),
  // pageBuilder: (context, state) => MaterialPage(
  //   key: state.pageKey,
  //   child: route.child,
  // ),
  // builder: (context, state) => route.child,
  pageBuilder: (context, state) {
    final theme = FTheme.of(context);
    // Use theme-aware surface color for a tasteful fade backdrop
    final overlay = theme.colors.background;
    return _desktopTransitionPage(
      state.pageKey,
      route.child,
      barrierColor: overlay,
    );
  },
);

/// A desktop-style transition that fades in the content with a subtle slide
/// and scale effect.
CustomTransitionPage<T> _desktopTransitionPage<T>(
  LocalKey key,
  Widget child, {
  required Color barrierColor,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    barrierColor: barrierColor, // theme-aware
    opaque: false, // allow the barrier to show
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

      // Subtle depth and slide for desktop feel
      final slide = Tween<Offset>(
        begin: const Offset(0, 0.02), // ~2% height
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

/// Generates the routes for the app.
List<RouteBase> _generateRoutes(
  List<AppRoute> routes,
  ThemeSettings themeData,
  Logger log,
) => [
  // GoRoute(
  //   path: '/test',
  //   builder: (context, state) => const TawaqApp(),
  // ),
  GoRoute(
    path: '/wizard',
    builder: (context, state) => const StartedScreen(),
  ),
  ShellRoute(
    routes: [
      ...routes.map((route) => _buildGoRoute(route, themeData)),
    ],
    builder: (context, state, child) => PageShell(child: child),
  ),
];

/// Returns the localized label if available,
///  otherwise returns the initial label.
String _labelLocalization(String? localization, String initialLabel) =>
    localization ?? initialLabel;
