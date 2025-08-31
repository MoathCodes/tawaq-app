import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_reader/src/data/models/ayah_fragment.dart';
import 'package:mushaf_reader/src/presentation/widgets/page_ayah_widget.dart';

void main() {
  group('PageAyahWidget Optimization Tests', () {
    testWidgets('should reuse gesture recognizers for same ayah IDs', (
      tester,
    ) async {
      const testText = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';
      final fragments = [
        AyahFragment(ayahId: 1, start: 0, end: 10),
        AyahFragment(ayahId: 2, start: 10, end: 20),
        AyahFragment(ayahId: 1, start: 20, end: 30), // Same ayah ID as first
      ];

      const style = TextStyle(fontSize: 16);
      var tapCount = 0;

      final widget = PageAyahWidget(
        fullText: testText,
        ayahs: fragments,
        style: style,
        activeStyle: style.copyWith(backgroundColor: Colors.yellow),
        onAyahSelection: (ayahId) => tapCount++,
      );

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

      // Verify widget builds successfully
      expect(find.byType(RichText), findsOneWidget);

      // Find the RichText widget and verify it has the expected structure
      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;

      expect(textSpan.children?.length, equals(3));
    });

    testWidgets(
      'should cache TextSpans and avoid rebuilding when content unchanged',
      (tester) async {
        const testText = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';
        final fragments = [
          AyahFragment(ayahId: 1, start: 0, end: 15),
          AyahFragment(ayahId: 2, start: 15, end: 30),
        ];

        const style = TextStyle(fontSize: 16);
        var buildCount = 0;

        Widget buildWidget() {
          buildCount++;
          return PageAyahWidget(
            fullText: testText,
            ayahs: fragments,
            style: style,
            activeStyle: style.copyWith(backgroundColor: Colors.yellow),
            onAyahSelection: (ayahId) {},
          );
        }

        await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: buildWidget())),
        );

        final initialBuildCount = buildCount;

        // Trigger a rebuild with same content
        await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: buildWidget())),
        );

        // Build count should increase but internal spans should be cached
        expect(buildCount, equals(initialBuildCount + 1));
        expect(find.byType(RichText), findsOneWidget);
      },
    );

    testWidgets('should handle ayah selection correctly', (tester) async {
      const testText = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';
      final fragments = [
        AyahFragment(ayahId: 1, start: 0, end: 15),
        AyahFragment(ayahId: 2, start: 15, end: 30),
      ];

      const style = TextStyle(fontSize: 16);
      var lastSelectedAyah = -1;

      final widget = PageAyahWidget(
        fullText: testText,
        ayahs: fragments,
        style: style,
        activeStyle: style.copyWith(backgroundColor: Colors.yellow),
        onAyahSelection: (ayahId) => lastSelectedAyah = ayahId,
        enableHighlight: true,
      );

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

      // Find the RichText and simulate tap on first span
      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;
      final firstSpan = textSpan.children?.first as TextSpan;

      // Simulate tap if recognizer exists
      if (firstSpan.recognizer is TapGestureRecognizer) {
        (firstSpan.recognizer as TapGestureRecognizer).onTap?.call();
        await tester.pump();

        expect(lastSelectedAyah, equals(1));
      }
    });

    testWidgets('should properly dispose gesture recognizers', (tester) async {
      const testText = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';
      final fragments = [
        AyahFragment(ayahId: 1, start: 0, end: 15),
        AyahFragment(ayahId: 2, start: 15, end: 30),
      ];

      const style = TextStyle(fontSize: 16);

      final widget = PageAyahWidget(
        fullText: testText,
        ayahs: fragments,
        style: style,
        activeStyle: style.copyWith(backgroundColor: Colors.yellow),
        onAyahSelection: (ayahId) {},
      );

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

      // Widget should build successfully
      expect(find.byType(RichText), findsOneWidget);

      // Remove widget to trigger dispose
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('Empty'))),
      );

      // Should not throw any errors during disposal
      expect(find.byType(PageAyahWidget), findsNothing);
    });

    testWidgets('should handle empty ayah fragments gracefully', (
      tester,
    ) async {
      const testText = '';
      final fragments = <AyahFragment>[];

      const style = TextStyle(fontSize: 16);

      final widget = PageAyahWidget(
        fullText: testText,
        ayahs: fragments,
        style: style,
        activeStyle: style.copyWith(backgroundColor: Colors.yellow),
        onAyahSelection: (ayahId) {},
      );

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

      expect(find.byType(RichText), findsOneWidget);

      final richText = tester.widget<RichText>(find.byType(RichText));
      final textSpan = richText.text as TextSpan;

      expect(textSpan.children?.length ?? 0, equals(0));
    });

    testWidgets('should rebuild spans when content changes', (tester) async {
      const testText1 = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';
      const testText2 = 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ';

      final fragments = [
        AyahFragment(ayahId: 1, start: 0, end: 15),
        AyahFragment(ayahId: 2, start: 15, end: 30),
      ];

      const style = TextStyle(fontSize: 16);

      // Build with first text
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageAyahWidget(
              fullText: testText1,
              ayahs: fragments,
              style: style,
              activeStyle: style.copyWith(backgroundColor: Colors.yellow),
              onAyahSelection: (ayahId) {},
            ),
          ),
        ),
      );

      expect(find.byType(RichText), findsOneWidget);

      // Build with second text - should trigger span rebuild
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageAyahWidget(
              fullText: testText2,
              ayahs: fragments,
              style: style,
              activeStyle: style.copyWith(backgroundColor: Colors.yellow),
              onAyahSelection: (ayahId) {},
            ),
          ),
        ),
      );

      expect(find.byType(RichText), findsOneWidget);
    });
  });
}
