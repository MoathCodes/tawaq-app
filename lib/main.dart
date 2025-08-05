import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/routing/route_provider.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_card/prayer_card_provider.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/l10n/app_localizations.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  // WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    talker.handle(details.exception, details.stack);
  };

  tz.initializeTimeZones();

  // ui.PlatformDispatcher.instance.onKeyData = (ui.KeyData data) {
  //   final metaLeft = LogicalKeyboardKey.metaLeft.keyId;
  //   final metaRight = LogicalKeyboardKey.metaRight.keyId;

  //   if (data.logical == metaLeft || data.logical == metaRight) {
  //     return true;
  //   }
  //   return false;
  // };
  runTalkerZonedGuarded(
      talker,
      () => runApp(ProviderScope(
            observers: [
              TalkerRiverpodObserver(
                  talker: talker,
                  settings: TalkerRiverpodLoggerSettings(
                    printStateFullData: true,
                    providerFilter: (provider) {
                      return provider.name != prayerCardProvider.name;
                    },
                  )),
            ],
            child: const SeratiApp(),
          )), (error, stackTrace) {
    talker.handle(error, stackTrace);
  });
}

final talker = TalkerFlutter.init();

class SeratiApp extends ConsumerWidget {
  const SeratiApp({super.key});

// 1910x990

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the localization instance
    final appRouter = ref.watch(appRouterProvider);
    final locale = ref.watch(localeNotifierProvider);
    final appTheme = ref.watch(themeNotifierProvider);
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
            bool isArabic = locale.value?.languageCode == 'ar';
            final currentTheme =
                appTheme.value?.colorScheme ?? FThemes.zinc.light;
            FThemeData themeData = currentTheme;
            if (isArabic) {
              final typo = FTypography.inherit(
                  colors: currentTheme.colors,
                  defaultFontFamily: 'IBMPlexSansArabic');
              // .scale(sizeScalar: 1.285);
              themeData =
                  FThemeData(colors: currentTheme.colors, typography: typo);
            }
            return FTheme(
              data: themeData,
              child: child!,
            );
          },
          themeMode: appTheme.value?.themeMode,
          onGenerateTitle: (context) =>
              AppLocalizations.of(context)?.appName ?? "",
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
