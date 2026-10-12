import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:mushaf_reader/src/presentation/widgets/page_ayah_widget.dart';

void main() {
  testWidgets('100% fits the complete real page; zoom scrolls one whole page', (
    tester,
  ) async {
    final directory = Directory.systemTemp.createTempSync('mushaf_fit_');
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (_) async => directory.path,
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
      directory.deleteSync(recursive: true);
    });
    late MushafReaderController controller;
    await tester.runAsync(() async {
      for (final font in ['QCF4_003', 'QCF4_507', 'QCF4_604', 'QCF4_BSML']) {
        final loader = FontLoader('packages/mushaf_reader/$font');
        loader.addFont(
          rootBundle.load('packages/mushaf_reader/assets/otf_fonts/$font.otf'),
        );
        await loader.load();
      }
      await MushafReaderLibrary.ensureInitialized();
      controller = MushafReaderController(initialPage: 507);
      await controller.ensureReady();
      for (final page in [3, 507, 604]) {
        await controller.getPage(page);
      }
    });
    addTearDown(controller.dispose);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final height in [180.0, 450.0, 650.0]) {
      tester.view.physicalSize = Size(1000, height);
      for (final page in [3, 507, 604]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MushafPage(
                key: ValueKey('$height-$page'),
                page: page,
                controller: controller,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final states = tester
            .stateList<ScrollableState>(find.byType(Scrollable))
            .toList();
        expect(states, hasLength(1));
        expect(
          states.single.position.maxScrollExtent,
          closeTo(0, .5),
          reason: 'page $page at height $height',
        );
        final footer = tester.getRect(find.byType(PageNumberWidget));
        expect(footer.top, greaterThanOrEqualTo(0));
        expect(footer.bottom, lessThanOrEqualTo(height + .5));
      }
    }
    tester.view.physicalSize = const Size(1000, 180);
    await tester.pumpWidget(
      MaterialApp(
        home: MushafPage(
          page: 507,
          controller: controller,
          style: const MushafStyle(
            scale: MushafScale(ayahFontSize: 32, pageNumberFontSize: 24),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<PageAyahWidget>(find.byType(PageAyahWidget)).style.fontSize,
      32,
    );
    expect(
      tester.widget<PageNumberWidget>(find.byType(PageNumberWidget)).fontSize,
      24,
    );
    expect(
      tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position
          .maxScrollExtent,
      greaterThan(0),
    );
    tester.view.physicalSize = const Size(1000, 650);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MushafPage(
            page: 507,
            controller: controller,
            style: const MushafStyle(scale: MushafScale(readingBoost: 1.15)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final scrollers = tester
        .stateList<ScrollableState>(find.byType(Scrollable))
        .toList();
    expect(scrollers, hasLength(1));
    expect(scrollers.single.position.maxScrollExtent, greaterThan(0));
    await tester.drag(find.byType(MushafPage), const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byType(PageNumberWidget)).bottom,
      lessThanOrEqualTo(650.5),
    );
  });
}
