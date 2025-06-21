import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  tz.initializeTimeZones();

  // ui.PlatformDispatcher.instance.onKeyData = (ui.KeyData data) {
  //   final metaLeft = LogicalKeyboardKey.metaLeft.keyId;
  //   final metaRight = LogicalKeyboardKey.metaRight.keyId;

  //   if (data.logical == metaLeft || data.logical == metaRight) {
  //     return true;
  //   }
  //   return false;
  // };
  runApp(ProviderScope(
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
  ));
}

final talker = TalkerFlutter.init();

class SeratiApp extends ConsumerWidget {
  const SeratiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the localization instance
    final appRouter = ref.watch(appRouterProvider);
    final appTheme = ref.watch(themeNotifierProvider);
    final locale = ref.watch(localeNotifierProvider);
    return ShadcnApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context)?.appName ?? "",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          colorScheme:
              appTheme.mapOrNull(data: (data) => data.value.colorScheme) ??
                  IslamicTheme.lightIslamic(),
          radius: 0.5,
          typography:
              const Typography.geist().copyWith(sans: GoogleFonts.readexPro())),
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
    );
  }
}
