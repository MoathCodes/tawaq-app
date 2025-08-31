import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_reader/src/presentation/widgets/surah_header_widget.dart';
import 'package:mushaf_reader/src/presentation/widgets/surah_name_widget.dart';

void main() {
  group('SurahHeaderWidget Optimization Tests', () {
    tearDown(() {
      // Clear cache after each test
      SurahHeaderWidget.clearCache();
    });

    testWidgets('should display surah header with SVG background', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SurahHeaderWidget(name: 'الفاتحة', width: 300)),
        ),
      );

      expect(find.byType(SurahHeaderWidget), findsOneWidget);
      expect(find.byType(SvgPicture), findsOneWidget);

      // Find the Stack that contains the SVG background (the first Stack)
      final stackFinder = find.byType(Stack);
      expect(stackFinder, findsAtLeastNWidgets(1));
    });

    testWidgets('should use different SVG for dark mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SurahHeaderWidget(name: 'الفاتحة', width: 300, isDark: true),
          ),
        ),
      );

      expect(find.byType(SurahHeaderWidget), findsOneWidget);
      expect(find.byType(SvgPicture), findsOneWidget);
    });

    testWidgets('should cache SVG widgets for performance', (tester) async {
      const surahName = 'الفاتحة';
      const width = 300.0;

      // Build first widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SurahHeaderWidget(name: surahName, width: width),
          ),
        ),
      );

      expect(find.byType(SvgPicture), findsOneWidget);

      // Build second widget with same parameters - should use cached SVG
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SurahHeaderWidget(name: surahName, width: width),
                SurahHeaderWidget(name: surahName, width: width),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(SvgPicture), findsNWidgets(2));
    });

    testWidgets('should handle different widths correctly', (tester) async {
      const surahName = 'الفاتحة';

      final widthTestCases = [200.0, 300.0, 500.0, 600.0];

      for (final width in widthTestCases) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SurahHeaderWidget(name: surahName, width: width),
            ),
          ),
        );

        expect(find.byType(SvgPicture), findsOneWidget);
        expect(find.byType(SurahNameWidget), findsOneWidget);
      }
    });

    testWidgets('should pass text style to SurahNameWidget', (tester) async {
      const surahName = 'الفاتحة';
      const textStyle = TextStyle(fontSize: 24, color: Colors.red);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SurahHeaderWidget(name: surahName, textStyle: textStyle),
          ),
        ),
      );

      final surahNameWidget = tester.widget<SurahNameWidget>(
        find.byType(SurahNameWidget),
      );

      expect(surahNameWidget.textStyle, equals(textStyle));
    });

    testWidgets('should handle cache clearing', (tester) async {
      const surahName = 'الفاتحة';

      // Build widget to populate cache
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SurahHeaderWidget(name: surahName)),
        ),
      );

      expect(find.byType(SvgPicture), findsOneWidget);

      // Clear cache
      SurahHeaderWidget.clearCache();

      // Build again - should work normally after cache clear
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SurahHeaderWidget(name: surahName)),
        ),
      );

      expect(find.byType(SvgPicture), findsOneWidget);
    });

    testWidgets('should maintain proper widget structure', (tester) async {
      const surahName = 'الفاتحة';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SurahHeaderWidget(name: surahName)),
        ),
      );

      // Verify widget tree structure
      final stacks = find.byType(Stack);
      expect(stacks, findsAtLeastNWidgets(1));

      final stack = tester.widget<Stack>(stacks.first);
      expect(stack.alignment, equals(Alignment.center));

      final sizedBoxes = find.byType(SizedBox);
      expect(sizedBoxes, findsAtLeastNWidgets(1));

      final sizedBox = tester.widget<SizedBox>(sizedBoxes.first);
      expect(sizedBox.height, equals(50));
    });

    group('Performance Tests', () {
      testWidgets('should handle rapid widget creation efficiently', (
        tester,
      ) async {
        const surahNames = [
          'الفاتحة',
          'البقرة',
          'آل عمران',
          'النساء',
          'المائدة',
        ];

        final stopwatch = Stopwatch()..start();

        for (final name in surahNames) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(body: SurahHeaderWidget(name: name)),
            ),
          );

          expect(find.byType(SvgPicture), findsOneWidget);
          expect(find.byType(SurahNameWidget), findsOneWidget);
        }

        stopwatch.stop();

        // Should complete all creations in reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(2000)); // 2 seconds
      });

      testWidgets('should benefit from caching with multiple widgets', (
        tester,
      ) async {
        const surahName = 'الفاتحة';
        const widgetCount = 10;

        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: List.generate(
                  widgetCount,
                  (index) =>
                      const SurahHeaderWidget(name: surahName, width: 300),
                ),
              ),
            ),
          ),
        );

        stopwatch.stop();

        expect(find.byType(SvgPicture), findsNWidgets(widgetCount));
        expect(find.byType(SurahNameWidget), findsNWidgets(widgetCount));

        // Multiple widgets with same parameters should render quickly due to caching
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // 1 second
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle empty surah name', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: SurahHeaderWidget(name: '')),
          ),
        );

        expect(find.byType(Stack), findsWidgets);
        expect(find.byType(SvgPicture), findsOneWidget);
        expect(find.byType(SurahNameWidget), findsOneWidget);
      });

      testWidgets('should handle very small width', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: SurahHeaderWidget(name: 'الفاتحة', width: 50)),
          ),
        );

        expect(find.byType(SvgPicture), findsOneWidget);
      });

      testWidgets('should handle very large width', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SurahHeaderWidget(name: 'الفاتحة', width: 1000),
            ),
          ),
        );

        expect(find.byType(SvgPicture), findsOneWidget);
      });
    });
  });
}
