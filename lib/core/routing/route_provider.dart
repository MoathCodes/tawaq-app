// ignore_for_file: avoid_build_context_in_providers
// import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/assets.dart';
import 'package:go_router/go_router.dart';
import 'package:hasanat/core/locale/locale_extension.dart';
import 'package:hasanat/core/logging/talker_provider.dart';
import 'package:hasanat/core/routing/route.dart';
import 'package:hasanat/core/theme/theme.dart';
import 'package:hasanat/core/widgets/not_found_page.dart';
import 'package:hasanat/core/widgets/page_shell/page_shell.dart';
import 'package:hasanat/feature/prayer/presentation/screens/prayer_page.dart';
import 'package:hasanat/feature/quran/presentation/screens/quran_page.dart';
import 'package:hasanat/feature/settings/presentation/pages/settings_page.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/feature/testpages/new_design.dart';
import 'package:hasanat/l10n/app_localizations.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'route_provider.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  final routes = [
    ...ref.read(mainRoutesProvider(null)),
    ...ref.read(secondaryRoutesProvider(null))
  ];
  final themeData = ref.read(themeNotifierProvider).valueOrNull ?? defaultTheme;
  final talker = ref.read(talkerNotifierProvider);
  final appRouter = GoRouter(
    observers: [
      TalkerRouteObserver(talker),
    ],
    routes: _generateRoutes(routes, themeData, talker),
    initialLocation: routes.first.path,
    // initialLocation: '/settings',
    // errorPageBuilder: (context, state) =>
    //     _buildErrorPage(context, state, themeData),
    // errorBuilder: (context, state) => NotFoundPage(
    //   errorMsg: state.error?.message ?? context.l10n.errorNotFoundPage,
    // ),
    errorPageBuilder: (context, state) => NoTransitionPage(
      key: state.pageKey,
      child: NotFoundPage(
        errorMsg: state.error?.message ?? context.l10n.errorNotFoundPage,
      ),
    ),
  );
  ref.onDispose(() {
    // Clean up resources if needed
    appRouter.dispose();
  });
  return appRouter;
}

@riverpod
List<AppRoute> mainRoutes(Ref ref, AppLocalizations? localization) {
  return [
    AppRoute(
      path: '/prayer',
      label: _labelLocalization(localization?.prayerTimes, 'مواقيت الصلاة'),
      icon: FIcons.clock,
      child: const PrayerPage(),
    ),
    AppRoute(
        path: '/quran',
        label: _labelLocalization(localization?.quran, 'القرآن'),
        icon: FIcons.book,
        child: const QuranPage()),
    AppRoute(
        path: '/muslim_fortress',
        label: _labelLocalization(localization?.muslimFortress, 'الحصن'),
        icon: FIcons.building,
        child: const QuranPage()),
    AppRoute(
        path: '/thkr',
        label: _labelLocalization(localization?.remembrance, 'الأذكار'),
        icon: FIcons.bell,
        child: const QuranPage()),
    AppRoute(
        path: '/hadith',
        label: _labelLocalization(localization?.hadith, "الحديث"),
        icon: FIcons.mic,
        child: const TawaqApp()),
  ];
}

@riverpod
List<AppRoute> secondaryRoutes(Ref ref, AppLocalizations? localization) {
  return [
    AppRoute(
        path: '/settings',
        label: _labelLocalization(localization?.settings, "الإعدادات"),
        icon: FIcons.settings,
        child: const SettingsPage()),
    AppRoute(
        path: '/about',
        label: _labelLocalization(localization?.about, "عن التطبيق"),
        icon: FIcons.info,
        child: const QuranPage()),
  ];
}

/// Reusable method to create a custom transition page
// CustomTransitionPage<T> _buildCustomTransitionPage<T>(
//     LocalKey key, Widget child, ThemeSettings themeData) {
//   return CustomTransitionPage<T>(
//     key: key,
//     child: child,
//     barrierDismissible: true,
//     // barrierColor: themeData.themeMode == ThemeMode.dark
//     //     ? const Color.fromARGB(24, 255, 255, 255)
//     //     : const Color.fromARGB(25, 0, 0, 0), // Subtle backdrop
//     opaque: false,
//     transitionDuration:
//         const Duration(milliseconds: 600), // Longer for smoothness
//     reverseTransitionDuration: const Duration(milliseconds: 400),
//     transitionsBuilder: (context, animation, secondaryAnimation, child) {
//       // macOS-style easing curves
//       final forwardCurve = CurvedAnimation(
//         parent: animation,
//         curve: const Cubic(0.2, 0.0, 0.0, 1.0), // macOS entrance curve
//         reverseCurve: const Cubic(0.4, 0.0, 1.0, 1.0), // macOS exit curve
//       );

//       // More subtle slide from top (5% instead of 10%)
//       final slideAnimation = Tween<Offset>(
//         begin: const Offset(0, -0.05),
//         end: Offset.zero,
//       ).animate(forwardCurve);

//       final scaleAnimation = Tween<double>(
//         begin: 0.94,
//         end: 1.0,
//       ).animate(forwardCurve);

//       final opacityAnimation = Tween<double>(
//         begin: 0.0,
//         end: 1.0,
//       ).animate(forwardCurve);

//       // Add a subtle blur effect during transition (optional)
//       final blurAnimation = Tween<double>(
//         begin: 2.0,
//         end: 0.0,
//       ).animate(CurvedAnimation(
//         parent: animation,
//         curve: const Cubic(0.2, 0.0, 0.2, 1.0),
//       ));

//       return AnimatedBuilder(
//         animation: animation,
//         builder: (context, child) {
//           return BackdropFilter(
//               filter: ImageFilter.blur(
//                 sigmaX: blurAnimation.value,
//                 sigmaY: blurAnimation.value,
//               ),
//               child: FadeTransition(
//                 opacity: opacityAnimation,
//                 child: SlideTransition(
//                   position: slideAnimation,
//                   child: ScaleTransition(
//                     scale: scaleAnimation,
//                     child: child,
//                   ),
//                 ),
//               ));
//         },
//         child: child,
//       );
//     },
//   );
// }

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
      pageBuilder: (context, state) => NoTransitionPage(
        key: state.pageKey,
        child: route.child,
      ),
    );

/// Generates the routes for the app
List<RouteBase> _generateRoutes(
        List<AppRoute> routes, ThemeSettings themeData, Talker talker) =>
    [
      GoRoute(
        path: '/test',
        builder: (context, state) => const TawaqApp(),
      ),
      ShellRoute(
        routes: [
          ...routes.map((route) => _buildGoRoute(route, themeData)),
          GoRoute(
              path: '/debug',
              builder: (context, state) {
                return TalkerScreen(talker: talker);
              }),
        ],
        builder: (context, state, child) => PageShell(child: child),
      ),
    ];

String _labelLocalization(String? localization, String initialLabel) =>
    localization ?? initialLabel;
