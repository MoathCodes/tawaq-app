import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_reader/mushaf_reader.dart';

import '../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MushafReader layout stability', () {
    late MushafReaderController controller;

    setUp(() async {
      controller = MushafReaderController.withRepository(
        repository: MockQuranRepository(),
        initialPage: 50,
      );
      await controller.ensureReady();
      controller.jumpToPage(50);
    });

    tearDown(() {
      controller.dispose();
    });

    Future<void> pumpReader(
      WidgetTester tester, {
      required double width,
      Key? key,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: width,
            height: 600,
            child: MushafReader(
              key: key,
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('keeps current page when the parent resizes', (tester) async {
      await pumpReader(tester, width: 800);
      expect(controller.currentPage, 50);

      await pumpReader(tester, width: 420);
      expect(controller.currentPage, 50);
    });

    testWidgets('keeps current page when the reader widget is recreated',
        (tester) async {
      await pumpReader(tester, width: 800, key: const ValueKey('first'));
      expect(controller.currentPage, 50);

      await pumpReader(tester, width: 800, key: const ValueKey('second'));
      expect(controller.currentPage, 50);
      expect(controller.pageController.page?.round(), 49);
    });
  });
}
