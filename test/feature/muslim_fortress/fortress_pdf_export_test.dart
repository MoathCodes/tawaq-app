import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/share/fortress_pdf_export.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late String page;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('fortress-pdf-worker-');
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawRect(
      const ui.Rect.fromLTWH(0, 0, 8, 8),
      ui.Paint()..color = const ui.Color(0xff997733),
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(8, 8);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    page = '${directory.path}/page.png';
    await File(page).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
    picture.dispose();
  });
  tearDown(() => directory.delete(recursive: true));

  test('worker creates every ordered PDF page and reports progress', () async {
    final destination = '${directory.path}/booklet.pdf';
    final progress = <int>[];
    await FortressPdfExport().run(
      pages: List.filled(4, page),
      destination: destination,
      onProgress: progress.add,
    );
    final text = latin1.decode(await File(destination).readAsBytes());
    expect(text, startsWith('%PDF-'));
    expect(RegExp(r'/Type\s*/Page\b').allMatches(text).length, 4);
    expect(progress, [1, 2, 3, 4]);
  });

  test('cancellation stops assembly and allows a fresh job', () async {
    final job = FortressPdfExport();
    final destination = '${directory.path}/cancelled.pdf';
    final result = job.run(
      pages: List.filled(100, page),
      destination: destination,
      onProgress: (_) => job.cancel(),
    );
    await expectLater(result, throwsA(isA<FortressPdfCancelled>()));
    expect(await File(destination).exists(), isFalse);
    await FortressPdfExport().run(
      pages: [page],
      destination: destination,
      onProgress: (_) {},
    );
    expect(await File(destination).exists(), isTrue);
  });

  test('worker file failures propagate without hanging', () async {
    await expectLater(
      FortressPdfExport().run(
        pages: ['${directory.path}/missing.png'],
        destination: '${directory.path}/failed.pdf',
        onProgress: (_) {},
      ),
      throwsA(isA<StateError>()),
    );
  });
}
