import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/detail/hadith_sharh_text.dart';
import 'package:tawaq/theme/durations.dart';
import 'package:tawaq/theme/radii.dart';

void main() {
  late List<Map<String, dynamic>> fixtures;

  setUpAll(() {
    final raw = File('test/fixtures/hadith_sharh_samples.json').readAsStringSync();
    fixtures = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  });

  Map<String, dynamic> fixture(String id) {
    return fixtures.firstWhere((entry) => entry['id'] == id);
  }

  Widget wrap(Widget child) {
    return FTheme(
      data: FThemeData(
        colors: FTheme.neutral.light.desktop.colors,
        typography: FTheme.neutral.light.desktop.typography,
        icons: FTheme.neutral.light.desktop.icons,
        touch: false,
        extensions: const [AppRadii.standard(), AppDurations.standard()],
      ),
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: child),
        ),
      ),
    );
  }

  String plainText(InlineSpan span) {
    final buffer = StringBuffer();
    void walk(InlineSpan node) {
      if (node is TextSpan) {
        buffer.write(node.text ?? '');
        for (final child in node.children ?? const <InlineSpan>[]) {
          walk(child);
        }
      }
    }

    walk(span);
    return buffer.toString();
  }

  List<({String text, FontWeight? weight, Color? color})> styledRuns(
    InlineSpan span,
  ) {
    final runs = <({String text, FontWeight? weight, Color? color})>[];
    void walk(InlineSpan node) {
      if (node is TextSpan) {
        final text = node.text;
        if (text != null && text.isNotEmpty) {
          runs.add((
            text: text,
            weight: node.style?.fontWeight,
            color: node.style?.color,
          ));
        }
        for (final child in node.children ?? const <InlineSpan>[]) {
          walk(child);
        }
      }
    }

    walk(span);
    return runs;
  }

  group('Sharh 113371 — gloss and quote styling', () {
    testWidgets('renders gloss chains and section leads', (tester) async {
      final sample = fixture('113371');
      await tester.pumpWidget(
        wrap(HadithSharhText(text: sample['sharh'] as String)),
      );

      final richTexts = tester.widgetList<ScopedSelectableRichText>(
        find.byType(ScopedSelectableRichText),
      );
      expect(richTexts, isNotEmpty);

      final allRuns = richTexts
          .expand((rt) => styledRuns(rt.textSpan))
          .toList(growable: false);

      expect(
        allRuns.any(
          (run) =>
              (run.text.contains('أي:') || run.text.contains('، أي:')) &&
              run.weight == FontWeight.w600,
        ),
        isTrue,
      );
      expect(
        allRuns.any(
          (run) =>
              (run.text.startsWith('"') || run.text.startsWith('«')) &&
              run.weight == FontWeight.w600,
        ),
        isTrue,
      );
    });
  });

  group('Sharh 15844 — Tashahhud guillemet styling', () {
    testWidgets('renders guillemet prayer phrases with quote styling', (
      tester,
    ) async {
      final sample = fixture('15844');
      await tester.pumpWidget(
        wrap(HadithSharhText(text: sample['sharh'] as String)),
      );

      final richTexts = tester.widgetList<ScopedSelectableRichText>(
        find.byType(ScopedSelectableRichText),
      );
      final allRuns = richTexts
          .expand((rt) => styledRuns(rt.textSpan))
          .toList(growable: false);

      final quoteRuns = allRuns
          .where(
            (run) => run.text.startsWith('«') && run.weight == FontWeight.w600,
          )
          .toList();

      expect(quoteRuns.length, greaterThanOrEqualTo(10));
      expect(
        quoteRuns.any((run) => run.text.contains('التَّحيَّاتُ لله')),
        isTrue,
      );
      expect(
        quoteRuns.any((run) => run.text.contains('والصَّلَواتُ')),
        isTrue,
      );
    });
  });

  group('Sharh 15844 — وقيل styling', () {
    testWidgets('renders alternate opinions in muted italic', (tester) async {
      final sample = fixture('15844');
      await tester.pumpWidget(
        wrap(HadithSharhText(text: sample['sharh'] as String)),
      );

      final richTexts = tester.widgetList<ScopedSelectableRichText>(
        find.byType(ScopedSelectableRichText),
      );
      final allRuns = richTexts
          .expand((rt) => styledRuns(rt.textSpan))
          .toList(growable: false);

      expect(
        allRuns.any(
          (run) =>
              run.text.contains('وقيل:') &&
              run.weight != FontWeight.w600,
        ),
        isTrue,
      );
    });
  });

  group('Sharh 4730 — guillemet gloss chain layout', () {
    testWidgets('does not render orphan comma before أي:', (tester) async {
      final sample = fixture('4730');
      await tester.pumpWidget(
        wrap(HadithSharhText(text: sample['sharh'] as String)),
      );

      final richTexts = tester.widgetList<ScopedSelectableRichText>(
        find.byType(ScopedSelectableRichText),
      );
      final allRuns = richTexts
          .expand((rt) => styledRuns(rt.textSpan))
          .toList(growable: false);

      expect(
        allRuns.any((run) => run.text.trim() == '،'),
        isFalse,
        reason: 'dangling comma must not appear as its own text run',
      );

      final chainWidget = richTexts.firstWhere(
        (rt) => styledRuns(rt.textSpan).any(
          (run) => run.text.contains('«تَرى ما لا أرى»'),
        ),
      );
      final chainRuns = styledRuns(chainWidget.textSpan);
      expect(
        chainRuns.any((run) => run.text.contains('، أي:')),
        isTrue,
        reason: 'comma and gloss lead should stay with the quoted phrase',
      );
    });
  });

  group('Sharh 113371 — metadata card', () {
    testWidgets('shows metadata card for metadata-rich sharh', (tester) async {
      final sample = fixture('113371');
      await tester.pumpWidget(
        wrap(HadithSharhText(text: sample['sharh'] as String)),
      );

      expect(find.textContaining('الراوي'), findsOneWidget);
    });
  });

  group('Sharh 211278 — inline gloss flow', () {
    testWidgets('merges gloss segments into one selectable rich text run', (
      tester,
    ) async {
      final sample = fixture('211278');
      await tester.pumpWidget(
        wrap(HadithSharhText(text: sample['sharh'] as String)),
      );

      final richTexts = tester
          .widgetList<ScopedSelectableRichText>(
            find.byType(ScopedSelectableRichText),
          )
          .toList(growable: false);

      // Metadata card may add its own rich text; commentary body should be one run.
      expect(richTexts.length, lessThanOrEqualTo(2));

      final commentaryRun = richTexts.reduce((a, b) {
        final aRuns = styledRuns(a.textSpan);
        final bRuns = styledRuns(b.textSpan);
        return aRuns.length >= bRuns.length ? a : b;
      });
      final runs = styledRuns(commentaryRun.textSpan);

      expect(
        runs.any((run) => run.text.contains('أي:') && run.weight == FontWeight.w600),
        isTrue,
        reason: 'gloss markers should stay styled inline',
      );

      final glossRuns = runs.where((run) => run.text.contains('أي:')).toList();
      expect(glossRuns, isNotEmpty);

      for (final glossRun in glossRuns) {
        final index = runs.indexOf(glossRun);
        final hasNeighborProse = (index > 0 && !runs[index - 1].text.contains('أي:')) ||
            (index + 1 < runs.length && !runs[index + 1].text.contains('أي:'));
        expect(
          hasNeighborProse,
          isTrue,
          reason: 'أي: gloss marker should sit inline beside prose in the same run',
        );
      }
    });

    testWidgets('preserves spaces around inline gloss markers', (tester) async {
      final sample = fixture('211278');
      await tester.pumpWidget(
        wrap(HadithSharhText(text: sample['sharh'] as String)),
      );

      final richTexts = tester
          .widgetList<ScopedSelectableRichText>(
            find.byType(ScopedSelectableRichText),
          )
          .toList(growable: false);

      final commentaryRun = richTexts.reduce((a, b) {
        final aRuns = styledRuns(a.textSpan);
        final bRuns = styledRuns(b.textSpan);
        return aRuns.length >= bRuns.length ? a : b;
      });
      final rendered = plainText(commentaryRun.textSpan);

      expect(rendered, contains('، أي:'));
      expect(rendered, contains('أي: كان'));
      expect(rendered, contains('حَسَناتٍ، أي: استَحَقَّ'));
      expect(rendered, contains('أقَلُّه، فقال'));

      expect(rendered, isNot(contains('،أي:')));
      expect(rendered, isNot(contains('أي:كان')));
      expect(rendered, isNot(contains('حَسَناتٍ،أي:')));
      expect(rendered, isNot(contains('أقَلُّه،فقال')));
    });

    testWidgets('commentary body uses a single selectable rich text widget', (
      tester,
    ) async {
      final sample = fixture('211278');
      await tester.pumpWidget(
        wrap(HadithSharhText(text: sample['sharh'] as String)),
      );

      final richTexts = tester.widgetList<ScopedSelectableRichText>(
        find.byType(ScopedSelectableRichText),
      );

      final hasCrossStyleRun = richTexts.any((rt) {
        final runs = styledRuns(rt.textSpan);
        final hasGloss = runs.any(
          (run) => run.text.contains('أي:') && run.weight == FontWeight.w600,
        );
        final hasProse = runs.any(
          (run) => !run.text.contains('أي:') && run.weight != FontWeight.w600,
        );
        return hasGloss && hasProse;
      });

      expect(
        hasCrossStyleRun,
        isTrue,
        reason: 'selection should span prose and gloss in one widget',
      );
    });
  });
}
