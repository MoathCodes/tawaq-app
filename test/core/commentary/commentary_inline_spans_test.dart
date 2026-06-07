import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/commentary/commentary_inline_spans.dart';
import 'package:tawaq/core/commentary/commentary_text_styles.dart';

void main() {
  late CommentaryTextStyles styles;

  setUp(() {
    final colors = FThemes.zinc.light.desktop.colors;
    styles = CommentaryTextStyles.from(
      baseStyle: const TextStyle(fontSize: 14),
      colors: colors,
      isDark: false,
    );
  });

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
    test('styles qawl lead phrases', () {
      final runs = styledRuns(
        CommentaryInlineSpans.build(
          'وقوله تعالى: ﴿بسم الله﴾',
          styles: styles,
        ),
      );

      expect(runs, hasLength(2));
      expect(runs[0].text, 'وقوله تعالى: ');
      expect(runs[0].weight, FontWeight.w700);
      expect(runs[0].color, styles.qawlLead.color);
      expect(runs[1].text, '﴿بسم الله﴾');
      expect(runs[1].color, styles.ayah.color);
    });

    test('styles scholar dialogue leads', () {
      final runs = styledRuns(
        CommentaryInlineSpans.build(
          'قال ابن عباس: معناه كذا',
          styles: styles,
        ),
      );

      expect(runs.first.text, 'قال ابن عباس: ');
      expect(runs.first.weight, FontWeight.w600);
      expect(runs.first.color, styles.scholarLead.color);
    });

    test('styles ayah snippets and verse references', () {
      final runs = styledRuns(
        CommentaryInlineSpans.build(
          'نص ﴿الحمد لله﴾ سورة الفاتحة، الآية: 1 متابعة',
          styles: styles,
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
