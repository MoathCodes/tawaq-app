import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hasanat/core/locale/arabic_delegate.dart';
import 'package:hasanat/core/routing/route_provider.dart';
import 'package:hasanat/core/theme/custom_themes.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/l10n/app_localizations.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
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
                  settings: const TalkerRiverpodLoggerSettings(
                    printStateFullData: true,
                    // providerFilter: (provider) {
                    //   // return provider.name != prayerCardProvider.name;
                    // },
                  )),
            ],
            child: const SeratiApp(),
          )), (error, stackTrace) {
    talker.handle(error, stackTrace);
  });
}

final talker = TalkerFlutter.init();

Typography _typography = const Typography.geist().copyWith(
  sans: GoogleFonts.readexPro(),
  xSmall: TextStyle(fontSize: 12.sp),
  small: TextStyle(fontSize: 14.sp),
  base: TextStyle(fontSize: 16.sp),
  large: TextStyle(fontSize: 18.sp),
  xLarge: TextStyle(fontSize: 20.sp),
  x2Large: TextStyle(fontSize: 24.sp),
  x3Large: TextStyle(fontSize: 30.sp),
  x4Large: TextStyle(fontSize: 36.sp),
  x5Large: TextStyle(fontSize: 48.sp),
  x6Large: TextStyle(fontSize: 60.sp),
  x7Large: TextStyle(fontSize: 72.sp),
  x8Large: TextStyle(fontSize: 96.sp),
  x9Large: TextStyle(fontSize: 144.sp),
  h1: TextStyle(fontSize: 36.sp, fontWeight: FontWeight.w800),
  h2: TextStyle(fontSize: 30.sp, fontWeight: FontWeight.w600),
  h3: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w600),
  h4: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
  p: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w400),
  blockQuote: TextStyle(
      fontSize: 16.sp,
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.italic),
  inlineCode: TextStyle(
      fontFamily: 'GeistMono', fontSize: 14.sp, fontWeight: FontWeight.w600),
  lead: TextStyle(fontSize: 22.sp),
  textLarge: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w600),
  textSmall: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
  textMuted: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w400),
);

class SeratiApp extends ConsumerWidget {
  const SeratiApp({super.key});

// 1910x990

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the localization instance
    final appRouter = ref.watch(appRouterProvider);
    final appTheme = ref.watch(themeNotifierProvider);
    final locale = ref.watch(localeNotifierProvider);
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
      builder: (context, child) => ShadcnApp.router(
        onGenerateTitle: (context) =>
            AppLocalizations.of(context)?.appName ?? "",
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            colorScheme:
                appTheme.mapOrNull(data: (data) => data.value.colorScheme) ??
                    IslamicTheme.lightIslamic(),
            radius: 0.5,
            typography: _typography),
        // typography: locale.value?.languageCode == 'ar'
        //     ? const Typography.geist().copyWith(sans: GoogleFonts.readexPro())
        //     : const Typography.geist()),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ArabicShadcnDelegate.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        locale: locale.value,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: appRouter,
      ),
    );
  }
}
