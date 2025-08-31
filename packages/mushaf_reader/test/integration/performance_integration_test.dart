import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_reader/mushaf_reader.dart';

void main() {
  group('Integration Performance Tests', () {
    testWidgets('should initialize library efficiently', (tester) async {
      final stopwatch = Stopwatch()..start();

      await MushafController.instance.init();

      stopwatch.stop();

      // Initialization should complete in reasonable time (increased for JSON loading)
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(15000),
      ); // 15 seconds for first-time asset loading
    });

    testWidgets('should render MushafPage efficiently', (tester) async {
      await MushafController.instance.init();

      var ayahTapCount = 0;

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 800,
              width: 500,
              child: MushafPage(page: 1, onTapAyah: (ayahId) => ayahTapCount++),
            ),
          ),
        ),
      );

      stopwatch.stop();

      // Page should render in reasonable time
      expect(stopwatch.elapsedMilliseconds, lessThan(2000)); // 2 seconds

      // Verify page content
      expect(find.byType(PageNumberWidget), findsOneWidget);
      expect(find.text('١'), findsOneWidget); // Page 1 in Arabic numerals
    });

    testWidgets('should handle rapid page navigation efficiently', (
      tester,
    ) async {
      await MushafController.instance.init();

      final pageController = PageController();
      var currentPage = 1;

      Widget buildPageView() {
        return MaterialApp(
          home: Scaffold(
            body: PageView.builder(
              controller: pageController,
              itemCount: 10, // Test with first 10 pages
              onPageChanged: (index) => currentPage = index + 1,
              itemBuilder: (context, index) {
                return SizedBox(
                  height: 800,
                  width: 500,
                  child: MushafPage(
                    key: ValueKey('page_${index + 1}'),
                    page: index + 1,
                    onTapAyah: (ayahId) {},
                  ),
                );
              },
            ),
          ),
        );
      }

      await tester.pumpWidget(buildPageView());

      final stopwatch = Stopwatch()..start();

      // Navigate through multiple pages
      for (int i = 0; i < 5; i++) {
        await tester.drag(find.byType(PageView), const Offset(-400, 0));
        await tester.pumpAndSettle();
      }

      stopwatch.stop();

      // Navigation should be smooth and fast
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(3000),
      ); // 3 seconds for 5 page transitions
      expect(currentPage, greaterThan(1));

      pageController.dispose();
    });

    testWidgets('should handle multiple MushafPage widgets efficiently', (
      tester,
    ) async {
      await MushafController.instance.init();

      // Preload some pages for better performance
      await MushafController.instance.preloadPages([1, 2, 3]);

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    height: 600,
                    width: 400,
                    child: MushafPage(page: 1, onTapAyah: (ayahId) {}),
                  ),
                  SizedBox(
                    height: 600,
                    width: 400,
                    child: MushafPage(page: 2, onTapAyah: (ayahId) {}),
                  ),
                  SizedBox(
                    height: 600,
                    width: 400,
                    child: MushafPage(page: 3, onTapAyah: (ayahId) {}),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      stopwatch.stop();

      // Multiple pages should render efficiently due to optimizations
      expect(stopwatch.elapsedMilliseconds, lessThan(3000)); // 3 seconds

      // Verify all pages are rendered
      expect(find.byType(MushafPage), findsNWidgets(3));
      expect(find.byType(PageNumberWidget), findsNWidgets(3));
    });

    testWidgets('should maintain performance with style customization', (
      tester,
    ) async {
      await MushafController.instance.init();

      const customTextStyle = TextStyle(
        fontSize: 32,
        color: Colors.blue,
        fontWeight: FontWeight.bold,
      );

      const customActiveStyle = TextStyle(
        fontSize: 32,
        color: Colors.red,
        backgroundColor: Colors.yellow,
      );

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 800,
              width: 500,
              child: MushafPage(
                page: 1,
                textStyle: customTextStyle,
                activeTextStyle: customActiveStyle,
                highlightColor: Colors.orange,
                onTapAyah: (ayahId) {},
              ),
            ),
          ),
        ),
      );

      stopwatch.stop();

      // Custom styles should not significantly impact performance
      expect(stopwatch.elapsedMilliseconds, lessThan(2000)); // 2 seconds
      expect(find.byType(MushafPage), findsOneWidget);
    });

    testWidgets('should handle memory efficiently during extended usage', (
      tester,
    ) async {
      await MushafController.instance.init();

      // Simulate extended usage by creating and disposing multiple widgets
      for (int session = 0; session < 3; session++) {
        final stopwatch = Stopwatch()..start();

        for (int page = 1; page <= 5; page++) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  height: 800,
                  width: 500,
                  child: MushafPage(
                    key: ValueKey('session_${session}_page_$page'),
                    page: page,
                    onTapAyah: (ayahId) {},
                  ),
                ),
              ),
            ),
          );

          // Verify page renders correctly
          expect(find.byType(MushafPage), findsOneWidget);
        }

        stopwatch.stop();

        // Each session should maintain performance
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(2000),
        ); // 2 seconds per session
      }

      // Clean up caches
      PerformanceUtils.clearCaches();
      SurahHeaderWidget.clearCache();
    });

    testWidgets('should benefit from preloading optimization', (tester) async {
      await MushafController.instance.init();

      // Measure performance without preloading
      final stopwatch1 = Stopwatch()..start();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 800,
              width: 500,
              child: MushafPage(page: 50, onTapAyah: (ayahId) {}),
            ),
          ),
        ),
      );
      stopwatch1.stop();

      final timeWithoutPreload = stopwatch1.elapsedMilliseconds;

      // Preload pages
      await MushafController.instance.preloadPages([51, 52, 53]);

      // Measure performance with preloading
      final stopwatch2 = Stopwatch()..start();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 800,
              width: 500,
              child: MushafPage(page: 51, onTapAyah: (ayahId) {}),
            ),
          ),
        ),
      );
      stopwatch2.stop();

      final timeWithPreload = stopwatch2.elapsedMilliseconds;

      // Preloaded page should render faster or at least not slower
      expect(timeWithPreload, lessThanOrEqualTo(timeWithoutPreload + 100));
    });

    group('Stress Tests', () {
      testWidgets('should handle quick successive page changes', (
        tester,
      ) async {
        await MushafController.instance.init();

        final stopwatch = Stopwatch()..start();

        // Rapidly change pages
        for (int i = 1; i <= 20; i++) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  height: 800,
                  width: 500,
                  child: MushafPage(
                    key: ValueKey('rapid_page_$i'),
                    page: i,
                    onTapAyah: (ayahId) {},
                  ),
                ),
              ),
            ),
          );
        }

        stopwatch.stop();

        // Should handle rapid changes efficiently
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(5000),
        ); // 5 seconds for 20 pages
      });
    });
  });
}
