import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:mushaf_reader/src/presentation/widgets/page_ayah_widget.dart';
import 'package:path/path.dart' as p;

import '../hive_test_support.dart';
import 'tolerant_golden_comparator.dart';

/// Deterministic style for KFQC visual goldens (white page, no zoom boost).
const _goldenStyle = MushafStyle(
  backgroundColor: Color(0xFFFFFFFF),
  scale: MushafScale(readingBoost: 1),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late MushafReaderController controller;
  late GoldenFileComparator previousComparator;

  final packageRoot = findPackageRoot();
  final refsDir = Directory(
    p.join(packageRoot.path, 'test', 'goldens', 'kfqc_refs'),
  );

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('mushaf_kfqc_goldens_');
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getApplicationDocumentsDirectory') {
            return tempDir.path;
          }
          return null;
        });

    await MushafReaderLibrary.ensureInitialized();
    controller = MushafReaderController(initialPage: 1);
    await controller.ensureReady();

    previousComparator = goldenFileComparator;
    goldenFileComparator = TolerantKfqcGoldenComparator(
      Uri.file(
        p.join(
          packageRoot.path,
          'test',
          'goldens',
          'kfqc_visual_golden_test.dart',
        ),
      ),
    );
  });

  tearDownAll(() async {
    goldenFileComparator = previousComparator;
    controller.dispose();
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  final fullRun = Platform.environment['MUSHAF_KFQC_FULL_GOLDENS'] == '1';
  final pages = _pagesToTest(refsDir: refsDir, fullRun: fullRun);

  for (final page in pages) {
    final stem = KfqcPageGeometry.pageStem(page);
    final refFile = File(p.join(refsDir.path, '$stem.png'));

    testWidgets('KFQC page $stem matches SVG raster', (tester) async {
      if (!refFile.existsSync()) {
        // Full suite: skip pages not rasterized yet instead of failing 500+.
        markTestSkipped(
          'Missing ${refFile.path}. Run:\n'
          '  dart run tool/rasterize_kfqc_svg.dart --pages=$page\n'
          'or:\n'
          '  dart run tool/rasterize_kfqc_svg.dart --all',
        );
        return;
      }

      // Preload page data outside fake-async so Hive futures complete.
      await tester.runAsync(() async {
        await controller.getPage(page);
      });

      // Flutter golden capture uses logical px at pixelRatio 1. Size the
      // viewport to the SVG raster so candidate and reference match.
      final raster = KfqcPageGeometry.rasterSizeForPage(page);
      final viewSize = Size(
        raster.width.toDouble(),
        raster.height.toDouble(),
      );
      tester.view.physicalSize = viewSize;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            home: ColoredBox(
              color: Colors.white,
              child: SizedBox(
                width: viewSize.width,
                height: viewSize.height,
                child: MushafPage(
                  page: page,
                  controller: controller,
                  style: _goldenStyle,
                  enableAyahHighlight: false,
                  // Flutter surah/juz chrome differs from KFQC path art.
                  hideHeader: true,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(PageAyahWidget), findsWidgets);
      expect(find.byType(PageNumberWidget), findsOneWidget);

      await expectLater(
        find.byType(MushafPage),
        matchesGoldenFile('kfqc_refs/$stem.png'),
      );
    });
  }

  test('blank page fails ink-density corruption check', () async {
    final refFile = File(p.join(refsDir.path, '003.png'));
    if (!refFile.existsSync()) {
      fail('Missing ${refFile.path}');
    }

    final blank = await _solidPng(
      KfqcPageGeometry.normalRasterWidth,
      KfqcPageGeometry.normalRasterHeight,
      const Color(0xFFFFFFFF),
    );
    final diff = await compareKfqcImages(
      candidatePng: blank,
      referencePng: Uint8List.fromList(await refFile.readAsBytes()),
    );
    expect(diff.passed, isFalse);
    expect(diff.candidateInkRatio, lessThan(KfqcImageDiff.minInkRatio));
  });
}

/// Smoke pages always; plus any `kfqc_refs/NNN.png` already on disk.
///
/// With `MUSHAF_KFQC_FULL_GOLDENS=1`, registers all 604 pages (missing refs
/// are skipped at runtime).
List<int> _pagesToTest({required Directory refsDir, required bool fullRun}) {
  if (fullRun) {
    return [for (var n = 1; n <= MushafConstants.pageCount; n++) n];
  }

  final pages = <int>{...KfqcPageGeometry.smokePages};
  if (refsDir.existsSync()) {
    for (final entity in refsDir.listSync()) {
      if (entity is! File || !entity.path.endsWith('.png')) continue;
      final stem = p.basenameWithoutExtension(entity.path);
      final page = int.tryParse(stem);
      if (page != null && page >= 1 && page <= MushafConstants.pageCount) {
        pages.add(page);
      }
    }
  }
  return pages.toList()..sort();
}

Future<Uint8List> _solidPng(int width, int height, Color color) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawColor(color, BlendMode.src);
  final image = await recorder.endRecording().toImage(width, height);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}
