/// The entry point of the application.
library;

import 'package:dorar_hadith_flutter/dorar_hadith_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:hivez_flutter/hivez_flutter.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/core/desktop/desktop_shell.dart';
import 'package:tawaq/core/desktop/launch_at_login_service.dart';
import 'package:tawaq/core/routing/route_provider.dart';
import 'package:tawaq/core/utils/platform.dart';
import 'package:tawaq/core/widgets/tawaq_scroll_behavior.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/adhan/adhan_alert_host.dart';
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
  MpvAudioKit.ensureInitialized();

  if (isDesktopPlatform) {
    await initDesktopNotifications();
    await LaunchAtLoginService.setup();
    await _initDesktopWindow();
  }

  runApp(
    ProviderScope(
      child: isDesktopPlatform
          ? const DesktopShell(child: TawaqApp())
          : const TawaqApp(),
    ),
  );
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
    () async {},
  );
}

/// The root widget of the application.
class TawaqApp extends ConsumerWidget {
  /// Creates a new instance of [TawaqApp].
  const TawaqApp({super.key});

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
    );
    final materialTheme = appTheme.toApproximateMaterialTheme();
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      scrollBehavior: const TawaqAppScrollBehavior(),
      themeMode: themePrefs.value?.themeMode,
      theme: materialTheme.copyWith(
        scrollbarTheme: tawaqScrollbarTheme(materialTheme.colorScheme),
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
        child: FToaster(
          child: AdhanAlertHost(child: child!),
        ),
      ),
    );
  }
}
