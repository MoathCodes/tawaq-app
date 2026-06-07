/// The entry point of the application.
library;

import 'package:dorar_hadith_flutter/dorar_hadith_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:forui/forui.dart';
import 'package:hivez_flutter/hivez_flutter.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/core/routing/route_provider.dart';
import 'package:tawaq/core/utils/platform.dart';
import 'package:tawaq/core/widgets/tawaq_scroll_behavior.dart';
import 'package:tawaq/feature/settings/data/models/theme_prefs.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/hive/hive_registrar.g.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:window_manager/window_manager.dart';

bool get _isTouchThemePlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.fuchsia);

/// The entry point of the application.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Future.wait([
    DorarHadithFlutter.ensureInitialized(),
    MushafReaderLibrary.ensureInitialized(subDirectory: 'tawaq'),
    Hive.initFlutter(),
  ]);
  Hive.registerAdapters();
  tz.initializeTimeZones();

  if (isDesktopPlatform) await _initDesktopWindow();

  runApp(const ProviderScope(child: TawaqApp()));
}

Future<void> _initDesktopWindow() async {
  await windowManager.ensureInitialized();
  await windowManager.waitUntilReadyToShow(
    const WindowOptions(
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    ),
    windowManager.show,
  );
}

/// The root widget of the application.
class TawaqApp extends ConsumerWidget {
  /// Creates a new instance of [TawaqApp].
  const TawaqApp({super.key});

  static const _designSize = Size(1908, 987);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appRouter = ref.watch(appRouterProvider);
    final langCode = ref.watch(localeProvider);
    final themePrefs = ref.watch(themeProvider);
    final locale = Locale(langCode);
    final useTouchTheme = _isTouchThemePlatform;
    final prefs = themePrefs.value ?? ThemePrefs.defaults();
    final appTheme = buildAppTheme(
      palette: prefs.appPalette,
      themeMode: prefs.themeMode,
      touch: useTouchTheme,
      textScale: prefs.appTextScale.scalar,
      isArabic: locale.languageCode == 'ar',
    );
    return ScreenUtilPlusInit(
      designSize: _designSize,
      minTextAdapt: true,
      autoRebuild: false,
      splitScreenMode: true,
      enableScaleWH: () =>
          ScreenUtilPlus().screenWidth >= _designSize.width &&
          ScreenUtilPlus().screenHeight >= _designSize.height,
      builder: (_, _) => MaterialApp.router(
        debugShowCheckedModeBanner: false,
        scrollBehavior: const TawaqAppScrollBehavior(),
        themeMode: themePrefs.value?.themeMode,
        theme: appTheme.toApproximateMaterialTheme().copyWith(
          scrollbarTheme: const ScrollbarThemeData(
            thumbVisibility: WidgetStatePropertyAll(false),
            trackVisibility: WidgetStatePropertyAll(false),
          ),
        ),
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: appRouter,
        onGenerateTitle: (ctx) => AppLocalizations.of(ctx)?.appName ?? '',
        localizationsDelegates: const [
          AppLocalizations.delegate,
          FLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (_, child) => FTheme(
          data: appTheme,
          child: child!,
        ),
      ),
    );
  }
}
