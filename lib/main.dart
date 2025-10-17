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
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/routing/route_provider.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_card/prayer_card_provider.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/gen/fonts.gen.dart';
import 'package:hasanat/l10n/app_localizations.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:window_manager/window_manager.dart';

void main() async {
  // Initialize Talker first, before any other initialization

  // Run everything inside the Talker zone from the beginning
  runTalkerZonedGuarded(talker, () async {
    // Initialize Flutter bindings inside the zone
    WidgetsFlutterBinding.ensureInitialized();

    // Set up error handling
    FlutterError.onError = (details) {
      talker.handle(details.exception, details.stack);
    };

    // Initialize timezone data
    tz.initializeTimeZones();

    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      // Initialize window manager
      await windowManager.ensureInitialized();

      const windowOptions = WindowOptions(
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.hidden,
      );

      windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    }
    // Run the app
    runApp(
      ProviderScope(
        observers: [
          TalkerRiverpodObserver(
            talker: talker,
            settings: TalkerRiverpodLoggerSettings(
              providerFilter: (provider) {
                return provider.name != prayerCardProvider.name;
              },
            ),
          ),
        ],
        child: const TawaqApp(),
      ),
    );
  }, talker.handle);
}

/// The Talker instance for logging and error handling.
final Talker talker = TalkerFlutter.init();

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
    return ScreenUtilInit(
      designSize: const Size(1908, 987),
      minTextAdapt: true,
      enableScaleWH: () {
        if (ScreenUtil().screenWidth < 1908 ||
            ScreenUtil().screenHeight < 987) {
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
              );
            }
            return FTheme(data: themeData, child: child!);
          },
          themeMode: appTheme.value?.themeMode,
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
