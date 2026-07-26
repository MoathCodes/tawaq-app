import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/commentary/commentary_inline_spans.dart';
import 'package:tawaq/core/commentary/commentary_text_styles.dart';

void main() {
  late CommentaryTextStyles styles;

  setUp(() {
    final colors = FTheme.neutral.light.desktop.colors;
    styles = CommentaryTextStyles.from(
      baseStyle: const TextStyle(fontSize: 14),
      colors: colors,
      isDark: false,
    );
  });

  Future<List<InlineSpan>> buildSpans(
    WidgetTester tester,
    String input, {
    bool emphasizeQawl = false,
  }) async {
    late List<InlineSpan> spans;
    await tester.pumpWidget(
      MaterialApp(
        home: CommentaryStyleScope(
          styles: styles,
          child: Builder(
            builder: (context) {
              spans = CommentaryInlineSpans.build(
                context,
                input,
                emphasizeQawl: emphasizeQawl,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    return spans;
  }

  List<({String text, FontWeight? weight, Color? color})> styledRuns(
    List<InlineSpan> spans,
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

    for (final span in spans) {
      walk(span);
    }
    return runs;
  }

  group('CommentaryInlineSpans.build', () {
    testWidgets('styles qawl lead phrases', (tester) async {
      final runs = styledRuns(
        await buildSpans(tester, 'وقوله تعالى: ﴿بسم الله﴾'),
      );

      expect(runs, hasLength(2));
      expect(runs[0].text, 'وقوله تعالى: ');
      expect(runs[0].weight, FontWeight.w700);
      expect(runs[0].color, styles.qawlLead.color);
      expect(runs[1].text, '﴿بسم الله﴾');
      expect(runs[1].color, styles.ayah.color);
    });

    testWidgets('styles scholar dialogue leads', (tester) async {
      final runs = styledRuns(
        await buildSpans(tester, 'قال ابن عباس: معناه كذا'),
      );

      expect(runs.first.text, 'قال ابن عباس: ');
      expect(runs.first.weight, FontWeight.w600);
      expect(runs.first.color, styles.scholarLead.color);
    });

    testWidgets('styles guillemet-quoted prayer phrases', (tester) async {
      const input =
          'فقال: «التَّحيَّاتُ لله»، هي جَمعُ تحيَّةٍ '
          '«\u200fوالصَّلَواتُ» «\u200fوالطَّيِّباتُ»';
      final runs = styledRuns(await buildSpans(tester, input));

      final quoteRuns = runs
          .where(
            (run) =>
                run.text.startsWith('«') &&
                run.weight == FontWeight.w600 &&
                run.color == styles.quote.color,
          )
          .toList();

      expect(quoteRuns.length, 3);
      expect(quoteRuns[0].text, '«التَّحيَّاتُ لله»');
      expect(quoteRuns[1].text, '«\u200fوالصَّلَواتُ»');
      expect(quoteRuns[2].text, '«\u200fوالطَّيِّباتُ»');
    });

    testWidgets('styles ayah snippets and verse references', (tester) async {
      final runs = styledRuns(
        await buildSpans(
          tester,
          'نص ﴿الحمد لله﴾ سورة الفاتحة، الآية: 1 متابعة',
        ),
      );

      expect(runs, hasLength(4));
      expect(runs[0].text, 'نص ');
      expect(runs[0].color, styles.prose.color);
      expect(runs[1].text, '﴿الحمد لله﴾');
      expect(runs[1].color, styles.ayah.color);
      expect(runs[2].text, ' سورة الفاتحة، الآية: 1');
      expect(runs[2].color, styles.verseRef.color);
      expect(runs[3].text, ' متابعة');
      expect(runs[3].color, styles.prose.color);
    });
  });

  group('isolateLtrNumerals', () {
    test('wraps digit and slash runs in LTR isolates', () {
      expect(
        isolateLtrNumerals('ص 12/345'),
        'ص \u206612/345\u2069',
      );
    });
  });
}
