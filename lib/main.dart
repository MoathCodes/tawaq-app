/// The entry point of the application.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/core/bootstrap/app_init_providers.dart';
import 'package:tawaq/core/desktop/desktop_shell.dart';
import 'package:tawaq/core/locale/locale_provider.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/core/routing/route_provider.dart';
import 'package:tawaq/core/utils/platform.dart';
import 'package:tawaq/core/widgets/tawaq_scroll_behavior.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/adhan/adhan_alert_host.dart';
import 'package:tawaq/feature/settings/presentation/provider/theme_settings_provider.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:timezone/data/latest.dart' as tz;

/// The entry point of the application.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MushafReaderLibrary.ensureInitialized();
  await initFileLogging();
  tz.initializeTimeZones();
  runApp(const ProviderScope(child: AppBootstrap()));
}

/// Minimal shell until Hive and desktop services are ready.
class AppBootstrap extends ConsumerWidget {
  /// Creates [AppBootstrap].
  const AppBootstrap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(appBootstrapReadyProvider);
    final themeapp = ref.watch(appThemeDataProvider);
    final materialTheme = themeapp.toApproximateMaterialTheme();
    return bootstrap.when(
      loading: () => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: materialTheme,
        home: const FScaffold(child: Center(child: FCircularProgress.loader())),
      ),
      error: (error, _) => MaterialApp(
        theme: materialTheme,
        debugShowCheckedModeBanner: false,
        home: FScaffold(child: Center(child: Text('$error'))),
      ),
      data: (_) => isDesktopPlatform
          ? const DesktopShell(child: TawaqApp())
          : const TawaqApp(),
    );
  }
}

/// The root widget of the application.
class TawaqApp extends ConsumerWidget {
  /// Creates a new instance of [TawaqApp].
  const TawaqApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appRouter = ref.watch(appRouterProvider);
    final langCode = ref.watch(localeProvider);
    final themeMode = ref.watch(
      themeProvider.select((t) => t.value?.themeMode ?? ThemeMode.light),
    );
    final appTheme = ref.watch(appThemeDataProvider);
    final locale = Locale(langCode);
    final materialTheme = appTheme.toApproximateMaterialTheme();
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      scrollBehavior: const TawaqAppScrollBehavior(),
      themeMode: themeMode,
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
      builder: (_, child) => _AppTextScaleScope(
        child: FToaster(
          child: AdhanAlertHost(child: child!),
        ),
      ),
    );
  }
}

/// Rebuilds only when app text scale changes, not on palette/mode/router edits.
class _AppTextScaleScope extends ConsumerWidget {
  const _AppTextScaleScope({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(appThemeWithTextScaleProvider);
    return FTheme(data: theme, child: child);
  }
}
