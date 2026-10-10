/// Native captures of the real routes, isolated from the user's saved data.
/// Run: fvm flutter run -d linux -t tool/sage_visual_harness.dart
/// Add --dart-define=RESTORE_ONLY=true to verify persisted Sage after a run.
/// The fixed native render viewport is independent of compositor tiling.
/// Capture-only semantics exclusion avoids debug AT-SPI assertions; these
/// images do not verify screen-reader behavior.
/// Captures go to /tmp/tawaq-sage-review unless SAGE_REVIEW_DIR is set.
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/rendering.dart';
import 'package:hivez_flutter/hivez_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/app/routing/route_provider.dart';
import 'package:tawaq/core/bootstrap/app_init_providers.dart';
import 'package:tawaq/core/desktop/omarchy_theme_source.dart';
import 'package:tawaq/core/locale/locale_provider.dart';
import 'package:tawaq/core/widgets/page_shell/sidebar_settings_provider.dart';
import 'package:tawaq/feature/onboarding/presentation/providers/onboarding_state_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/provider/theme_settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/widgets/theme/app_theme_selector.dart';
import 'package:tawaq/hive/hive_registrar.g.dart';
import 'package:tawaq/main.dart';
import 'package:tawaq/theme/omarchy_theme_provider.dart';
import 'package:tawaq/theme/theme_model.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as timezone;
import 'package:window_manager/window_manager.dart';

final GlobalKey _captureKey = GlobalKey();
final _size = ValueNotifier<Size>(const Size(1200, 860));

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  final output = Directory(
    Platform.environment['SAGE_REVIEW_DIR'] ?? '/tmp/tawaq-sage-review',
  );
  await output.create(recursive: true);
  final data = await Directory('${output.path}/data').create(recursive: true);
  await MushafReaderLibrary.ensureInitialized(
    storageDirectory: Directory('${data.path}/quran'),
  );
  final container = ProviderContainer(
    overrides: [
      hiveCoreInitProvider.overrideWith((ref) async {
        Hive
          ..init(data.path)
          ..registerAdapters();
      }),
      omarchyThemeProvider.overrideWith(
        (ref) => Stream.value(const OmarchyThemeSnapshot.unavailable()),
      ),
    ],
  );
  await container.read(appBootstrapReadyProvider.future);
  await container.read(prayerSettingsProvider.future);
  await container
      .read(prayerSettingsProvider.notifier)
      .applyLocationBundle(
        coordinates: Coordinates(24.7136, 46.6753),
        locationName: 'Riyadh',
        location: timezone.getLocation('Asia/Riyadh'),
        autoLocation: false,
      );
  await container.read(themeProvider.future);
  if (const bool.fromEnvironment('RESTORE_ONLY')) {
    final prefs = await container.read(themeProvider.future);
    if (prefs.appPalette != AppPalette.sage ||
        prefs.themeMode != ThemeMode.dark) {
      throw StateError('Sage dark did not survive process restart: $prefs');
    }
    stdout.writeln('Sage dark restored from disk after process restart.');
    exit(0);
  }
  await container.read(localeProvider.future);
  await container.read(onboardingStateProvider.future);
  await container.read(onboardingStateProvider.notifier).finish();
  await windowManager.setMinimumSize(const Size(800, 600));
  await windowManager.setSize(const Size(1280, 940));
  await windowManager.show();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: ValueListenableBuilder<Size>(
        valueListenable: _size,
        builder: (context, size, child) => OverflowBox(
          minWidth: size.width,
          maxWidth: size.width,
          minHeight: size.height,
          maxHeight: size.height,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(size: size),
            child: RepaintBoundary(key: _captureKey, child: child),
          ),
        ),
        child: const ExcludeSemantics(child: TawaqApp()),
      ),
    ),
  );
  await Future<void>.delayed(const Duration(seconds: 3));
  final router = container.read(appRouterProvider);
  final errors = <String>[];
  final originalError = FlutterError.onError;
  FlutterError.onError = (details) {
    errors.add('${details.exception.runtimeType}\n${details.stack}');
    originalError?.call(details);
  };
  for (final palette in [AppPalette.manuscript, AppPalette.sage]) {
    container.read(themeProvider.notifier).setPalette(palette);
    for (final language in ['en', 'ar']) {
      container.read(localeProvider.notifier).setLocale(Locale(language));
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        container.read(themeProvider.notifier).setThemeMode(mode);
        for (final width in [1200.0, 800.0]) {
          // Resize on Prayer, away from the Material tab bar's scroll-mode
          // transition. Settle sidebar motion before capturing either width.
          router.go('/prayer');
          await Future<void>.delayed(const Duration(milliseconds: 300));
          await container.read(sidebarSettingsProvider.future);
          container
              .read(sidebarSettingsProvider.notifier)
              .setCollapsed(collapsed: true);
          await Future<void>.delayed(const Duration(milliseconds: 400));
          _size.value = Size(width, 860);
          await Future<void>.delayed(const Duration(milliseconds: 300));
          container
              .read(sidebarSettingsProvider.notifier)
              .setCollapsed(collapsed: width < 1024);
          await Future<void>.delayed(const Duration(milliseconds: 400));
          for (final route in [
            'prayer',
            'quran',
            'hadith',
            'muslim_fortress',
            'settings',
          ]) {
            router.go('/$route');
            await Future<void>.delayed(const Duration(seconds: 2));
            if (route == 'settings') {
              Element? selector;
              void visit(Element element) {
                if (element.widget is ColorThemeSelectorContent) {
                  selector = element;
                }
                element.visitChildren(visit);
              }

              _captureKey.currentContext!.visitChildElements(visit);
              if (selector != null) {
                await Scrollable.ensureVisible(selector!, alignment: 0.2);
                await Future<void>.delayed(const Duration(milliseconds: 300));
              }
            }
            await WidgetsBinding.instance.endOfFrame;
            final boundary =
                _captureKey.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await boundary.toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final name =
                '${palette.name}-$language-${mode.name}-${width.toInt()}-$route.png';
            await File('${output.path}/$name')
                .writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
            stdout.writeln('Captured $name');
          }
        }
      }
    }
  }
  await container.read(themeProvider.notifier).flush();
  await File('${output.path}/errors.txt').writeAsString(errors.join('\n\n'));
  container.dispose();
  exit(errors.isEmpty ? 0 : 1);
}
