/// The entry point of the application.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/core/bootstrap/app_init_providers.dart';
import 'package:tawaq/core/desktop/desktop_shell.dart';
import 'package:tawaq/core/desktop/single_instance.dart';
import 'package:tawaq/core/locale/locale_provider.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/core/routing/route_provider.dart';
import 'package:tawaq/core/utils/platform.dart';
import 'package:tawaq/core/widgets/tawaq_scroll_behavior.dart';
import 'package:tawaq/feature/onboarding/presentation/providers/onboarding_state_provider.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/adhan/adhan_alert_host.dart';
import 'package:tawaq/feature/settings/presentation/provider/prayer_settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/provider/theme_settings_provider.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:timezone/data/latest.dart' as tz;

/// The entry point of the application.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MushafReaderLibrary.ensureInitialized(subDirectory: 'tawaq');
  await ensureSingleDesktopInstance();
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
    // Keep the splash up until route-gate settings hydrate so GoRouter never
    // decides onboarding vs /prayer during the loading gap (hot restart).
    final onboarding = ref.watch(onboardingStateProvider);
    final prayer = ref.watch(prayerSettingsProvider);
    final themeapp = ref.watch(appThemeDataProvider);
    final materialTheme = themeapp.toApproximateMaterialTheme();

    // Forui 0.24 widgets (FScaffold, FCircularProgress, …) read
    // FAccessibilityScope via FTheme — wrap splash/error shells too.
    Widget foruiShell({required Widget child}) => FTheme(
      data: themeapp,
      child: child,
    );

    Widget splash() => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: materialTheme,
      home: foruiShell(
        child: const FScaffold(
          child: Center(child: FCircularProgress.loader()),
        ),
      ),
    );

    return bootstrap.when(
      loading: splash,
      error: (error, _) => MaterialApp(
        theme: materialTheme,
        debugShowCheckedModeBanner: false,
        home: foruiShell(
          child: FScaffold(child: Center(child: Text('$error'))),
        ),
      ),
      data: (_) {
        if (onboarding.isLoading || !prayer.hasValue) return splash();
        return isDesktopPlatform
            ? const DesktopShell(child: TawaqApp())
            : const TawaqApp();
      },
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
    final langCode = ref.watch(localeProvider).value ?? 'en';
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
          child: _AutoLocationLifecycle(
            child: AdhanAlertHost(child: child ?? const SizedBox.shrink()),
          ),
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

/// Refreshes GPS when auto-location is on and the app returns to foreground.
class _AutoLocationLifecycle extends ConsumerStatefulWidget {
  const _AutoLocationLifecycle({required this.child});

  final Widget child;

  @override
  ConsumerState<_AutoLocationLifecycle> createState() =>
      _AutoLocationLifecycleState();
}

class _AutoLocationLifecycleState
    extends ConsumerState<_AutoLocationLifecycle> {
  late final AppLifecycleListener _listener;
  var _refreshing = false;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(onResume: _onResume);
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  Future<void> _onResume() async {
    if (_refreshing) return;
    final settings = ref.read(prayerSettingsProvider).value;
    if (settings == null || !settings.autoLocation) return;

    _refreshing = true;
    try {
      await ref
          .read(prayerSettingsProvider.notifier)
          .applyCurrentDeviceLocation();
    } on Object catch (error, stack) {
      ref.read(loggerProvider).w(
        '[AutoLocationLifecycle] resume refresh failed',
        error: error,
        stackTrace: stack,
      );
    } finally {
      _refreshing = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
