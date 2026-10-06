/// Native captures of the real routes, isolated from the user's saved data.
/// Run: fvm flutter run -d linux -t tool/launch_visual_harness.dart
/// Place this process's native window in a floating test workspace first.
/// Capture-only semantics exclusion avoids debug AT-SPI assertions; these
/// images do not verify screen-reader behavior.
/// Captures go to /tmp/tawaq-launch-d62d0f64 unless LAUNCH_REVIEW_DIR is set.
library;

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:adhan_dart/adhan_dart.dart';
import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/share/hadith_share_card.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/results/hadith_result_card.dart';
import 'package:tawaq/feature/hadith/presentation/models/hadith_share_include.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/quran_search_field.dart';
import 'package:tawaq/feature/quran/presentation/models/quran_ui_models.dart';
import 'package:forui/forui.dart';
import 'package:hivez_flutter/hivez_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/app/routing/route_provider.dart';
import 'package:tawaq/app/desktop/desktop_shutdown.dart';
import 'package:tawaq/app/desktop/alerts/prayer_alert_dispatcher.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_alert_event.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_alert_kind.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/provider/fortress_screen_settings_provider.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_screen_state.dart';

import 'package:tawaq/app/onboarding/onboarding_screen.dart';
import 'package:tawaq/core/bootstrap/app_init_providers.dart';
import 'package:tawaq/core/desktop/omarchy_theme_source.dart';
import 'package:tawaq/core/locale/locale_provider.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/utils/app_clock_provider.dart';
import 'package:tawaq/core/utils/external_link_provider.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/hero_header/prayer_hero_header.dart';
import 'package:tawaq/core/widgets/page_shell/sidebar_settings_provider.dart';
import 'package:tawaq/core/widgets/mouse_click.dart';
import 'package:tawaq/core/layout/lazy_tab_content.dart';
import 'package:tawaq/feature/onboarding/presentation/providers/onboarding_state_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_settings_provider.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_settings.dart';
import 'package:tawaq/feature/prayer/data/database/prayer_database.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/schedule_row/schedule_alert_picker.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/schedule_status_chips.dart';
import 'package:tawaq/feature/about/presentation/about_dialog.dart';
import 'package:tawaq/feature/about/presentation/screens/about_screen.dart';
import 'package:tawaq/feature/about/presentation/widgets/about_view.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_screen_settings_provider.dart';
import 'package:tawaq/feature/hadith/presentation/screens/hadith_screen.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/share/hadith_share_dialog.dart';
import 'package:tawaq/feature/muslim_fortress/data/repository/fortress_repository.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/provider/muslim_fortress_provider.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/screens/muslim_fortress_screen.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/browse/fortress_browse_sidebar.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/browse/fortress_category_detail.dart';
import 'package:tawaq/core/shortcuts/shortcuts.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/share/fortress_share_dialog.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/share/fortress_share_card.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/study/fortress_dua_insights.dart';
import 'package:tawaq/feature/settings/presentation/models/settings_tabs.dart';
import 'package:tawaq/feature/prayer/presentation/provider/location_service_provider.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_screen_settings_provider.dart';
import 'package:tawaq/feature/settings/presentation/widgets/prayer_section/widgets/custom_parameters_content.dart';
import 'package:tawaq/feature/settings/presentation/provider/theme_settings_provider.dart';
import 'package:tawaq/feature/settings/data/models/app_text_scale.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_notes_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_header_widget.dart';
import 'package:tawaq/feature/quran/presentation/widgets/study/study_panel.dart';
import 'package:tawaq/feature/quran/presentation/widgets/study/notes_section.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/dialogs/offline_files_dialog.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/dialogs/range_repeat_dialog.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/dialogs/reciter_dialog.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/dialogs/sleep_timer_dialog.dart';
import 'package:tawaq/feature/quran/presentation/widgets/share/ayah_share_dialog.dart';
import 'package:tawaq/feature/settings/presentation/widgets/theme/app_theme_selector.dart';
import 'package:tawaq/hive/hive_registrar.g.dart';
import 'package:tawaq/main.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/omarchy_theme_provider.dart';
import 'package:tawaq/theme/theme_model.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as timezone;
import 'package:window_manager/window_manager.dart';

final GlobalKey _captureKey = GlobalKey();
final _reviewSharhAttempts = <String, int>{};

Future<void> main() async {
  try {
    await captureMain();
  } catch (error, stack) {
    stderr.writeln('$error\n$stack');
    exit(1);
  }
}

Future<void> captureMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  final output = Directory(
    Platform.environment['LAUNCH_REVIEW_DIR'] ?? '/tmp/tawaq-launch-d62d0f64',
  );
  await output.create(recursive: true);
  final data = await Directory('${output.path}/data').create(recursive: true);
  await MushafReaderLibrary.ensureInitialized(
    subDirectory: 'tawaq-launch-d62d0f64',
  );
  final container = ProviderContainer(
    retry: const bool.fromEnvironment('HADITH_REVIEW') ? (_, _) => null : null,
    overrides: [
      if (const bool.fromEnvironment('FINAL_FIXES_REVIEW'))
        deviceLocationAvailableProvider.overrideWith((ref) async => false),
      if (const bool.fromEnvironment('HADITH_REVIEW'))
        hadithDetailProvider.overrideWith((ref, argument) async {
          final (kind, id) = argument;
          if (kind != HadithDetailKind.sharh || !id.startsWith('review-sharh-'))
            throw StateError('No synthetic detail fixture for this request');
          await Future<void>.delayed(const Duration(milliseconds: 150));
          final attempt = _reviewSharhAttempts.update(
            id,
            (value) => value + 1,
            ifAbsent: () => 1,
          );
          if (attempt == 1)
            throw StateError('Synthetic selected-detail network failure');
          return const Sharh(
            hadith: ExplainedHadith(
              hadith: 'Synthetic UI fixture',
              rawi: '-',
              mohdith: 'Fixture scholar',
              book: 'Fixture source',
              numberOrPage: '1',
              grade: 'Fixture judgment',
            ),
            sharhMetadata: SharhMetadata(
              id: 'review-sharh',
              isContainSharh: true,
              sharh: 'Synthetic UI review fixture — optional commentary successfully loaded.',
            ),
          );
        }),
      if (const bool.fromEnvironment('EDGE_SCENARIOS'))
        externalLinkLauncherProvider.overrideWithValue((uri) async => false),
      appClockProvider.overrideWith(
        (ref) => Stream.value(DateTime.utc(2026, 10, 3, 9, 12)),
      ),
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
  await container.read(prayerHistoryReadyProvider.future);
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
  await container.read(localeProvider.future);
  await container.read(onboardingStateProvider.future);
  await container.read(onboardingStateProvider.notifier).finish();
  await windowManager.setMinimumSize(const Size(800, 600));
  await windowManager.setSize(const Size(1200, 860));
  await windowManager.show();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: RepaintBoundary(
        key: _captureKey,
        child:
            (const bool.fromEnvironment('EDGE_SCENARIOS') ||
                Platform.environment['LAUNCH_REDUCED_MOTION'] == 'true')
            ? Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(disableAnimations: true),
                  child: const ExcludeSemantics(child: TawaqApp()),
                ),
              )
            : const ExcludeSemantics(child: TawaqApp()),
      ),
    ),
  );
  await Future<void>.delayed(const Duration(seconds: 3));
  final router = container.read(appRouterProvider);
  final errors = <String>[];
  var scenario = 'bootstrap';
  final originalError = FlutterError.onError;
  FlutterError.onError = (details) {
    final owners = <String>[];
    for (final diagnostic
        in details.informationCollector?.call() ?? const <DiagnosticsNode>[]) {
      if (diagnostic.value case final RenderObject object) {
        if (object.debugCreator case final DebugCreator creator) {
          creator.element.visitAncestorElements((element) {
            owners.add(element.widget.runtimeType.toString());
            return owners.length < 45;
          });
          void collectText(Element element) {
            if (element.widget case Text(:final data))
              owners.add('Text: $data');
            element.visitChildren(collectText);
          }

          collectText(creator.element);
        }
      }
    }
    errors.add('Scenario: $scenario\nOwners: ${owners.join(' → ')}\n$details');
    originalError?.call(details);
  };
  if (const bool.fromEnvironment('FINAL_FIXES_REVIEW')) {
    await reviewFinalFixes(
      container,
      output,
      errors,
      (value) => scenario = value,
    );
    container.dispose();
    exit(errors.isEmpty ? 0 : 1);
  }
  if (const bool.fromEnvironment('QURAN_REVIEW') ||
      const bool.fromEnvironment('QURAN_PERFORMANCE') ||
      const bool.fromEnvironment('QURAN_MOTION')) {
    await reviewQuran(container, output, errors, (value) => scenario = value);
    container.dispose();
    exit(errors.isEmpty ? 0 : 1);
  }
  if (const bool.fromEnvironment('UI_FOLLOWUP_REVIEW')) {
    await reviewFortress(
      container,
      output,
      errors,
      (value) => scenario = value,
    );
    await reviewHadith(container, output, errors, (value) => scenario = value);
    container.dispose();
    exit(errors.isEmpty ? 0 : 1);
  }
  if (const bool.fromEnvironment('FORTRESS_REVIEW')) {
    await reviewFortress(
      container,
      output,
      errors,
      (value) => scenario = value,
    );
    container.dispose();
    exit(errors.isEmpty ? 0 : 1);
  }
  if (const bool.fromEnvironment('HADITH_REVIEW')) {
    await reviewHadith(container, output, errors, (value) => scenario = value);
    container.dispose();
    exit(errors.isEmpty ? 0 : 1);
  }
  final durabilityMode = Platform.environment['LAUNCH_DURABILITY_MODE'];
  if (durabilityMode != null) {
    const reflection = 'Launch kill-boundary reflection';
    await container.read(quranNotesStoreProvider.future);
    if (durabilityMode == 'write') {
      final store = container.read(quranNotesStoreProvider.notifier);
      store.edit(1, reflection);
      await store.flushAyah(1);
      await File('${output.path}/durability-ack.json').writeAsString(
        jsonEncode({
          'pid': pid,
          'ayah_id': 1,
          'text': reflection,
          'boundary': 'flushAyah completed',
        }),
        flush: true,
      );
      stdout.writeln(
        'Durable reflection acknowledged; awaiting owned-process kill',
      );
      await Completer<void>().future;
    } else if (durabilityMode == 'read') {
      final note = container
          .read(quranNotesStoreProvider)
          .requireValue
          .persisted[1];
      if (note?.text != reflection)
        throw StateError('Durable reflection did not restore');
      await File('${output.path}/durability-restored.json').writeAsString(
        jsonEncode({
          'pid': pid,
          'ayah_id': 1,
          'text': note!.text,
          'boundary': 'new process hydration',
        }),
        flush: true,
      );
      router.go('/quran');
      await Future<void>.delayed(const Duration(seconds: 2));
      Element? header;
      void visit(Element element) {
        if (element.widget is QuranHeaderWidget) header = element;
        element.visitChildren(visit);
      }

      _captureKey.currentContext!.visitChildElements(visit);
      if (header == null)
        throw StateError('Quran header not mounted after reopen');
      (header!.widget as QuranHeaderWidget).onNotes!();
      await Future<void>.delayed(const Duration(milliseconds: 900));
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          _captureKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('${output.path}/durability-restored-notes.png')
          .writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
      await File('${output.path}/errors.txt')
          .writeAsString(errors.join('\n\n'));
      container.dispose();
      exit(errors.isEmpty ? 0 : 1);
    } else {
      throw ArgumentError.value(durabilityMode, 'LAUNCH_DURABILITY_MODE');
    }
  }
  if (const bool.fromEnvironment('EDGE_SCENARIOS')) {
    container
        .read(themeProvider.notifier)
        .setAppTextScale(AppTextScale.extraLarge);
    List<Element> findMounted(bool Function(Widget) matches, [Element? scope]) {
      final found = <Element>[];
      void visit(Element element) {
        if (element.widget case Offstage(offstage: true)) return;
        if (matches(element.widget)) found.add(element);
        element.visitChildren(visit);
      }

      visit(scope ?? _captureKey.currentContext! as Element);
      return found;
    }

    Future<void> captureEdge(String name) async {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          _captureKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final rendered = await boundary.toImage();
      final data = await rendered.toByteData(format: ui.ImageByteFormat.png);
      await File('${output.path}/$name.png')
          .writeAsBytes(data!.buffer.asUint8List());
      rendered.dispose();
      stdout.writeln('Captured $name');
    }

    for (final language in ['en', 'ar']) {
      container.read(localeProvider.notifier).setLocale(Locale(language));
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        container.read(themeProvider.notifier).setThemeMode(mode);
        router.go('/prayer');
        await resizeOwnedWindow(const Size(1200, 860));
        await Future<void>.delayed(const Duration(seconds: 3));
        final hero = findMounted((widget) => widget is PrayerHeroHeader).single;
        final trigger =
            findMounted(
                  (widget) => widget is MouseClick && widget.onClick != null,
                  hero,
                ).single.widget
                as MouseClick;
        trigger.onClick!();
        await captureEdge('edge-$language-${mode.name}-hero-status-reduced');
        final currentHero = findMounted((widget) => widget is PrayerHeroHeader)
            .single;
        final currentTrigger =
            findMounted(
                  (widget) => widget is MouseClick && widget.onClick != null,
                  currentHero,
                ).single.widget
                as MouseClick;
        currentTrigger.onClick!();
        await Future<void>.delayed(const Duration(milliseconds: 350));
        router.go('/about');
        await resizeOwnedWindow(const Size(800, 600));
        await Future<void>.delayed(const Duration(seconds: 1));
        final about = findMounted((widget) => widget is AboutView).single;
        final link = findMounted(
          (widget) => widget is FTile && widget.onPress != null,
          about,
        ).first;
        await Scrollable.ensureVisible(link, alignment: .25);
        (link.widget as FTile).onPress!();
        await captureEdge('edge-$language-${mode.name}-about-link-failure');
        final navigator = Navigator.of(link, rootNavigator: true);
        if (!navigator.canPop())
          throw StateError('About link recovery did not open');
        navigator.pop();
        await Future<void>.delayed(const Duration(milliseconds: 350));
      }
    }
    await File('${output.path}/errors.txt').writeAsString(errors.join('\n\n'));
    container.dispose();
    exit(errors.isEmpty ? 0 : 1);
  }
  if (const bool.fromEnvironment('PERFORMANCE')) {
    final performanceSize = Size(
      double.parse(Platform.environment['PERFORMANCE_WIDTH'] ?? '1200'),
      double.parse(Platform.environment['PERFORMANCE_HEIGHT'] ?? '860'),
    );
    await resizeOwnedWindow(performanceSize);
    final timings = <ui.FrameTiming>[];
    void collect(List<ui.FrameTiming> frames) => timings.addAll(frames);
    WidgetsBinding.instance.addTimingsCallback(collect);
    final events = File('${output.path}/performance-events.jsonl').openWrite();
    final routes = [
      'prayer',
      'quran',
      'hadith',
      'muslim_fortress',
      'settings',
      'about',
    ];
    for (var cycle = -3; cycle < 20; cycle++) {
      events.writeln(
        jsonEncode({
          'cycle': cycle,
          'at': DateTime.now().toUtc().toIso8601String(),
        }),
      );
      if (cycle == 0) timings.clear();
      for (final route in routes) {
        router.go('/$route');
        await WidgetsBinding.instance.endOfFrame;
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
    }
    await Future<void>.delayed(const Duration(seconds: 1));
    WidgetsBinding.instance.removeTimingsCallback(collect);
    await events.close();
    double percentile(List<double> values, double fraction) {
      if (values.isEmpty) return 0;
      values.sort();
      return values[((values.length - 1) * fraction).ceil()];
    }

    final build = timings
        .map((t) => t.buildDuration.inMicroseconds / 1000)
        .toList();
    final raster = timings
        .map((t) => t.rasterDuration.inMicroseconds / 1000)
        .toList();
    await File('${output.path}/performance-frames.json').writeAsString(
      jsonEncode({
        'build_mode': const bool.fromEnvironment('dart.vm.product')
            ? 'release'
            : 'profile',
        'viewport': {
          'width': performanceSize.width,
          'height': performanceSize.height,
        },
        'cycles': 20,
        'routes': routes,
        'frames': timings.length,
        'ui_p95_ms': percentile(build, .95),
        'ui_p99_ms': percentile(build, .99),
        'raster_p95_ms': percentile(raster, .95),
        'raster_p99_ms': percentile(raster, .99),
        'missed_60hz_fraction': timings.isEmpty
            ? null
            : timings
                      .where(
                        (t) =>
                            t.buildDuration.inMicroseconds > 16667 ||
                            t.rasterDuration.inMicroseconds > 16667,
                      )
                      .length /
                  timings.length,
        'ui_max_ms': percentile(build, 1),
        'raster_max_ms': percentile(raster, 1),
        'errors': errors,
        'scope': 'Programmatic warm route cycles; capture-only semantics excluded; no input-to-frame claim.',
      }),
      flush: true,
    );
    container.dispose();
    exit(errors.isEmpty ? 0 : 1);
  }
  const compactOnly = bool.fromEnvironment('COMPACT_ONLY');
  const xl = bool.fromEnvironment('XL_TEXT');
  container
      .read(themeProvider.notifier)
      .setAppTextScale(xl ? AppTextScale.extraLarge : AppTextScale.normal);
  final palettes = const bool.fromEnvironment('ALL_PALETTES')
      ? [AppPalette.manuscript, AppPalette.neutral, AppPalette.sage]
      : [AppPalette.manuscript];
  for (final palette in palettes) {
    container.read(themeProvider.notifier).setPalette(palette);
    for (final language in ['en', 'ar']) {
      container.read(localeProvider.notifier).setLocale(Locale(language));
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        container.read(themeProvider.notifier).setThemeMode(mode);
        for (final width in compactOnly ? [800.0] : [1200.0, 800.0, 1440.0]) {
          // Resize on Prayer, away from the Material tab bar's scroll-mode
          // transition. Settle sidebar motion before capturing either width.
          scenario = '${palette.name}-$language-${mode.name}-$width-resize';
          router.go('/prayer');
          await Future<void>.delayed(const Duration(milliseconds: 300));
          await container.read(sidebarSettingsProvider.future);
          container
              .read(sidebarSettingsProvider.notifier)
              .setCollapsed(collapsed: true);
          await Future<void>.delayed(const Duration(milliseconds: 400));
          final targetSize = Size(
            width,
            width == 800
                ? 600
                : width == 1440
                ? 900
                : 860,
          );
          await resizeOwnedWindow(targetSize);
          final deadline = DateTime.now().add(const Duration(seconds: 3));
          var adjustedPixelRounding = false;
          while (true) {
            final view = WidgetsBinding.instance.platformDispatcher.views.first;
            final actual = view.physicalSize / view.devicePixelRatio;
            if (actual == targetSize) break;
            // GTK/Wayland can round the mapped buffer one pixel differently
            // from compositor geometry. Correct the owned outer window once;
            // record actual buffer dimensions when the minimum width prevents
            // correcting a one-pixel compositor rounding difference.
            if (!adjustedPixelRounding &&
                (actual.width - targetSize.width).abs() <= 1 &&
                (actual.height - targetSize.height).abs() <= 1) {
              adjustedPixelRounding = true;
              await resizeOwnedWindow(
                Size(
                  targetSize.width * 2 - actual.width,
                  targetSize.height * 2 - actual.height,
                ),
              );
            }
            if (DateTime.now().isAfter(deadline)) {
              if ((actual.width - targetSize.width).abs() <= 1 &&
                  (actual.height - targetSize.height).abs() <= 1) {
                stdout.writeln(
                  'Viewport rounding: requested $targetSize, captured $actual',
                );
                break;
              }
              throw StateError(
                'Native viewport was not resized: $actual, expected $targetSize',
              );
            }
            await Future<void>.delayed(const Duration(milliseconds: 50));
          }
          await Future<void>.delayed(const Duration(milliseconds: 300));
          container
              .read(sidebarSettingsProvider.notifier)
              .setCollapsed(collapsed: width < 1024);
          await Future<void>.delayed(const Duration(milliseconds: 400));
          for (final route
              in [
                'prayer',
                'quran',
                'hadith',
                'muslim_fortress',
                'settings',
                'about',
              ].where(
                (route) =>
                    Platform.environment['LAUNCH_ROUTE_FILTER'] == null ||
                    Platform.environment['LAUNCH_ROUTE_FILTER']!
                        .split(',')
                        .contains(route),
              )) {
            scenario = '${palette.name}-$language-${mode.name}-$width-$route';
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
                '${palette.name}-$language-${mode.name}-${width.toInt()}${xl ? '-xl' : ''}-$route.png';
            await File('${output.path}/$name')
                .writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
            stdout.writeln('Captured $name');
            Future<void> captureState(String state) async {
              await Future<void>.delayed(const Duration(milliseconds: 900));
              await WidgetsBinding.instance.endOfFrame;
              final boundary =
                  _captureKey.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary;
              final captured = await boundary.toImage();
              final data = await captured.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await File(
                '${output.path}/${name.replaceFirst('-$route.png', '-$state.png')}',
              ).writeAsBytes(data!.buffer.asUint8List());
              captured.dispose();
              stdout.writeln(
                'Captured ${name.replaceFirst('-$route.png', '-$state.png')}',
              );
            }

            if (width == 800 &&
                const bool.fromEnvironment('CONTROL_SCENARIOS')) {
              List<Element> mountedWhere(
                bool Function(Widget) matches, [
                Element? scope,
              ]) {
                final found = <Element>[];
                void visit(Element element) {
                  if (element.widget case Offstage(offstage: true)) return;
                  if (matches(element.widget)) {
                    found.add(element);
                    return;
                  }
                  element.visitChildren(visit);
                }

                (scope ?? _captureKey.currentContext! as Element).visitChildren(
                  visit,
                );
                return found;
              }

              Future<void> inspectSelects(Element scope, String prefix) async {
                final selects = mountedWhere(
                  (widget) => widget is FSelect<Object?>,
                  scope,
                );
                for (var index = 0; index < selects.length; index++) {
                  final element = selects[index];
                  if (!element.mounted) continue;
                  final fields = mountedWhere(
                    (widget) => widget is FTextField && widget.onTap != null,
                    element,
                  );
                  if (fields.isEmpty)
                    throw StateError(
                      'Select has no mounted field: ${element.widget.runtimeType}',
                    );
                  final field = fields.first;
                  await Scrollable.ensureVisible(field, alignment: .25);
                  await Future<void>.delayed(const Duration(milliseconds: 350));
                  if (!element.mounted || !field.mounted) continue;
                  final box = field.findRenderObject()! as RenderBox;
                  final hit = HitTestResult();
                  RendererBinding.instance.hitTestInView(
                    hit,
                    box.localToGlobal(box.size.center(Offset.zero)),
                    View.of(field).viewId,
                  );
                  if (!hit.path.any((entry) => identical(entry.target, box))) {
                    stdout.writeln(
                      'Skipped clipped/inactive select: ${element.widget.runtimeType}',
                    );
                    continue;
                  }
                  final toggle = (field.widget as FTextField).onTap!;
                  final type = element.widget.runtimeType.toString().replaceAll(
                    RegExp('[^a-zA-Z0-9]'),
                    '-',
                  );
                  scenario = '$name-$prefix-select-$index-$type';
                  toggle();
                  await captureState('$prefix-select-$index-$type');
                  toggle();
                  await Future<void>.delayed(const Duration(milliseconds: 350));
                }
              }

              Future<void> inspectToggle(
                Element scope,
                String state,
                bool mouse,
              ) async {
                await Scrollable.ensureVisible(scope, alignment: .25);
                await Future<void>.delayed(const Duration(milliseconds: 350));
                final triggers = mountedWhere(
                  (widget) => mouse
                      ? widget is MouseClick && widget.onClick != null
                      : widget is FButton && widget.onPress != null,
                  scope,
                );
                if (triggers.isEmpty)
                  throw StateError('Missing mounted trigger: $state');
                final widget = triggers.first.widget;
                final toggle = widget is MouseClick
                    ? widget.onClick!
                    : (widget as FButton).onPress!;
                scenario = '$name-$state';
                toggle();
                await captureState(state);
                toggle();
                await Future<void>.delayed(const Duration(milliseconds: 350));
              }

              final root = _captureKey.currentContext! as Element;
              if (route == 'prayer' &&
                  const bool.fromEnvironment('LAST_SCENARIOS')) {
                container
                    .read(desktopQuitFailureProvider.notifier)
                    .setFailed(true);
                await captureState('quit-recovery');
                container
                    .read(desktopQuitFailureProvider.notifier)
                    .setFailed(false);
                container
                    .read(prayerAlertSessionStateProvider.notifier)
                    .start(
                      PrayerAlertEvent(
                        kind: PrayerAlertKind.adhan,
                        prayer: Prayer.dhuhr,
                        scheduledTime: DateTime(2026, 10, 3, 12, 12),
                        playSound: false,
                        showInApp: true,
                        showOsNotification: false,
                        volume: 0,
                      ),
                    );
                await captureState('adhan-alert-overlay');
                container
                    .read(prayerAlertSessionStateProvider.notifier)
                    .clear();
                await Future<void>.delayed(const Duration(milliseconds: 400));
                final saved = container
                    .read(prayerSettingsProvider)
                    .requireValue;
                container
                    .read(prayerSettingsProvider.notifier)
                    .setPrayerSettings(PrayerSettings.defaultSettings());
                await captureState('prayer-location-required');
                container
                    .read(prayerSettingsProvider.notifier)
                    .setPrayerSettings(saved);
                router.go('/launch-review-unavailable-route');
                await captureState('route-error');
                router.go('/prayer');
                await Future<void>.delayed(const Duration(milliseconds: 900));
              }
              if (route == 'muslim_fortress' &&
                  const bool.fromEnvironment('LAST_SCENARIOS')) {
                final session = container.read(
                  fortressScreenControllerProvider.notifier,
                );
                session.setQuery('الصلاة');
                await captureState('fortress-search');
                session.clearGlobalSearch();
                container
                    .read(fortressScreenSettingsProvider.notifier)
                    .setSidebarTab(FortressSidebarTab.favorites);
                await captureState('fortress-favorites');
                container
                    .read(fortressScreenSettingsProvider.notifier)
                    .setSidebarTab(FortressSidebarTab.allChapters);
              }
              if (route == 'prayer') {
                final pickers = mountedWhere(
                  (widget) => widget is ScheduleAlertPicker,
                );
                if (pickers.isNotEmpty)
                  await inspectToggle(
                    pickers.first,
                    'prayer-alert-picker',
                    true,
                  );
                final statuses = mountedWhere(
                  (widget) => widget is ScheduleStatusChips && widget.menu,
                );
                if (statuses.isNotEmpty)
                  await inspectToggle(
                    statuses.first,
                    'prayer-status-row',
                    false,
                  );
              }
              if (route == 'quran') {
                final context = mountedWhere(
                  (widget) => widget is QuranHeaderWidget,
                ).single;
                final header = context.widget as QuranHeaderWidget;
                if (!const bool.fromEnvironment('LAST_SCENARIOS'))
                  await inspectSelects(context, 'quran-header');
                final navigation = mountedWhere(
                  (widget) =>
                      widget is Semantics &&
                      widget.properties.label == context.l10n.quranNavigation,
                  context,
                ).single;
                final openNavigation =
                    (mountedWhere(
                              (widget) => widget is FButton,
                              navigation,
                            ).single.widget
                            as FButton)
                        .onPress!;
                openNavigation();
                await Future<void>.delayed(const Duration(milliseconds: 900));
                await captureState('quran-display-controls');
                openNavigation();
                await Future<void>.delayed(const Duration(milliseconds: 350));
                await container
                    .read(quranMushafControllerProvider)
                    .jumpToAyah(1, select: true);
                container.read(quranSelectedAyahIdProvider.notifier).select(1);
                if (const bool.fromEnvironment('LAST_SCENARIOS')) {
                  await captureState('ayah-actions');
                  final labels = lookupAppLocalizations(Locale(language));
                  final actions = mountedWhere(
                    (widget) =>
                        widget is FButton &&
                        widget.semanticsLabel == labels.quranRecitationPlay,
                  );
                  if (actions.isNotEmpty) {
                    final toggle = (actions.first.widget as FButton).onPress!;
                    toggle();
                    await captureState('ayah-play-menu');
                    toggle();
                  }
                }
                header.onStudy!();
                await Future<void>.delayed(const Duration(milliseconds: 900));
                final study = mountedWhere((widget) => widget is StudyPanel)
                    .single;
                if (!const bool.fromEnvironment('LAST_SCENARIOS'))
                  await inspectSelects(study, 'study-source');
                final notes = mountedWhere(
                  (widget) => widget is NotesSection,
                  study,
                ).single;
                await Scrollable.ensureVisible(notes, alignment: .25);
                scenario = '$name-note-editor';
                await captureState('note-editor');
                (mountedWhere((widget) => widget is QuranHeaderWidget)
                            .single
                            .widget
                        as QuranHeaderWidget)
                    .onStudy!();
                container
                    .read(quranSelectedAyahIdProvider.notifier)
                    .select(null);
                await Future<void>.delayed(const Duration(milliseconds: 350));
              }
              if (route == 'settings') {
                final tab =
                    mountedWhere((widget) => widget is TabBar).single.widget
                        as TabBar;
                final controller = tab.controller!;
                final tabs = visibleTabs();
                for (var index = 0; index < tabs.length; index++) {
                  controller.animateTo(index);
                  await Future<void>.delayed(const Duration(milliseconds: 900));
                  final activePanel = mountedWhere(
                    (widget) =>
                        widget is LazyPanelContent && widget.index == index,
                  ).single;
                  if (tabs[index].key == 'prayer-times') {
                    final custom = mountedWhere(
                      (widget) => widget is CustomParametersAccordion,
                      activePanel,
                    ).single;
                    await Scrollable.ensureVisible(custom, alignment: .25);
                    final trigger =
                        mountedWhere(
                              (widget) =>
                                  widget is FTappable &&
                                  widget.semanticsExpanded != null,
                              custom,
                            ).first.widget
                            as FTappable;
                    if (trigger.semanticsExpanded != true) trigger.onPress!();
                    await WidgetsBinding.instance.endOfFrame;
                    scenario = '$name-settings-custom-expanded';
                    await captureState('settings-custom-expanded');
                  }
                  if (tabs[index].key == 'location') {
                    final location = mountedWhere(
                      (widget) =>
                          widget.runtimeType.toString() ==
                          'PrayerLocationSettings',
                      activePanel,
                    ).single;
                    final trigger =
                        mountedWhere(
                              (widget) =>
                                  widget is FTappable &&
                                  widget.semanticsExpanded != null,
                              location,
                            ).first.widget
                            as FTappable;
                    if (trigger.semanticsExpanded != true) trigger.onPress!();
                    await WidgetsBinding.instance.endOfFrame;
                    final body = mountedWhere(
                      (widget) =>
                          widget.runtimeType.toString() == 'CoordinatesRow',
                      location,
                    ).single;
                    await Scrollable.ensureVisible(body, alignment: .25);
                    scenario = '$name-settings-map-expanded';
                    await captureState('settings-map-expanded');
                  }
                  if (const bool.fromEnvironment('LAST_SCENARIOS')) {
                    await captureState('settings-tab-${tabs[index].key}');
                    for (final type in [
                      'DesktopSettingsSection',
                      'PrayerIqamahTile',
                      'LocationControlsRow',
                      '_UseLocationTile',
                    ]) {
                      final widgets = mountedWhere(
                        (widget) => widget.runtimeType.toString() == type,
                        activePanel,
                      );
                      if (widgets.isNotEmpty) {
                        await Scrollable.ensureVisible(
                          widgets.first,
                          alignment: .15,
                        );
                        await captureState('settings-$type');
                      }
                    }
                  }
                  if (!const bool.fromEnvironment('LAST_SCENARIOS'))
                    await inspectSelects(
                      activePanel,
                      'settings-${tabs[index].key}',
                    );
                }
                controller.animateTo(0);
                await Future<void>.delayed(const Duration(milliseconds: 350));
              }
              if (route == 'hadith') {
                final hadithLabels = lookupAppLocalizations(Locale(language));
                final filter = mountedWhere(
                  (widget) =>
                      widget is FButton &&
                      widget.semanticsLabel == hadithLabels.hadithOpenFilters,
                ).single;
                final toggleFilter = (filter.widget as FButton).onPress!;
                scenario = '$name-hadith-filter';
                toggleFilter();
                await captureState('hadith-filter');
                if (!const bool.fromEnvironment('LAST_SCENARIOS'))
                  await inspectSelects(root, 'hadith-filter');
                toggleFilter();
                await Future<void>.delayed(const Duration(milliseconds: 350));
                final session = container.read(
                  hadithSessionControllerProvider.notifier,
                );
                await session.setQuery('الصلاة');
                await Future<void>.delayed(const Duration(milliseconds: 900));
                final tiles = mountedWhere(
                  (widget) => widget.runtimeType.toString() == '_ResultTile',
                );
                if (tiles.isNotEmpty) {
                  if (const bool.fromEnvironment('LAST_SCENARIOS')) {
                    final actions = mountedWhere(
                      (widget) =>
                          widget is FButton &&
                          widget.semanticsLabel ==
                              hadithLabels.hadithMoreActions,
                      tiles.first,
                    );
                    if (actions.isNotEmpty) {
                      final toggle = (actions.first.widget as FButton).onPress!;
                      toggle();
                      await captureState('hadith-actions');
                      toggle();
                    }
                  }
                  await inspectToggle(tiles.first, 'hadith-preview', true);
                }
                await session.setQuery('');
                session.clearSelection();
                scenario = '$name-hadith-recents';
                await captureState('hadith-recents');
                final clear = mountedWhere(
                  (widget) =>
                      widget is Text &&
                      widget.data == hadithLabels.hadithClearAllRecents,
                );
                if (clear.isNotEmpty) {
                  final context = clear.first;
                  FButton? clearButton;
                  context.visitAncestorElements((element) {
                    if (element.widget case final FButton button) {
                      clearButton = button;
                      return false;
                    }
                    return true;
                  });
                  if (clearButton?.onPress == null)
                    throw StateError('Missing recent-search clear control');
                  clearButton!.onPress!();
                  scenario = '$name-hadith-clear-recents';
                  await captureState('hadith-clear-recents');
                  Navigator.of(context).pop(false);
                  await Future<void>.delayed(const Duration(milliseconds: 350));
                }
                await session.openBookmarks();
                scenario = '$name-hadith-favorites';
                await captureState('hadith-favorites');
                await session.exitSpecificMode();
              }
            }

            if (route == 'quran' &&
                width == 800 &&
                const bool.fromEnvironment('EXTRA_SCENARIOS')) {
              Element? headerElement;
              void findHeader(Element element) {
                if (element.widget is QuranHeaderWidget)
                  headerElement = element;
                element.visitChildren(findHeader);
              }

              _captureKey.currentContext!.visitChildElements(findHeader);
              if (headerElement == null)
                throw StateError('Quran header is not mounted');
              final header = headerElement!.widget as QuranHeaderWidget;
              scenario = '$name-study-empty';
              header.onStudy!();
              await captureState('study-empty');
              Navigator.of(headerElement!, rootNavigator: true).pop();
              await Future<void>.delayed(const Duration(milliseconds: 350));
              await container
                  .read(quranMushafControllerProvider)
                  .jumpToAyah(1, select: true);
              container.read(quranSelectedAyahIdProvider.notifier).select(1);
              scenario = '$name-study-selected';
              header.onStudy!();
              await captureState('study-selected');
              Navigator.of(headerElement!, rootNavigator: true).pop();
              await Future<void>.delayed(const Duration(milliseconds: 350));
              scenario = '$name-notes-empty';
              header.onNotes!();
              await captureState('notes-empty');
              Navigator.of(headerElement!, rootNavigator: true).pop();
              await container.read(quranNotesStoreProvider.future);
              container
                  .read(quranNotesStoreProvider.notifier)
                  .edit(1, 'Launch verification draft');
              await container
                  .read(quranNotesStoreProvider.notifier)
                  .flushAyah(1);
              scenario = '$name-notes-saved';
              header.onNotes!();
              await captureState('notes-saved');
              if (const bool.fromEnvironment('LAST_SCENARIOS')) {
                final label = lookupAppLocalizations(Locale(language))
                    .deleteReflection;
                FButton? delete;
                void findDelete(Element element) {
                  if (element.widget case FButton button
                      when button.semanticsLabel == label)
                    delete = button;
                  element.visitChildren(findDelete);
                }

                _captureKey.currentContext!.visitChildElements(findDelete);
                if (delete == null)
                  throw StateError('Missing reflection delete action');
                delete!.onPress!();
                await captureState('note-delete-confirm');
                Navigator.of(headerElement!, rootNavigator: true).pop(false);
                await Future<void>.delayed(const Duration(milliseconds: 350));
              }
              Navigator.of(headerElement!, rootNavigator: true).pop();
              await container.read(quranNotesStoreProvider.notifier).delete(1);
              scenario = '$name-player-no-selection';
              container.read(recitationDrawerProvider.notifier).open();
              await captureState('player-no-selection');
              container.read(recitationDrawerProvider.notifier).close();
              if (const bool.fromEnvironment('LAST_SCENARIOS')) {
                // Clearly named non-audio fixture; never played or shipped.
                final audio = await container
                    .read(recitationCacheProvider)
                    .audioDirectory();
                final fixtureDir = await Directory(
                  '${audio.path}/999999-999999 Review fixture',
                ).create(recursive: true);
                final fixture = File(
                  '${fixtureDir.path}/001 Review fixture.mp3',
                );
                await fixture.writeAsBytes(List.filled(4096, 0));
                await container
                    .read(recitationOfflineStoreProvider.notifier)
                    .refresh();
                final closed = showOfflineFilesDialog(headerElement!);
                await captureState('offline-file-fixture');
                final label = lookupAppLocalizations(Locale(language))
                    .quranRecitationOfflineDelete;
                FButton? delete;
                void findDelete(Element element) {
                  if (element.widget case FButton button
                      when button.semanticsLabel == label)
                    delete = button;
                  element.visitChildren(findDelete);
                }

                _captureKey.currentContext!.visitChildElements(findDelete);
                if (delete == null)
                  throw StateError('Missing offline delete action');
                delete!.onPress!();
                await captureState('offline-delete-confirm');
                Navigator.of(headerElement!, rootNavigator: true).pop(false);
                await Future<void>.delayed(const Duration(milliseconds: 350));
                Navigator.of(headerElement!, rootNavigator: true).pop();
                await closed;
                await fixture.delete();
                await container
                    .read(recitationOfflineStoreProvider.notifier)
                    .refresh();
              }
              container.read(quranSelectedAyahIdProvider.notifier).select(null);
              await Future<void>.delayed(const Duration(milliseconds: 350));
            }
            if (width == 800 && const bool.fromEnvironment('SHEET_SCENARIOS')) {
              Element mountedSurface(bool Function(Widget) matches) {
                Element? found;
                void visit(Element element) {
                  if (matches(element.widget)) found = element;
                  element.visitChildren(visit);
                }

                _captureKey.currentContext!.visitChildElements(visit);
                if (found == null)
                  throw StateError('Surface is not mounted: $route');
                return found!;
              }

              Future<void> inspectLocalDialog(
                BuildContext context,
                String state,
                Future<void> Function() open,
              ) async {
                scenario = '$name-$state';
                final closed = open();
                await captureState(state);
                Navigator.of(context).pop();
                await closed;
                await Future<void>.delayed(const Duration(milliseconds: 350));
              }

              if (route == 'about') {
                final context = mountedSurface(
                  (widget) => widget is AboutScreen,
                );
                await inspectLocalDialog(
                  context,
                  'about-dialog',
                  () => showAboutAppDialog(context),
                );
              }
              if (route == 'muslim_fortress') {
                final context = mountedSurface(
                  (widget) => widget is MuslimFortressScreen,
                );
                final repository = await container.read(
                  fortressRepositoryProvider.future,
                );
                final category = repository.loadChapters().firstWhere(
                  (chapter) => repository
                      .loadDuas(chapter.chapterId)
                      .any((dua) => dua.hasStudyContent),
                );
                final dua = repository
                    .loadDuas(category.chapterId)
                    .firstWhere((dua) => dua.hasStudyContent);
                final flow = container.read(
                  fortressScreenControllerProvider.notifier,
                );
                scenario = '$name-fortress-selected';
                flow.selectSearchTitle(category);
                await captureState('fortress-selected');
                scenario = '$name-fortress-reading';
                flow.startFocusReading();
                await captureState('fortress-reading');
                await inspectLocalDialog(
                  context,
                  'fortress-insights',
                  () => showFortressStudySheet(context, dua),
                );
                await inspectLocalDialog(
                  context,
                  'fortress-share',
                  () => showFortressShareDialog(context, dua),
                );
                flow.exitFocusMode();
                flow.selectCategory(category);
              }
              if (route == 'hadith') {
                final context = mountedSurface(
                  (widget) => widget is HadithPage,
                );
                final session = container.read(
                  hadithSessionControllerProvider.notifier,
                );
                scenario = '$name-hadith-search-loading';
                final search = session.setQuery('الصلاة');
                await captureState('hadith-search-loading');
                try {
                  await search.timeout(const Duration(seconds: 20));
                } on Object catch (error) {
                  stdout.writeln('Hadith readiness: $error');
                }
                scenario = '$name-hadith-search-outcome';
                await captureState('hadith-search-outcome');
                final results = container
                    .read(hadithSessionControllerProvider)
                    .results;
                if (results.isNotEmpty) {
                  await session.selectHadith(results.first);
                  scenario = '$name-hadith-selected';
                  await captureState('hadith-selected');
                  await inspectLocalDialog(
                    context,
                    'hadith-share',
                    () => showHadithShareDialog(context, results.first),
                  );
                }
                await session.setQuery('');
                session.clearSelection();
              }
              if (route == 'settings') {
                Element? tabElement;
                void findTabs(Element element) {
                  if (element.widget is TabBar) tabElement = element;
                  element.visitChildren(findTabs);
                }

                _captureKey.currentContext!.visitChildElements(findTabs);
                final controller = (tabElement!.widget as TabBar).controller!;
                final tabs = visibleTabs();
                for (var index = 1; index < tabs.length; index++) {
                  scenario = '$name-${tabs[index].key}';
                  controller.animateTo(index);
                  await captureState('settings-${tabs[index].key}');
                }
                controller.animateTo(0);
                await Future<void>.delayed(const Duration(milliseconds: 350));
              }
              if (route == 'quran') {
                Element? headerElement;
                void findHeader(Element element) {
                  if (element.widget is QuranHeaderWidget)
                    headerElement = element;
                  element.visitChildren(findHeader);
                }

                _captureKey.currentContext!.visitChildElements(findHeader);
                final context = headerElement!;
                void pressHeaderAction(String label) {
                  FButton? button;
                  void findButton(Element element) {
                    if (element.widget case final FButton found) button = found;
                    element.visitChildren(findButton);
                  }

                  void findLabel(Element element) {
                    if (element.widget case final Semantics semantics
                        when semantics.properties.label == label) {
                      element.visitChildren(findButton);
                    } else {
                      element.visitChildren(findLabel);
                    }
                  }

                  context.visitChildElements(findLabel);
                  if (button?.onPress == null)
                    throw StateError('Missing mounted action: $label');
                  button!.onPress!();
                }

                for (final entry in [
                  ('quran-search', context.l10n.searchQuran),
                  ('quran-navigation', context.l10n.quranNavigation),
                ]) {
                  scenario = '$name-${entry.$1}';
                  pressHeaderAction(entry.$2);
                  await captureState(entry.$1);
                  Navigator.of(context, rootNavigator: true).pop();
                  await Future<void>.delayed(const Duration(milliseconds: 350));
                }
                Future<void> inspectDialog(
                  String state,
                  Future<void> Function() open, {
                  bool rootNavigator = true,
                }) async {
                  scenario = '$name-$state';
                  final closed = open();
                  await captureState(state);
                  Navigator.of(context, rootNavigator: rootNavigator).pop();
                  await closed;
                  await Future<void>.delayed(const Duration(milliseconds: 350));
                }

                await inspectDialog(
                  'sleep-timer',
                  () => showSleepTimerDialog(context),
                );
                await inspectDialog(
                  'offline-files-empty',
                  () => showOfflineFilesDialog(context),
                );
                await inspectDialog(
                  'range-repeat-no-selection',
                  () => showRangeRepeatDialog(context),
                );
                // Capture the catalog's real ready/error state; do not seed invented metadata.
                try {
                  await container
                      .read(recitersProvider.future)
                      .timeout(const Duration(seconds: 12));
                } on Object catch (error) {
                  stdout.writeln('Catalog readiness: $error');
                }
                await inspectDialog('reciter-catalog', () async {
                  await showReciterDialog(context);
                });
                await inspectDialog('reciter-catalog-timed', () async {
                  await showReciterDialog(context, initialTimedFilter: true);
                });
                final ayah = await container
                    .read(quranMushafControllerProvider)
                    .getAyah(1);
                await inspectDialog(
                  'ayah-share',
                  () => showAyahShareDialog(context, ayah: ayah),
                  rootNavigator: false,
                );
              }
            }
          }
        }
      }
    }
  }
  if (const bool.fromEnvironment('ONBOARDING')) {
    await resizeOwnedWindow(const Size(800, 600));
    for (final language in ['en', 'ar']) {
      container.read(localeProvider.notifier).setLocale(Locale(language));
      await container.read(onboardingStateProvider.notifier).reset();
      router.go('/onboarding');
      await Future<void>.delayed(const Duration(seconds: 1));
      for (final step in OnboardingStep.values) {
        await Future<void>.delayed(const Duration(milliseconds: 600));
        await WidgetsBinding.instance.endOfFrame;
        final boundary =
            _captureKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final captured = await boundary.toImage();
        final bytes = await captured.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '${output.path}/onboarding-$language-${step.name}${xl ? '-xl' : ''}.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        captured.dispose();
        container.read(onboardingControllerProvider.notifier).next();
      }
      await container.read(onboardingStateProvider.notifier).finish();
      router.go('/prayer');
      await Future<void>.delayed(const Duration(milliseconds: 600));
    }
  }
  await container.read(themeProvider.notifier).flush();
  await File('${output.path}/errors.txt').writeAsString(errors.join('\n\n'));
  container.dispose();
  exit(errors.isEmpty ? 0 : 1);
}

/// GTK cannot request a mapped Wayland window's size. On Hyprland, use its
/// geometry dispatcher only after verifying this PID's unique floating window.
Future<void> resizeOwnedWindow(Size size) async {
  if (Platform.isLinux &&
      Platform.environment.containsKey('HYPRLAND_INSTANCE_SIGNATURE')) {
    final result = await Process.run('hyprctl', ['clients', '-j']);
    if (result.exitCode != 0) throw StateError('Cannot inspect native windows');
    final owned = (jsonDecode(result.stdout as String) as List)
        .where((dynamic client) => client['pid'] == pid)
        .toList();
    if (owned.length != 1 || owned.single['floating'] != true) {
      throw StateError('Place the owned test window in floating mode first');
    }
    final address = owned.single['address'] as String;
    if (!RegExp(r'^0x[0-9a-f]+$').hasMatch(address))
      throw StateError('Invalid window address');
    final resized = await Process.run('hyprctl', [
      'dispatch',
      'hl.dsp.window.resize({window="address:$address", x=${size.width.toInt()}, y=${size.height.toInt()}, relative=false})',
    ]);
    if (resized.exitCode != 0)
      throw StateError('Native resize failed: ${resized.stderr}');
    final deadline = DateTime.now().add(const Duration(seconds: 15));
    while (true) {
      final view = WidgetsBinding.instance.platformDispatcher.views.first;
      final actual = view.physicalSize / view.devicePixelRatio;
      if ((actual.width - size.width).abs() < 1 &&
          (actual.height - size.height).abs() < 1)
        break;
      if (DateTime.now().isAfter(deadline))
        throw StateError(
          'Native view did not reach requested size $size (got $actual)',
        );
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  } else {
    await windowManager.setSize(size);
  }
}

/// Mounted framework interactions, never a claim of native OS input coverage.
Future<void> reviewQuran(
  ProviderContainer container,
  Directory output,
  List<String> errors,
  void Function(String) scenario,
) async {
  // The harness reads preferences while Prayer owns the route during resizing.
  // Keep that auto-disposed provider subscribed until its Quran owner mounts.
  final preferences = container.listen(quranScreenSettingsProvider, (_, _) {});
  await container.read(quranScreenSettingsProvider.future);
  final router = container.read(appRouterProvider);
  final captures = <String>[];
  List<Element> elements(Type type, {Element? scope}) {
    final found = <Element>[];
    void visit(Element element) {
      if (element.widget is Offstage && (element.widget as Offstage).offstage)
        return;
      if (element.widget.runtimeType == type) found.add(element);
      element.visitChildren(visit);
    }

    visit(scope ?? _captureKey.currentContext! as Element);
    return found;
  }

  Future<void> ready(bool Function() condition) async {
    final deadline = DateTime.now().add(const Duration(seconds: 12));
    while (!condition()) {
      if (DateTime.now().isAfter(deadline))
        throw StateError('Quran review readiness timed out');
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<void> snap(String name) async {
    scenario(name);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        _captureKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('${output.path}/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
    captures.add(name);
  }

  Element header() => elements(QuranHeaderWidget).single;
  Element search() => elements(QuranSearchField).single;
  void closeSearch() {
    final focus = elements(
      Focus,
      scope: search(),
    ).map((e) => e.widget as Focus).firstWhere((f) => f.onKeyEvent != null);
    focus.onKeyEvent!(
      FocusNode(),
      const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.escape,
        logicalKey: LogicalKeyboardKey.escape,
        timeStamp: Duration.zero,
      ),
    );
  }

  Future<void> query(String value) async {
    final field =
        elements(FTextField, scope: search()).single.widget as FTextField;
    field.onTap!();
    (elements(EditableText, scope: search()).single.widget as EditableText)
            .controller
            .text =
        value;
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await WidgetsBinding.instance.endOfFrame;
    if (value.isNotEmpty)
      await ready(
        () =>
            elements(FItem).isNotEmpty ||
            elements(Text).any(
              (e) => (e.widget as Text).data == search().l10n.noResultsFound,
            ),
      );
  }

  if (const bool.fromEnvironment('QURAN_MOTION')) {
    for (final language in ['en', 'ar']) {
      container.read(localeProvider.notifier).setLocale(Locale(language));
      for (final width in [1200.0, 800.0]) {
        router.go('/prayer');
        await resizeOwnedWindow(Size(width, width == 800 ? 600 : 860));
        await ready(
          () =>
              (WidgetsBinding
                              .instance
                              .platformDispatcher
                              .views
                              .first
                              .physicalSize
                              .width /
                          WidgetsBinding
                              .instance
                              .platformDispatcher
                              .views
                              .first
                              .devicePixelRatio -
                      width)
                  .abs() <=
              1,
        );
        container
            .read(sidebarSettingsProvider.notifier)
            .setCollapsed(collapsed: width < 1024);
        container.read(quranScreenSettingsProvider.notifier)
          ..setLayout(QuranReadingLayout.studyMode)
          ..setSidePanelCollapsed(collapsed: true);
        container.read(quranSelectedAyahIdProvider.notifier).select(null);
        router.go('/quran');
        await ready(() => elements(QuranHeaderWidget).isNotEmpty);
        await Future<void>.delayed(const Duration(milliseconds: 300));
        final name =
            'motion-$language-${width.toInt()}-${Platform.environment['LAUNCH_REDUCED_MOTION'] == 'true' ? 'reduced' : 'normal'}';
        final folder = await Directory('${output.path}/$name').create();
        final samples = <Map<String, Object>>[];
        final actions = <Map<String, Object>>[];
        final clock = Stopwatch()..start();
        Future<void> frames(int milliseconds) async {
          final end = clock.elapsedMilliseconds + milliseconds;
          while (clock.elapsedMilliseconds < end) {
            await WidgetsBinding.instance.endOfFrame;
            final boundary =
                _captureKey.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await boundary.toImage();
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            final filename = '${samples.length.toString().padLeft(4, '0')}.png';
            await File('${folder.path}/$filename')
                .writeAsBytes(data!.buffer.asUint8List());
            image.dispose();
            samples.add({
              'file': filename,
              'at_ms': clock.elapsedMicroseconds / 1000,
            });
            await Future<void>.delayed(const Duration(milliseconds: 25));
          }
        }

        void action(String label, VoidCallback callback) {
          actions.add({
            'action': label,
            'at_ms': clock.elapsedMicroseconds / 1000,
          });
          callback();
        }

        FButton display() {
          final semantic = elements(Semantics, scope: header()).firstWhere(
            (e) =>
                (e.widget as Semantics).properties.label ==
                header().l10n.quranNavigation,
          );
          return elements(FButton, scope: semantic).single.widget as FButton;
        }

        await frames(300);
        action(
          'Study open without selection',
          (header().widget as QuranHeaderWidget).onStudy!,
        );
        await frames(500);
        action(
          'Study close with same button',
          (header().widget as QuranHeaderWidget).onStudy!,
        );
        await frames(500);
        action('Display controls open', display().onPress!);
        await frames(400);
        action(
          'Double-page mode',
          () => container
              .read(quranScreenSettingsProvider.notifier)
              .setLayout(QuranReadingLayout.doublePage),
        );
        await frames(500);
        action(
          'Study mode',
          () => container
              .read(quranScreenSettingsProvider.notifier)
              .setLayout(QuranReadingLayout.studyMode),
        );
        await frames(500);
        action('Display controls close', display().onPress!);
        await frames(300);
        action('Search reference', () {
          (elements(FTextField, scope: search()).single.widget as FTextField)
              .onTap!();
          (elements(EditableText, scope: search()).single.widget
                      as EditableText)
                  .controller
                  .text =
              '2:255';
        });
        await frames(700);
        action('Dismiss search', closeSearch);
        await frames(400);
        await File('${folder.path}/sequence.json').writeAsString(
          jsonEncode({
            'samples': samples,
            'actions': actions,
            'duration_ms': clock.elapsedMicroseconds / 1000,
            'scope': 'Timestamped native Flutter render-buffer sequence from mounted callbacks. Capture readbacks affect motion; not OS input or a performance trace.',
          }),
        );
      }
    }
    await File('${output.path}/errors.txt').writeAsString(errors.join('\n\n'));
    preferences.close();
    return;
  }
  if (const bool.fromEnvironment('QURAN_PERFORMANCE')) {
    await resizeOwnedWindow(const Size(800, 600));
    await ready(
      () =>
          (WidgetsBinding
                          .instance
                          .platformDispatcher
                          .views
                          .first
                          .physicalSize
                          .width /
                      WidgetsBinding
                          .instance
                          .platformDispatcher
                          .views
                          .first
                          .devicePixelRatio -
                  800)
              .abs() <=
          1,
    );
    container
        .read(sidebarSettingsProvider.notifier)
        .setCollapsed(collapsed: true);
    container.read(themeProvider.notifier).setPalette(AppPalette.manuscript);
    container.read(localeProvider.notifier).setLocale(const Locale('en'));
    container
        .read(quranScreenSettingsProvider.notifier)
        .setSidePanelCollapsed(collapsed: true);
    router.go('/quran');
    await ready(() => elements(QuranHeaderWidget).isNotEmpty);
    final timings = <ui.FrameTiming>[];
    void collect(List<ui.FrameTiming> frames) => timings.addAll(frames);
    WidgetsBinding.instance.addTimingsCallback(collect);
    final measurements = <Map<String, Object>>[];
    final events = File('${output.path}/quran-profile-events.jsonl')
        .openWrite();
    bool marked(String key) =>
        elements(SingleChildScrollView)
            .any((e) => e.widget.key == ValueKey(key)) ||
        elements(Padding).any((e) => e.widget.key == ValueKey(key));
    for (var cycle = -3; cycle < 20; cycle++) {
      events.writeln(
        jsonEncode({
          'cycle': cycle,
          'at': DateTime.now().toUtc().toIso8601String(),
        }),
      );
      if (cycle == 0) timings.clear();
      for (final term in [
        '2',
        'juz 3',
        'hizb 7',
        'Al-Baqarah',
        '2:255',
        'الله',
        'juz 31',
      ]) {
        final field =
            elements(FTextField, scope: search()).single.widget as FTextField;
        field.onTap!();
        final timer = Stopwatch()..start();
        (elements(EditableText, scope: search()).single.widget as EditableText)
                .controller
                .text =
            term;
        await WidgetsBinding.instance.endOfFrame;
        final feedback = timer.elapsedMicroseconds / 1000;
        await ready(
          () =>
              !marked('quran-search-loading') &&
              (marked('quran-search-results') ||
                  marked('quran-search-message')),
        );
        final settled = timer.elapsedMicroseconds / 1000;
        if (cycle >= 0)
          measurements.add({
            'cycle': cycle,
            'query': term,
            'framework_feedback_ms': feedback,
            'results_frame_ms': settled,
          });
      }
      closeSearch();
      for (final route in [
        'prayer',
        'quran',
        'hadith',
        'muslim_fortress',
        'settings',
        'about',
      ]) {
        final timer = Stopwatch()..start();
        router.go('/$route');
        await WidgetsBinding.instance.endOfFrame;
        if (cycle >= 0)
          measurements.add({
            'cycle': cycle,
            'route': route,
            'framework_frame_ms': timer.elapsedMicroseconds / 1000,
          });
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
      router.go('/quran');
      await ready(() => elements(QuranHeaderWidget).isNotEmpty);
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    WidgetsBinding.instance.removeTimingsCallback(collect);
    await events.close();
    double percentile(List<double> values, double fraction) {
      values.sort();
      return values.isEmpty
          ? 0
          : values[((values.length - 1) * fraction).ceil()];
    }

    final buildTimes = timings
        .map((t) => t.buildDuration.inMicroseconds / 1000)
        .toList();
    final raster = timings
        .map((t) => t.rasterDuration.inMicroseconds / 1000)
        .toList();
    await File('${output.path}/quran-performance.json').writeAsString(
      jsonEncode({
        'measurements': measurements,
        'search_debounce_ms': kQuranSearchDebounce.inMilliseconds,
        'warm_cycles': 3,
        'measured_cycles': 20,
        'frames': timings.length,
        'ui_p95_ms': percentile(buildTimes, .95),
        'ui_p99_ms': percentile(buildTimes, .99),
        'raster_p95_ms': percentile(raster, .95),
        'raster_p99_ms': percentile(raster, .99),
        'missed_60hz_fraction':
            timings
                .where(
                  (t) =>
                      t.buildDuration.inMicroseconds > 16667 ||
                      t.rasterDuration.inMicroseconds > 16667,
                )
                .length /
            timings.length,
        'errors': errors,
        'scope': 'Linux profile; mounted text/controller and route callbacks to framework frames, including the recorded search debounce. Does not certify OS pointer/key delivery or display scan-out latency.',
      }),
    );
    await File('${output.path}/errors.txt').writeAsString(errors.join('\n\n'));
    preferences.close();
    return;
  }
  for (final xl in [false, true]) {
    container
        .read(themeProvider.notifier)
        .setAppTextScale(xl ? AppTextScale.extraLarge : AppTextScale.normal);
    for (final language in ['en', 'ar']) {
      container.read(localeProvider.notifier).setLocale(Locale(language));
      for (final theme in [ThemeMode.light, ThemeMode.dark]) {
        container.read(themeProvider.notifier).setThemeMode(theme);
        for (final width in [1200.0, 800.0]) {
          router.go('/prayer');
          await resizeOwnedWindow(Size(width, width == 800 ? 600 : 860));
          await ready(
            () =>
                (WidgetsBinding
                                .instance
                                .platformDispatcher
                                .views
                                .first
                                .physicalSize
                                .width /
                            WidgetsBinding
                                .instance
                                .platformDispatcher
                                .views
                                .first
                                .devicePixelRatio -
                        width)
                    .abs() <=
                1,
          );
          await container.read(quranScreenSettingsProvider.future);
          container.read(quranScreenSettingsProvider.notifier)
            ..setLayout(QuranReadingLayout.studyMode)
            ..setSidePanelCollapsed(collapsed: true);
          container.read(quranSelectedAyahIdProvider.notifier).select(null);
          router.go('/quran?page=1');
          await ready(() => elements(QuranHeaderWidget).isNotEmpty);
          final prefix =
              'quran-$language-${theme.name}-${width.toInt()}-${xl ? 'xl' : 'normal'}';
          await snap('$prefix-reading');
          (header().widget as QuranHeaderWidget).onStudy!();
          await ready(
            () =>
                container.read(quranSelectedAyahProvider).hasValue &&
                container.read(quranSelectedAyahIdProvider) != null,
          );
          await Future<void>.delayed(const Duration(milliseconds: 500));
          await snap('$prefix-study-page-start');
          (header().widget as QuranHeaderWidget).onStudy!();
          await snap('$prefix-study-closed');
          // A new selection restores an available split companion; clearing
          // selection returns its width to the reader without a blank pane.
          container
              .read(quranScreenSettingsProvider.notifier)
              .setSidePanelCollapsed(collapsed: false);
          container.read(quranSelectedAyahIdProvider.notifier).select(null);
          await snap('$prefix-study-deselected');
          final selection = await container
              .read(quranMushafControllerProvider)
              .getAyahBySurah(2, 255);
          container
              .read(quranSelectedAyahIdProvider.notifier)
              .select(selection.ayahId);
          await Future<void>.delayed(const Duration(milliseconds: 500));
          await snap('$prefix-study-reselected');
          container.read(quranSelectedAyahIdProvider.notifier).select(null);
          for (final term in [
            '21',
            'الق',
            '2',
            'juz 3',
            'hizb 7',
            'البقرة',
            '2:255',
            'الله',
            'juz 31',
          ]) {
            await query(term);
            await snap(
              '$prefix-search-${['21', 'الق', '2', 'juz 3', 'hizb 7', 'البقرة', '2:255', 'الله', 'juz 31'].indexOf(term)}',
            );
          }
          closeSearch();
          FButton displayButton() {
            final semantic = elements(Semantics, scope: header()).firstWhere(
              (e) =>
                  (e.widget as Semantics).properties.label ==
                  header().l10n.quranNavigation,
            );
            return elements(FButton, scope: semantic).single.widget as FButton;
          }

          final display = displayButton();
          display.onPress!();
          await ready(() => elements(FTabs).isNotEmpty);
          await snap('$prefix-display-study');
          container
              .read(quranScreenSettingsProvider.notifier)
              .setLayout(QuranReadingLayout.doublePage);
          await snap('$prefix-display-double');
          displayButton().onPress!();
          final controller = container.read(quranMushafControllerProvider);
          final ayah = await controller.getAyahBySurah(2, 255);
          container
              .read(quranSelectedAyahIdProvider.notifier)
              .select(ayah.ayahId);
          (header().widget as QuranHeaderWidget).onStudy!();
          await ready(() => container.read(quranSelectedAyahProvider).hasValue);
          // This is a settled composition, not a loading/animation sample.
          await Future<void>.delayed(const Duration(milliseconds: 1200));
          await snap('$prefix-study-selected-double');
          (header().widget as QuranHeaderWidget).onStudy!();
        }
      }
    }
  }
  await File('${output.path}/errors.txt').writeAsString(errors.join('\n\n'));
  await File('${output.path}/quran-review.json').writeAsString(
    jsonEncode({
      'captures': captures,
      'errors': errors,
      'interaction': 'Mounted framework callbacks and text controllers; native input and screen-reader checks unverified',
      'matrix': 'Arabic/English, manuscript light/dark, 800x600/1200x860, normal/extra-large text',
    }),
  );
  preferences.close();
}

/// Fortress composition and mounted callbacks, with isolated app data.
Future<void> reviewFortress(
  ProviderContainer container,
  Directory output,
  List<String> errors,
  void Function(String) scenario,
) async {
  final settings = container.listen(fortressScreenSettingsProvider, (_, _) {});
  final flow = container.listen(fortressScreenControllerProvider, (_, _) {});
  final repository = await container.read(fortressRepositoryProvider.future);
  await container.read(fortressScreenSettingsProvider.future);
  final category = const bool.fromEnvironment('UI_FOLLOWUP_REVIEW')
      ? repository.loadChapters().firstWhere(
          (chapter) => repository
              .loadDuas(chapter.chapterId)
              .any((dua) => dua.hasDistinctVirtue),
        )
      : repository.loadChapters()[3];
  final router = container.read(appRouterProvider);
  final captures = <String>[];
  List<Element> elements(Type type, [Element? scope]) {
    final found = <Element>[];
    void visit(Element element) {
      if (element.widget is Offstage && (element.widget as Offstage).offstage)
        return;
      if (element.widget.runtimeType == type) found.add(element);
      element.visitChildren(visit);
    }

    visit(scope ?? _captureKey.currentContext! as Element);
    return found;
  }

  Future<void> ready(bool Function() condition) async {
    final deadline = DateTime.now().add(const Duration(seconds: 12));
    while (!condition()) {
      if (DateTime.now().isAfter(deadline))
        throw StateError('Fortress readiness timeout');
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<void> snap(String name, [GlobalKey? key]) async {
    scenario(name);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        (key ?? _captureKey).currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('${output.path}/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
    captures.add(name);
  }

  void button(String label) {
    final match = elements(FButton)
        .where(
          (element) => elements(
            Text,
            element,
          ).any((text) => (text.widget as Text).data == label),
        )
        .single;
    (match.widget as FButton).onPress!();
  }

  Future<void> search(String value) async {
    final sidebar = elements(FortressBrowseSidebar).single;
    final editable =
        elements(EditableText, sidebar).single.widget as EditableText;
    editable.controller.text = value;
    await ready(
      () =>
          container.read(fortressScreenControllerProvider).query ==
          value.trim(),
    );
    if (value.length >= fortressSearchMinQueryLength) {
      await container.read(fortressSearchResultsProvider(value).future);
    }
  }

  for (final scale in [AppTextScale.normal, AppTextScale.extraLarge]) {
    container.read(themeProvider.notifier).setAppTextScale(scale);
    for (final language in ['en', 'ar']) {
      container.read(localeProvider.notifier).setLocale(Locale(language));
      final l10n = lookupAppLocalizations(Locale(language));
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        container.read(themeProvider.notifier).setThemeMode(mode);
        for (final width in [1200.0, 800.0]) {
          final prefix =
              'fortress-$language-${mode.name}-${width.toInt()}-${scale == AppTextScale.normal ? 'normal' : 'xl'}';
          router.go('/prayer');
          final session = container.read(
            fortressScreenControllerProvider.notifier,
          );
          session.exitFocusMode();
          final selected = container
              .read(fortressScreenControllerProvider)
              .selectedChapterId;
          if (selected != null)
            session.selectCategory(
              repository.loadChapters().firstWhere(
                (c) => c.chapterId == selected,
              ),
            );
          session.clearGlobalSearch();
          container.read(fortressScreenSettingsProvider.notifier)
            ..setSidePanelCollapsed(collapsed: false)
            ..setSidebarTab(FortressSidebarTab.allChapters);
          await container.read(sidebarSettingsProvider.future);
          container
              .read(sidebarSettingsProvider.notifier)
              .setCollapsed(collapsed: true);
          await resizeOwnedWindow(Size(width, width == 800 ? 600 : 860));
          await Future<void>.delayed(const Duration(milliseconds: 600));
          router.go('/muslim_fortress');
          await ready(() => elements(FortressBrowseSidebar).isNotEmpty);
          await snap('$prefix-browse');
          final tile = elements(FortressCategoryListTile).firstWhere(
            (e) =>
                (e.widget as FortressCategoryListTile).category.chapterId ==
                category.chapterId,
          );
          (elements(MouseClick, tile).first.widget as MouseClick).onClick!();
          await ready(() => elements(FortressCategoryDetailHeader).isNotEmpty);
          await snap('$prefix-selected');
          if (const bool.fromEnvironment('UI_FOLLOWUP_REVIEW')) {
            final preview = elements(FortressDuaPreviewCard).firstWhere(
              (e) => (e.widget as FortressDuaPreviewCard).dua.hasDistinctVirtue,
            );
            await Scrollable.ensureVisible(preview, alignment: 0);
            (preview.widget as FortressDuaPreviewCard).onToggleExpanded();
            await ready(
              () => elements(FortressDuaPreviewCard)
                  .any((e) => (e.widget as FortressDuaPreviewCard).isExpanded),
            );
            await snap('$prefix-expanded');
            final expandedPreview = elements(FortressDuaPreviewCard).firstWhere(
              (e) => (e.widget as FortressDuaPreviewCard).isExpanded,
            );
            final share = elements(FButton, expandedPreview).singleWhere(
              (e) => (e.widget as FButton).semanticsLabel == l10n.fortressShare,
            );
            (share.widget as FButton).onPress!();
            await ready(() => elements(FortressShareDialog).isNotEmpty);
            await snap('$prefix-share');
            final card =
                elements(FortressShareCard).single.widget as FortressShareCard;
            await snap('$prefix-share-card', card.boundaryKey);
            Navigator.of(elements(FortressShareDialog).single).pop();
            await ready(() => elements(FortressShareDialog).isEmpty);
            continue;
          }
          if (width == 800) {
            button(l10n.fortressBackToCatalog);
            await ready(() => elements(FortressBrowseSidebar).isNotEmpty);
            await snap('$prefix-back-to-catalog');
          } else {
            final sidebar =
                elements(FortressBrowseSidebar).single.widget
                    as FortressBrowseSidebar;
            sidebar.onCollapse!();
            await snap('$prefix-collapsed');
          }
          if (!AppSearchFocusRegistry.instance.focus())
            throw StateError('Fortress shortcut missing');
          await ready(
            () =>
                elements(FortressBrowseSidebar).isNotEmpty &&
                (elements(
                          EditableText,
                          elements(FortressBrowseSidebar).single,
                        ).single.widget
                        as EditableText)
                    .focusNode
                    .hasFocus,
          );
          await snap('$prefix-search-focused');
          await search('النوم');
          await snap('$prefix-title-search');
          await search('الحمد');
          await snap('$prefix-content-search');
          await search('zzznomatchfortress');
          await snap('$prefix-empty-search');
          await search('');
          container
              .read(fortressScreenSettingsProvider.notifier)
              .setSidebarTab(FortressSidebarTab.favorites);
          await snap('$prefix-favorites');
        }
      }
    }
  }
  await File('${output.path}/fortress-review.json').writeAsString(
    jsonEncode({
      'captures': captures,
      'errors': errors,
      'matrix': 'Arabic/English; manuscript light/dark; 800x600/1200x860; normal/extra-large text',
      'scope': 'Mounted app callbacks/text controllers and render buffers; native OS input/accessibility unverified',
    }),
  );
  settings.close();
  flow.close();
}

Future<void> reviewHadith(
  ProviderContainer container,
  Directory output,
  List<String> errors,
  void Function(String) scenario,
) async {
  // Transcribed exactly from the user's provided record screenshot. This is
  // visual regression evidence, not an independent religious authentication.
  const source = DetailedHadith(
    hadith: 'مَن نَوَّر بالفَجرِ نَوَّر اللهُ قلبَه وقبرَه',
    rawi: '-',
    mohdith: 'الذهبي',
    book: 'ترتيب الموضوعات',
    numberOrPage: '151',
    grade: 'فيه أبو داود النخعي كذاب',
  );
  final captures = <String>[];
  List<Element> elements(Type type, [Element? scope]) {
    final found = <Element>[];
    void visit(Element e) {
      if (e.widget is Offstage && (e.widget as Offstage).offstage) return;
      if (e.widget.runtimeType == type) found.add(e);
      e.visitChildren(visit);
    }

    visit(scope ?? _captureKey.currentContext! as Element);
    return found;
  }

  Future<void> ready(bool Function() condition) async {
    final deadline = DateTime.now().add(const Duration(seconds: 12));
    while (!condition()) {
      if (DateTime.now().isAfter(deadline))
        throw StateError('Hadith readiness timeout');
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<void> snap(String name, [GlobalKey? key]) async {
    scenario(name);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        (key ?? _captureKey).currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('${output.path}/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
    captures.add(name);
  }

  final router = container.read(appRouterProvider);
  final settingsSubscription = container.listen(
    hadithScreenSettingsProvider,
    (_, _) {},
  );
  await container.read(hadithScreenSettingsProvider.future);
  final subscription = container.listen(
    hadithSessionControllerProvider,
    (_, _) {},
  );
  for (final scale in [AppTextScale.normal, AppTextScale.extraLarge]) {
    container.read(themeProvider.notifier).setAppTextScale(scale);
    for (final language in ['en', 'ar']) {
      container.read(localeProvider.notifier).setLocale(Locale(language));
      final l10n = lookupAppLocalizations(Locale(language));
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        container.read(themeProvider.notifier).setThemeMode(mode);
        for (final width in [1200.0, 800.0]) {
          final prefix =
              'hadith-$language-${mode.name}-${width.toInt()}-${scale == AppTextScale.normal ? 'normal' : 'xl'}';
          router.go('/prayer');
          await resizeOwnedWindow(Size(width, width == 800 ? 600 : 860));
          await Future<void>.delayed(const Duration(milliseconds: 400));
          router.go('/hadith');
          await ready(() => elements(HadithPage).isNotEmpty);
          await container
              .read(hadithSessionControllerProvider.notifier)
              .openSpecificList([source]);
          await ready(() => elements(HadithResultCard).isNotEmpty);
          if (const bool.fromEnvironment('HADITH_CARD_REVIEW')) {
            final controller = container.read(
              hadithSessionControllerProvider.notifier,
            );
            Future<void> hover(bool enter) async {
              final row = elements(HadithResultCard).first;
              // Invoke the mounted Forui pointer callback; no OS input claim.
              final body = elements(MouseClick, row).single;
              final regions = elements(MouseRegion, body);
              for (final e in regions) {
                final region = e.widget as MouseRegion;
                if (enter) {
                  region.onEnter?.call(const PointerEnterEvent());
                } else {
                  region.onExit?.call(const PointerExitEvent());
                }
              }
              await WidgetsBinding.instance.endOfFrame;
            }

            await controller.selectHadith(source);
            await snap('$prefix-selected');
            await hover(true);
            await snap('$prefix-selected-hover');
            await hover(false);
            controller.clearSelection();
            await snap('$prefix-idle');
            await hover(true);
            await snap('$prefix-hover');
            await hover(false);
            continue;
          }
          await snap('$prefix-result');
          final row = elements(HadithResultCard).first;
          final share = elements(FButton, row).firstWhere(
            (e) => (e.widget as FButton).semanticsLabel == l10n.hadithShare,
          );
          (share.widget as FButton).onPress!();
          await ready(() => elements(HadithShareDialog).isNotEmpty);
          await snap('$prefix-share');
          final card =
              elements(HadithShareCard).single.widget as HadithShareCard;
          await snap('$prefix-card', card.boundaryKey);
          for (final value in [
            HadithShareInclude.muhaddith,
            HadithShareInclude.number,
          ]) {
            final option = elements(FSelectTile<HadithShareInclude>).firstWhere(
              (e) =>
                  (e.widget as FSelectTile<HadithShareInclude>).value == value,
            );
            final tile = elements(FTile, option).single.widget as FTile;
            tile.onPress!();
            await WidgetsBinding.instance.endOfFrame;
          }
          await snap('$prefix-all-details');
          final fullCard =
              elements(HadithShareCard).single.widget as HadithShareCard;
          await snap('$prefix-full-card', fullCard.boundaryKey);
          Navigator.of(elements(HadithShareDialog).single).pop();
          await ready(() => elements(HadithShareDialog).isEmpty);
          if (width == 800 && scale == AppTextScale.extraLarge) {
            final id = 'review-sharh-$language-${mode.name}';
            final review = source.copyWith(
              hadith: 'Synthetic UI fixture — optional commentary recovery',
              hasSharhMetadata: true,
              sharhMetadata: SharhMetadata(id: id),
            );
            final dialogFuture = showHadithShareDialog(
              elements(HadithPage).single,
              review,
            );
            await ready(() => elements(HadithShareDialog).isNotEmpty);
            final option = elements(FSelectTile<HadithShareInclude>).firstWhere(
              (e) =>
                  (e.widget as FSelectTile<HadithShareInclude>).value ==
                  HadithShareInclude.sharh,
            );
            (elements(FTile, option).single.widget as FTile).onPress!();
            await ready(
              () => elements(Text).any(
                (e) =>
                    (e.widget as Text).data ==
                    l10n.hadithShareDetailsFailed(l10n.hadithSharh),
              ),
            );
            await snap('$prefix-optional-error');
            final retry = elements(FButton).singleWhere(
              (e) => elements(
                Text,
                e,
              ).any((text) => (text.widget as Text).data == l10n.retryAction),
            );
            (retry.widget as FButton).onPress!();
            await ready(
              () => elements(Text).any(
                (e) => (e.widget as Text).data == 'Synthetic UI review fixture — optional commentary successfully loaded.',
              ),
            );
            await snap('$prefix-optional-recovered');
            Navigator.of(elements(HadithShareDialog).single).pop();
            await dialogFuture;
            await ready(() => elements(HadithShareDialog).isEmpty);
          }
        }
      }
    }
  }
  await File('${output.path}/errors.txt').writeAsString(errors.join('\n\n'));
  await File('${output.path}/hadith-review.json').writeAsString(
    jsonEncode({
      'captures': captures,
      'errors': errors,
      'fixture': 'User-supplied source screenshot transcribed for visual regression; no independent authentication',
      'scope': 'Native mounted app callbacks/render buffers; OS input and accessibility unverified',
    }),
  );
  subscription.close();
  settingsSubscription.close();
}

Future<void> reviewFinalFixes(
  ProviderContainer container,
  Directory output,
  List<String> errors,
  void Function(String) scenario,
) async {
  const confirmation = bool.fromEnvironment('FINAL_FIXES_CONFIRM');
  final router = container.read(appRouterProvider);
  final preferences = container.listen(quranScreenSettingsProvider, (_, _) {});
  await container.read(quranScreenSettingsProvider.future);
  final repository = await container.read(fortressRepositoryProvider.future);
  final chapters = repository.loadChapters();
  final virtueChapter = chapters.firstWhere(
    (c) => repository.loadDuas(c.chapterId).any((d) => d.hasDistinctVirtue),
  );
  final quranDua = chapters
      .expand((c) => repository.loadDuas(c.chapterId))
      .firstWhere((d) => d.isQuranicPassage && d.hasDistinctVirtue);
  final captures = <String>[];
  List<Element> elements(Type type, [Element? scope]) {
    final found = <Element>[];
    void visit(Element e) {
      if (e.widget case Offstage(offstage: true)) return;
      if (e.widget.runtimeType == type) found.add(e);
      e.visitChildren(visit);
    }

    visit(scope ?? _captureKey.currentContext! as Element);
    return found;
  }

  Future<void> settle() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<void> snap(String name) async {
    scenario(name);
    await settle();
    final boundary =
        _captureKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('${output.path}/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
    captures.add(name);
    stdout.writeln('Captured $name');
  }

  for (final language in ['ar', 'en']) {
    container.read(localeProvider.notifier).setLocale(Locale(language));
    for (final compact in [false, true]) {
      final prefix =
          '$language-${compact ? '800-light-xl' : '1200-dark-normal'}';
      router.go('/prayer');
      container.read(themeProvider.notifier)
        ..setThemeMode(compact ? ThemeMode.light : ThemeMode.dark)
        ..setAppTextScale(
          compact ? AppTextScale.extraLarge : AppTextScale.normal,
        );
      await resizeOwnedWindow(
        compact ? const Size(800, 600) : const Size(1200, 860),
      );
      if (!confirmation) await snap('$prefix-prayer');
      router.go('/quran');
      await settle();
      final controller = container.read(quranMushafControllerProvider);
      final ayah = await controller.getAyahBySurah(2, 255);
      container.read(quranScreenSettingsProvider.notifier)
        ..setLayout(QuranReadingLayout.studyMode)
        ..setSidePanelCollapsed(collapsed: true);
      container.read(quranSelectedAyahIdProvider.notifier).select(ayah.ayahId);
      await controller.jumpToAyah(ayah.ayahId, select: true);
      await settle();
      if (!confirmation) await snap('$prefix-quran');
      final actions = elements(FButton)
          .where(
            (e) => elements(Icon, e).any(
              (icon) => (icon.widget as Icon).icon == FLucideIcons.ellipsis,
            ),
          )
          .single;
      (actions.widget as FButton).onPress!();
      await snap('$prefix-ayah-actions');
      (actions.widget as FButton).onPress!();
      if (!confirmation) {
        router.go('/muslim_fortress');
        await settle();
        container
            .read(fortressScreenControllerProvider.notifier)
            .selectCategory(virtueChapter);
        await snap('$prefix-virtue-preview');
        final dialog = showFortressShareDialog(
          elements(MuslimFortressScreen).single,
          quranDua,
        );
        await snap('$prefix-quran-share');
        Navigator.of(elements(FortressShareDialog).single).pop();
        await dialog;
        router.go('/settings?tab=location');
        await container.read(settingsScreenSettingsProvider.future);
        container
            .read(settingsScreenSettingsProvider.notifier)
            .setActiveTabKey('location');
        await snap('$prefix-location');
        router.go('/settings?tab=appearance');
        await snap('$prefix-appearance');
        router.go('/about');
        await snap('$prefix-about');
      } else {
        router.go('/settings?tab=appearance');
        await snap('$prefix-appearance');
      }
    }
  }
  if (!confirmation) {
    // Leave a real reader mounted for exact-target native key delivery. The
    // external marker requests observations only; it never triggers UI actions.
    container.read(localeProvider.notifier).setLocale(const Locale('ar'));
    container.read(themeProvider.notifier)
      ..setThemeMode(ThemeMode.dark)
      ..setAppTextScale(AppTextScale.normal);
    router.go('/prayer');
    await resizeOwnedWindow(const Size(1200, 860));
    router.go('/quran');
    await settle();
    container.read(quranSelectedAyahIdProvider.notifier).select(null);
    final controller = container.read(quranMushafControllerProvider);
    await controller.animateToPage(50);
    await settle();
    await File('${output.path}/native-ready').writeAsString('$pid');
    var sample = 0;
    final deadline = DateTime.now().add(const Duration(minutes: 8));
    while (!File('${output.path}/native-done').existsSync() &&
        DateTime.now().isBefore(deadline)) {
      final request = File('${output.path}/observe');
      if (request.existsSync()) {
        final label = request.readAsStringSync().trim();
        request.deleteSync();
        await snap('native-$sample-$label');
        await File('${output.path}/native-$sample-$label.json').writeAsString(
          jsonEncode({
            'page': controller.currentPage,
            'selection': container.read(quranSelectedAyahIdProvider),
            'primary_focus': FocusManager.instance.primaryFocus?.debugLabel,
            'route': router.routeInformationProvider.value.uri.toString(),
          }),
        );
        sample++;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }
  await File('${output.path}/errors.txt').writeAsString(errors.join('\n\n'));
  await File('${output.path}/final-fixes-review.json').writeAsString(
    jsonEncode({
      'captures': captures,
      'errors': errors,
      'scope': 'Actual Linux route and share surfaces; unavailable location fixture; native input observations separately recorded.',
    }),
  );
  preferences.close();
}
