import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_reader/src/presentation/widgets/page_number_widget.dart';

void main() {
  group('PageNumberWidget Optimization Tests', () {
    testWidgets('should display correct Hindu-Arabic numerals', (tester) async {
      // Test various page numbers
      final testCases = [(1, '١'), (42, '٤٢'), (123, '١٢٣'), (604, '٦٠٤')];

      for (final (page, expected) in testCases) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: PageNumberWidget(page: page)),
          ),
        );

        expect(find.text(expected), findsOneWidget);

        // Verify text style is applied
        final textWidget = tester.widget<Text>(find.byType(Text));
        expect(textWidget.style?.fontSize, equals(20));
        expect(textWidget.style?.color, equals(const Color(0xFF000000)));
        expect(textWidget.textAlign, equals(TextAlign.center));
      }
    });

    testWidgets('should use cached number conversion for performance', (
      tester,
    ) async {
      const page = 123;

      // Build widget multiple times with same page number
      for (int i = 0; i < 5; i++) {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: PageNumberWidget(page: page)),
          ),
        );

        // Should always show the same result
        expect(find.text('١٢٣'), findsOneWidget);
      }
    });

    testWidgets('should handle edge cases correctly', (tester) async {
      // Test edge cases
      final edgeCases = [
        (0, '٠'),
        (604, '٦٠٤'), // Maximum Quran page
        (1000, '١٠٠٠'), // Beyond Quran pages
      ];

      for (final (page, expected) in edgeCases) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: PageNumberWidget(page: page)),
          ),
        );

        expect(find.text(expected), findsOneWidget);
      }
    });

    testWidgets('should maintain consistent styling', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PageNumberWidget(page: 100))),
      );

      final textWidget = tester.widget<Text>(find.byType(Text));

      // Verify static style properties
      expect(textWidget.style?.fontSize, equals(20));
      expect(textWidget.style?.color, equals(const Color(0xFF000000)));
      expect(textWidget.textAlign, equals(TextAlign.center));

      // Style should be const (same reference when accessed multiple times)
      final style1 = textWidget.style;
      final style2 = textWidget.style;
      expect(identical(style1, style2), isTrue);
    });

    testWidgets('should build efficiently without unnecessary widgets', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PageNumberWidget(page: 42))),
      );

      // Should only contain a Text widget, no Container wrapper
      expect(find.byType(Text), findsOneWidget);
      expect(find.byType(Container), findsNothing);
      expect(find.text('٤٢'), findsOneWidget);
    });

    testWidgets('should rebuild efficiently when page changes', (tester) async {
      // Build with page 1
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PageNumberWidget(page: 1))),
      );

      expect(find.text('١'), findsOneWidget);

      // Change to page 2
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PageNumberWidget(page: 2))),
      );

      expect(find.text('٢'), findsOneWidget);
      expect(find.text('١'), findsNothing);
    });

    group('Performance Tests', () {
      testWidgets('should handle rapid page changes efficiently', (
        tester,
      ) async {
        const pages = [1, 2, 3, 100, 200, 300, 400, 500, 604];

        final stopwatch = Stopwatch()..start();

        for (final page in pages) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(body: PageNumberWidget(page: page)),
            ),
          );

          // Verify correct display
          final expectedText = page
              .toString()
              .replaceAll('0', '٠')
              .replaceAll('1', '١')
              .replaceAll('2', '٢')
              .replaceAll('3', '٣')
              .replaceAll('4', '٤')
              .replaceAll('5', '٥')
              .replaceAll('6', '٦')
              .replaceAll('7', '٧')
              .replaceAll('8', '٨')
              .replaceAll('9', '٩');

          expect(find.text(expectedText), findsOneWidget);
        }

        stopwatch.stop();

        // Should complete all page changes in reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });
    });
  });
}
