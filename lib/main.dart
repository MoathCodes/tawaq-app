/// The entry point of the application.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:forui/forui.dart';
import 'package:hasanat/core/routing/route_provider.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/gen/fonts.gen.dart';
import 'package:hasanat/hive/hive_registrar.g.dart';
import 'package:hasanat/l10n/app_localizations.dart';
import 'package:hasanat/theme/theme.dart';
import 'package:hasanat/theme/theme_model.dart';
import 'package:hivez_flutter/hivez_flutter.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:window_manager/window_manager.dart';

/// Whether running on desktop platform.
bool get _isDesktop =>
    !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

/// The entry point of the application.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Future.wait([
    MushafReaderLibrary.ensureInitialized(subDirectory: 'tawaq'),
    Hive.initFlutter(),
  ]);
  Hive.registerAdapters();
  tz.initializeTimeZones();

  if (_isDesktop) await _initDesktopWindow();

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
    final resolvedTheme = themePrefs.value != null
        ? resolveColorScheme(
            themePrefs.value!.appPalette,
            themePrefs.value!.themeMode,
          )
        : FThemes.zinc.light;

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
        themeMode: themePrefs.value?.themeMode,
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
          data: _buildTheme(
            resolvedTheme,
            isArabic: locale.languageCode == 'ar',
          ),
          child: child!,
        ),
      ),
    );
  }

  FThemeData _buildTheme(FThemeData base, {required bool isArabic}) {
    const extensions = <ThemeExtension<dynamic>>[
      AppRadii.standard(),
      AppDurations.standard(),
    ];

    if (!isArabic) return base.copyWith(extensions: extensions);

    return FThemeData(
      colors: base.colors,
      typography: FTypography.inherit(
        colors: base.colors,
        defaultFontFamily: FontFamily.iBMPlexSansArabic,
      ),
      extensions: extensions,
    );
  }
}
