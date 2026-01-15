import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import '../test_utils.dart';

void main() {
  group('MushafReaderController Tests', () {
    late MushafReaderController controller;
    late MockQuranRepository mockRepo;

    setUp(() {
      mockRepo = MockQuranRepository();
      controller = MushafReaderController.withRepository(
        repository: mockRepo,
        initialPage: 1,
      );
    });

    test('Initial state is correct', () async {
      expect(controller.currentPage, 1);
      expect(controller.isInitialized, true);
      expect(controller.selectedAyahId, null);

      // Wait for async init to complete (microtask)
      await Future.microtask(() {});
      expect(controller.currentPageInfo, isNotNull);
      expect(controller.currentPageInfo?.pageNumber, 1);
    });

    test('Navigation works', () {
      controller.nextPage();
      expect(controller.currentPage, 2);

      controller.previousPage();
      expect(controller.currentPage, 1);

      controller.jumpToPage(10);
      expect(controller.currentPage, 10);
    });

    test('Selection works', () {
      controller.selectAyah(1);
      expect(controller.selectedAyahId, 1);

      controller.clearSelection();
      expect(controller.selectedAyahId, null);
    });

    test('Two page view mode', () {
      final twoPageController = MushafReaderController.withRepository(
        repository: mockRepo,
        initialPage: 1,
        pagesPerViewport: 2,
      );

      expect(twoPageController.currentPage, 1);
      expect(twoPageController.currentPages, (1, 2));

      twoPageController.nextPage();
      // Should jump to 3 (1,2 -> 3,4)
      expect(twoPageController.currentPage, 3);
      expect(twoPageController.currentPages, (3, 4));
    });

    test('jumpToSurah navigates correctly', () async {
      await controller.jumpToSurah(5);
      // Mock repo returns surahNumber as start page
      expect(controller.currentPage, 5);
    });

    test('jumpToJuz navigates correctly', () async {
      await controller.jumpToJuz(2);
      // Mock repo: (2-1)*20 + 2 = 22
      expect(controller.currentPage, 22);
    });
  });
}
