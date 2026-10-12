import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:mushaf_reader/src/presentation/widgets/page_ayah_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late MushafReaderController controller;
  final pages = List.generate(604, (index) => index + 1);
  const channel = MethodChannel('plugins.flutter.io/path_provider');

  setUpAll(() async {
    directory = Directory.systemTemp.createTempSync('mushaf_reading_size_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => directory.path);
    await MushafReaderLibrary.ensureInitialized();
    controller = MushafReaderController();
    await controller.ensureReady();
    for (final family in [
      MushafFonts.basmalahFamily,
      ...pages.map(MushafFonts.forPage),
    ]) {
      await (FontLoader('packages/mushaf_reader/$family')..addFont(
            rootBundle.load(
              'packages/mushaf_reader/assets/otf_fonts/$family.otf',
            ),
          ))
          .load();
    }
  });

  tearDownAll(() async {
    await Hive.close();
    controller.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await directory.delete(recursive: true);
  });

  for (final size in [const Size(1640, 920), const Size(420, 640)]) {
    testWidgets('fit-page keeps verses visible at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      double? readingSize;
      for (final page in pages) {
        await tester.runAsync(() => controller.getPage(page));
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MushafPage(
                key: ValueKey(page),
                page: page,
                controller: controller,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'page $page');
        for (final element in find.byType(Scrollable).evaluate()) {
          final state = (element as StatefulElement).state as ScrollableState;
          expect(
            state.position.maxScrollExtent,
            lessThanOrEqualTo(0.5),
            reason: 'page $page must show the last verse at fit-page zoom',
          );
        }
        for (final ayahs in tester.widgetList<PageAyahWidget>(
          find.byType(PageAyahWidget),
        )) {
          readingSize ??= ayahs.style.fontSize;
          expect(
            ayahs.style.fontSize,
            readingSize,
            reason: 'decorations must not shrink page $page verses',
          );
        }
      }
    });
  }
}
