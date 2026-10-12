/// Runs the production app with an isolated profile and a small review API.
/// XDG_CONFIG_HOME/XDG_DATA_HOME must point to the task's evidence directory.
/// Input through this API is Flutter input; it does not certify OS mouse input.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/app/onboarding/onboarding_screen.dart';
import 'package:tawaq/app/routing/route_provider.dart';
import 'package:tawaq/core/locale/locale_provider.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/core/widgets/reading_swipe_viewport.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/detail/hadith_reader_text.dart';
import 'package:tawaq/feature/muslim_fortress/data/repository/fortress_repository.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/provider/muslim_fortress_provider.dart';
import 'package:tawaq/feature/onboarding/presentation/providers/onboarding_state_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/adhan_preview_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_settings_provider.dart';
import 'package:tawaq/feature/settings/data/models/app_text_scale.dart';
import 'package:tawaq/feature/settings/presentation/provider/theme_settings_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';
import 'package:tawaq/main.dart';
import 'package:timezone/data/latest.dart' as tz;

final _capture = GlobalKey();
final _container = ProviderContainer();
bool _reviewPointerAdded = false;

Future<void> main() async {
  if (Platform.environment['XDG_CONFIG_HOME'] == null ||
      Platform.environment['XDG_DATA_HOME'] == null) {
    throw StateError('Use an isolated XDG profile for this review harness.');
  }
  if (const bool.fromEnvironment('ENABLE_FLUTTER_DRIVER')) {
    enableFlutterDriverExtension(handler: _review);
  } else {
    WidgetsFlutterBinding.ensureInitialized();
  }
  tz.initializeTimeZones();
  runApp(
    UncontrolledProviderScope(
      container: _container,
      child: RepaintBoundary(key: _capture, child: const AppBootstrap()),
    ),
  );
}

Future<String> _review(String? payload) async {
  final request = jsonDecode(payload!) as Map<String, dynamic>;
  switch (request['action']) {
    case 'configure':
      await _container.read(prayerSettingsProvider.future);
      await _container.read(themeProvider.future);
      await _container.read(localeProvider.future);
      if (request['zoom'] case final num zoom) {
        final subscription = _container.listen(
          quranScreenSettingsProvider,
          (_, _) {},
        );
        await _container.read(quranScreenSettingsProvider.future);
        _container
            .read(quranScreenSettingsProvider.notifier)
            .setMushafZoom(zoom.toDouble());
        _container
            .read(quranScreenSettingsProvider.notifier)
            .setSidePanelCollapsed(collapsed: false);
        subscription.close();
      }
      if (request['ayah'] case final int ayah) {
        _container.read(quranSelectedAyahIdProvider.notifier).select(ayah);
      }
      if (request['city'] == 'London') {
        await _container
            .read(prayerSettingsProvider.notifier)
            .applyLocationBundle(
              coordinates: Coordinates(51.5074, -.1278),
              locationName: 'London',
            );
      }
      if (request['locale'] case final String locale) {
        _container.read(localeProvider.notifier).setLocale(Locale(locale));
      }
      if (request['theme'] case final String mode) {
        _container
            .read(themeProvider.notifier)
            .setThemeMode(ThemeMode.values.byName(mode));
      }
      if (request['scale'] case final String scale) {
        _container
            .read(themeProvider.notifier)
            .setAppTextScale(AppTextScale.values.byName(scale));
      }
    case 'route':
      if (request['setup'] == true) {
        await _container.read(onboardingStateProvider.notifier).reset();
        _container.read(appRouterProvider).go('/onboarding');
        await WidgetsBinding.instance.endOfFrame;
        await WidgetsBinding.instance.endOfFrame;
        _container
            .read(onboardingControllerProvider.notifier)
            .review(OnboardingStep.values.byName(request['step'] as String));
      } else {
        await _container.read(onboardingStateProvider.notifier).finish();
        _container.read(appRouterProvider).go(request['path'] as String);
      }
    case 'fortress':
      final repository = await _container.read(
        fortressRepositoryProvider.future,
      );
      final category = repository.loadChapters().firstWhere(
        (c) => c.chapterId == 27,
      );
      _container
          .read(fortressScreenControllerProvider.notifier)
          .selectCategory(category);
    case 'saved':
      _container.read(hadithSessionControllerProvider.notifier).openBookmarks();
    case 'search':
      final controller = _container.read(
        hadithSessionControllerProvider.notifier,
      );
      await controller.setQuery(request['query'] as String);
      await controller.search();
      final result = _container
          .read(hadithSessionControllerProvider)
          .results
          .firstOrNull;
      if (result != null) await controller.selectHadith(result);
    case 'select':
      Element? reader;
      void findReader(Element e) {
        if (request['quran'] == true) {
          if (e.widget case ScopedSelectableRichText(:final textSpan)) {
            if (textSpan.toPlainText().length > 100) reader ??= e;
          }
        } else if (request['source'] == true) {
          if (e.widget case ScopedSelectableRichText(:final textSpan)) {
            if (textSpan.toPlainText().length > 100 &&
                textSpan.toPlainText().contains('الغداة')) {
              reader ??= e;
            }
          }
        } else if (e.widget is HadithReaderText) {
          reader = e;
        }
        e.visitChildren(findReader);
      }
      findReader(_capture.currentContext! as Element);
      if (reader == null) return 'reader unavailable';
      await Scrollable.ensureVisible(reader!, alignment: .3);
      await WidgetsBinding.instance.endOfFrame;
      RenderParagraph? paragraph;
      SelectionAreaState? selection;
      void findText(Element e) {
        if (e.widget is RichText)
          paragraph = e.findRenderObject() as RenderParagraph;
        if (e is StatefulElement && e.state is SelectionAreaState)
          selection = e.state as SelectionAreaState;
        e.visitChildren(findText);
      }
      reader!.visitChildren(findText);
      selection ??= reader!.findAncestorStateOfType<SelectionAreaState>();
      final p = paragraph!;
      Offset point(int offset) => p.localToGlobal(
        p.getOffsetForCaret(TextPosition(offset: offset), Rect.zero) +
            const Offset(0, 26),
      );
      var frame = 0;
      Future<void> captureFrame() async {
        if (request['frames'] case final String directory) {
          await Directory(directory).create(recursive: true);
          await _review(
            jsonEncode({
              'action': 'capture',
              'path': '$directory/${(frame++).toString().padLeft(3, '0')}.png',
            }),
          );
        }
      }
      await captureFrame();
      final ayahBefore = _container.read(quranSelectedAyahIdProvider);
      final start = point(request['start'] as int);
      final end = point(request['end'] as int);
      final anchor = p.getPositionForOffset(p.globalToLocal(start)).offset;
      final extent = p.getPositionForOffset(p.globalToLocal(end)).offset;
      if (!_reviewPointerAdded) {
        WidgetsBinding.instance.handlePointerEvent(
          PointerAddedEvent(
            pointer: 71934,
            timeStamp: Duration(
              milliseconds: DateTime.now().millisecondsSinceEpoch,
            ),
            device: 71934,
            kind: PointerDeviceKind.mouse,
            position: start,
          ),
        );
        _reviewPointerAdded = true;
      }
      WidgetsBinding.instance.handlePointerEvent(
        PointerDownEvent(
          pointer: 71934,
          timeStamp: Duration(
            milliseconds: DateTime.now().millisecondsSinceEpoch,
          ),
          device: 71934,
          kind: PointerDeviceKind.mouse,
          position: start,
          buttons: kPrimaryMouseButton,
        ),
      );
      for (var step = 1; step <= 16; step++) {
        WidgetsBinding.instance.handlePointerEvent(
          PointerMoveEvent(
            pointer: 71934,
            timeStamp: Duration(
              milliseconds: DateTime.now().millisecondsSinceEpoch,
            ),
            device: 71934,
            kind: PointerDeviceKind.mouse,
            position: Offset.lerp(start, end, step / 16)!,
            delta: (end - start) / 16,
            buttons: kPrimaryMouseButton,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 60));
        await captureFrame();
      }
      WidgetsBinding.instance.handlePointerEvent(
        PointerUpEvent(
          pointer: 71934,
          timeStamp: Duration(
            milliseconds: DateTime.now().millisecondsSinceEpoch,
          ),
          device: 71934,
          kind: PointerDeviceKind.mouse,
          position: end,
        ),
      );
      await WidgetsBinding.instance.endOfFrame;
      await captureFrame();
      if (request['capture'] case final String path) {
        await _review(jsonEncode({'action': 'capture', 'path': path}));
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
      final button = selection!.selectableRegion.contextMenuButtonItems
          .where((item) => item.type.name == 'copy')
          .firstOrNull;
      if (button == null) return 'selection has no copy action';
      button.onPressed?.call();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final copied = await Clipboard.getData(Clipboard.kTextPlain);
      final expected = p.text.toPlainText().substring(
        anchor < extent ? anchor : extent,
        anchor > extent ? anchor : extent,
      );
      return jsonEncode({
        'matches': copied?.text == expected,
        if (request['quran'] == true) ...{
          'ayahBefore': ayahBefore,
          'ayahAfter': _container.read(quranSelectedAyahIdProvider),
        },
        'anchor': anchor,
        'extent': extent,
        'copied': copied?.text,
        'expected': expected,
      });
    case 'trackpad':
      Element? viewport;
      void findViewport(Element e) {
        if (e.widget is ReadingSwipeViewport) viewport = e;
        e.visitChildren(findViewport);
      }
      findViewport(_capture.currentContext! as Element);
      if (viewport == null) return 'study viewport unavailable';
      final box = viewport!.findRenderObject()! as RenderBox;
      final position = box.localToGlobal(box.size.center(Offset.zero));
      final before = _container.read(quranSelectedAyahIdProvider);
      WidgetsBinding.instance.handlePointerEvent(
        PointerPanZoomStartEvent(
          pointer: 71935,
          device: 71935,
          position: position,
        ),
      );
      for (var step = 1; step <= 12; step++) {
        WidgetsBinding.instance.handlePointerEvent(
          PointerPanZoomUpdateEvent(
            pointer: 71935,
            device: 71935,
            position: position,
            pan: Offset(step * 12, 0),
            panDelta: const Offset(12, 0),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 60));
      }
      WidgetsBinding.instance.handlePointerEvent(
        PointerPanZoomEndEvent(
          pointer: 71935,
          device: 71935,
          position: position,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
      return jsonEncode({
        'ayahBefore': before,
        'ayahAfter': _container.read(quranSelectedAyahIdProvider),
      });
    case 'capture':
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          _capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(request['path'] as String)
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    case 'state':
      final settings = _container.read(prayerSettingsProvider).value;
      final preview = _container.read(adhanPreviewProvider);
      return jsonEncode({
        'timezone': settings?.location.name,
        'deviceTimezone': settings?.useSystemTimezone,
        'ready': settings?.isLocationReady,
        'preview': preview.status.name,
        'city': settings?.locationName,
        'theme': _container.read(themeProvider).value?.themeMode.name,
      });
  }
  return 'ok';
}
