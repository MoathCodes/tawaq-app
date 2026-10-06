/// The entry point of the application.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/app/audio_interruption_composition.dart';
import 'package:tawaq/app/desktop/alerts/adhan_alert_host.dart';
import 'package:tawaq/app/desktop/desktop_quit_failure_host.dart';
import 'package:tawaq/app/desktop/desktop_shell.dart';
import 'package:tawaq/app/routing/route_provider.dart';
import 'package:tawaq/core/bootstrap/app_init_providers.dart';
import 'package:tawaq/core/locale/locale_provider.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/core/storage/settings_storage.dart';
import 'package:tawaq/core/widgets/empty_state_panel.dart';
import 'package:tawaq/core/widgets/tawaq_scroll_behavior.dart';
import 'package:tawaq/feature/onboarding/presentation/providers/onboarding_state_provider.dart';
import 'package:tawaq/feature/prayer/data/database/prayer_database.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/provider/theme_settings_provider.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/l10n/app_localizations_delegates.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';
import 'package:timezone/data/latest.dart' as tz;

/// The entry point of the application.
Future<void> main() async {
  if (const bool.fromEnvironment('ENABLE_FLUTTER_DRIVER')) {
    enableFlutterDriverExtension();
  } else {
    WidgetsFlutterBinding.ensureInitialized();
  }
  LicenseRegistry.addLicense(() async* {
    for (final family in [
      'IBM_Plex_Sans_Arabic',
      'Noto_Sans',
      'Noto_Sans_Bengali',
      'Noto_Sans_SC',
      'Noto_Nastaliq_Urdu',
    ]) {
      yield LicenseEntryWithLineBreaks([
        family,
      ], await rootBundle.loadString('assets/fonts/$family/OFL.txt'));
    }
  });
  tz.initializeTimeZones();
  runApp(const ProviderScope(child: AppBootstrap()));
}

/// Minimal shell until Hive and desktop services are ready.
class AppBootstrap extends ConsumerWidget {
  /// Creates [AppBootstrap].
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(appBootstrapReadyProvider);
    // Keep the splash up until route-gate settings hydrate so GoRouter never
    // decides onboarding vs /prayer during the loading gap (hot restart).
    final onboarding = ref.watch(onboardingStateProvider);
    final prayer = ref.watch(prayerSettingsProvider);
    final themeapp = ref.watch(appThemeDataProvider);
    final materialTheme = buildAppMaterialTheme(
      themeapp,
      palette: ref.watch(
        themeProvider.select(
          (t) => t.value?.appPalette ?? AppPalette.manuscript,
        ),
      ),
    );
    final isDesktopPlatform = [
      TargetPlatform.windows,
      TargetPlatform.linux,
      TargetPlatform.macOS,
    ].contains(defaultTargetPlatform);

    // Forui 0.24 widgets (FScaffold, FCircularProgress, …) read
    // FAccessibilityScope via FTheme — wrap splash/error shells too.
    Widget foruiShell({required Widget child}) =>
        FTheme(data: themeapp, child: child);

    Widget splash() => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: materialTheme,
      home: foruiShell(
        child: const FScaffold(
          child: Center(child: FCircularProgress.loader()),
        ),
      ),
    );

    Widget recovery({
      required String Function(AppLocalizations) message,
      required VoidCallback onRetry,
    }) => MaterialApp(
      theme: materialTheme,
      debugShowCheckedModeBanner: false,
      locale: Locale(ref.watch(localeProvider).value ?? 'en'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: foruiShell(
        child: Builder(
          builder: (context) => FScaffold(
            child: Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: ErrorStatePanel(
                    message: message(AppLocalizations.of(context)!),
                    retryLabel: AppLocalizations.of(context)!.retryAction,
                    onRetry: onRetry,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return bootstrap.when(
      skipLoadingOnRefresh: false,
      loading: splash,
      error: (_, _) => recovery(
        message: (l10n) => l10n.appStartupFailed,
        onRetry: () {
          // Invalidate the failed source as well as the gate. Rebuilding only
          // the gate would await the same cached initialization failure.
          if (ref.exists(mushafInitProvider) &&
              ref.read(mushafInitProvider).hasError) {
            ref.invalidate(mushafInitProvider);
          }
          if (ref.exists(hiveCoreInitProvider) &&
              ref.read(hiveCoreInitProvider).hasError) {
            ref.invalidate(hiveCoreInitProvider);
          }
          if (ref.exists(desktopShellInitProvider) &&
              ref.read(desktopShellInitProvider).hasError) {
            ref.invalidate(desktopShellInitProvider);
          }
          ref.invalidate(appBootstrapReadyProvider);
        },
      ),
      data: (_) {
        if ((!onboarding.isLoading && onboarding.hasError) ||
            (!prayer.isLoading && prayer.hasError)) {
          return recovery(
            message: (l10n) => l10n.appStartupFailed,
            onRetry: () {
              if (ref.exists(settingsStorageProvider) &&
                  ref.read(settingsStorageProvider).hasError) {
                ref.invalidate(settingsStorageProvider);
              }
              if (onboarding.hasError) ref.invalidate(onboardingStateProvider);
              if (prayer.hasError) ref.invalidate(prayerSettingsProvider);
            },
          );
        }
        if (onboarding.isLoading || !prayer.hasValue) return splash();
        final history = ref.watch(prayerHistoryReadyProvider);
        if (history.isLoading) return splash();
        if (history.hasError) {
          return recovery(
            message: (l10n) => l10n.prayerHistoryStartupFailed,
            onRetry: () => ref.invalidate(prayerHistoryReadyProvider),
          );
        }
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
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(audioInterruptionCompositionProvider);
    final appRouter = ref.watch(appRouterProvider);
    final langCode = ref.watch(localeProvider).value ?? 'en';
    final themeMode = ref.watch(
      themeProvider.select((t) => t.value?.themeMode ?? ThemeMode.light),
    );
    final appTheme = ref.watch(appThemeDataProvider);
    final locale = Locale(langCode);
    final materialTheme = buildAppMaterialTheme(
      appTheme,
      palette: ref.watch(
        themeProvider.select(
          (t) => t.value?.appPalette ?? AppPalette.manuscript,
        ),
      ),
    );
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
      localizationsDelegates: appLocalizationsDelegates,
      builder: (_, child) => MaterialUiCompatibilityBridge(
        child: _AppTextScaleScope(
          child: FToaster(
            child: _AutoLocationLifecycle(
              child: DesktopQuitFailureHost(
                child: AdhanAlertHost(child: child ?? const SizedBox.shrink()),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Keeps the animated Forui theme mounted while app theme data changes.
class _AppTextScaleScope extends ConsumerWidget {
  const new({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(appThemeWithTextScaleProvider);
    return FTheme(data: theme, child: child);
  }
}

/// Refreshes GPS when auto-location is on and the app returns to foreground.
class _AutoLocationLifecycle extends ConsumerStatefulWidget {
  const new({required this.child});

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
      ref
          .read(loggerProvider)
          .w(
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
