/// The entry point of the application.
///
/// This function initializes the necessary bindings, sets up error handling,
/// initializes timezone data, and runs the application.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/logging/logger_provider.dart';
import 'package:hasanat/core/routing/route_provider.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/gen/fonts.gen.dart';
import 'package:hasanat/hive/hive_registrar.g.dart';
import 'package:hasanat/l10n/app_localizations.dart';
import 'package:hasanat/theme/theme.dart';
import 'package:hivez_flutter/hivez_flutter.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:window_manager/window_manager.dart';

/// The entry point of the application.
void main() async {
  // Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();
  await MushafReaderLibrary.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapters();

  // Set up error handling
  FlutterError.onError = (details) {
    logger.e(
      'Flutter error',
      error: details.exception,
      stackTrace: details.stack,
    );
  };
  // Initialize timezone data
  tz.initializeTimeZones();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    // Initialize window manager
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
    });
  }
  // Run the app
  runApp(const ProviderScope(child: TawaqApp()));
}

/// The root widget of the application.
///
/// This widget is responsible for setting up the application's theme,
/// localization, and routing.
class TawaqApp extends ConsumerWidget {
  /// Creates a new instance of [TawaqApp].
  const TawaqApp({super.key});

  // 1910x990

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the localization instance
    final appRouter = ref.watch(appRouterProvider);
    final locale = ref.watch(localeProvider);
    final appTheme = ref.watch(themeProvider);
    return ScreenUtilPlusInit(
      designSize: const Size(1908, 987),
      minTextAdapt: true,
      autoRebuild: false,
      enableScaleWH: () {
        if (ScreenUtilPlus().screenWidth < 1908 ||
            ScreenUtilPlus().screenHeight < 987) {
          return false;
        }
        return true;
      },
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          builder: (context, child) {
            final isArabic = locale.value?.languageCode == 'ar';
            final currentTheme =
                appTheme.value?.colorScheme ?? FThemes.zinc.light;
            var themeData = currentTheme;
            if (isArabic) {
              final typo = FTypography.inherit(
                colors: currentTheme.colors,
                defaultFontFamily: FontFamily.iBMPlexSansArabic,
              );
              // .scale(sizeScalar: 1.285);
              themeData = FThemeData(
                colors: currentTheme.colors,
                typography: typo,
                extensions: const [
                  AppRadii.standard(),
                  AppDurations.standard(),
                ],
              );
            } else {
              themeData = currentTheme.copyWith(
                extensions: const [
                  AppRadii.standard(),
                  AppDurations.standard(),
                ],
              );
            }
            return FTheme(data: themeData, child: child!);
          },
          themeMode: appTheme.value?.themeMode,
          // theme: appTheme.value?.colorScheme.toApproximateMaterialTheme(),
          onGenerateTitle: (context) =>
              AppLocalizations.of(context)?.appName ?? '',
          debugShowCheckedModeBanner: false,
          // theme: ThemeData(
          //     colorScheme:
          //         appTheme.mapOrNull(data: (data) => data.value.colorScheme) ??
          //             IslamicTheme.lightIslamic(),
          //     radius: 0.5,
          //     typography: _typography),
          // typography: locale.value?.languageCode == 'ar'
          //     ? const Typography.geist().copyWith(sans: GoogleFonts.readexPro())
          //     : const Typography.geist()),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            FLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          locale: locale.value,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: appRouter,
        );
      },
    );
  }
}
