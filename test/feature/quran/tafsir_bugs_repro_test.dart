import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/widgets/desktop_selection.dart';
import 'package:tawaq/feature/quran/domain/models/tafsir_source.dart';
import 'package:tawaq/feature/quran/domain/models/tafsir_text_segment.dart';
import 'package:tawaq/feature/quran/domain/services/tafsir_text_parser.dart';
import 'package:tawaq/feature/quran/presentation/widgets/study/tafsir_text.dart';
import 'package:tawaq/theme/durations.dart';
import 'package:tawaq/theme/radii.dart';

void main() {
  Widget wrap(Widget child) {
    return FTheme(
      data: FThemeData(
        colors: FThemes.zinc.light.desktop.colors,
        typography: FThemes.zinc.light.desktop.typography,
        icons: FThemes.zinc.light.desktop.icons,
        touch: false,
        extensions: const [AppRadii.standard(), AppDurations.standard()],
      ),
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  group('IK 1:1 qawl+ayah+ref spacing', () {
    const raw =
        'لقوله تعالى: '
        '<span class="t3">( ولقد آتيناك سبعا من المثاني )</span> '
        '<span class="t2">[ الحجر : 87 ]</span> '
        'والله أعلم.';

    test('parses qawl, ayah, reference, and commentary segments', () {
      final segments = TafsirTextParser.parse(raw, tafsirId: TafsirId.ibnKathir);

      expect(segments, hasLength(4));
      expect(segments[0].kind, TafsirSegmentKind.commentary);
      expect(segments[0].text, 'لقوله تعالى:');
      expect(segments[1].kind, TafsirSegmentKind.ayah);
      expect(segments[1].text, '﴿ولقد آتيناك سبعا من المثاني﴾');
      expect(segments[2].kind, TafsirSegmentKind.reference);
      expect(segments[2].text, '[الحجر: 87]');
      expect(segments[3].kind, TafsirSegmentKind.commentary);
      expect(segments[3].text, 'والله أعلم.');
    });

    testWidgets('renders spaces between inline segment kinds', (tester) async {
      await tester.pumpWidget(
        wrap(
          const TafsirText(
            text: raw,
            baseStyle: TextStyle(fontSize: 14),
            tafsirId: TafsirId.ibnKathir,
          ),
        ),
      );

      final richText = tester.widget<ScopedSelectableRichText>(
        find.byType(ScopedSelectableRichText),
      );
      final plain = richText.textSpan.toPlainText();

      expect(plain, contains('تعالى: ﴿'));
      expect(plain, contains('﴾ ['));
      expect(plain, contains('87] والله'));
    });
  });

  group('Arabic prefix particle qawl leads', () {
    List<({String text, FontWeight? weight})> styledRuns(InlineSpan span) {
      final runs = <({String text, FontWeight? weight})>[];
      void walk(InlineSpan node) {
        if (node is TextSpan) {
          final text = node.text;
          if (text != null && text.isNotEmpty) {
            runs.add((text: text, weight: node.style?.fontWeight));
          }
          for (final child in node.children ?? const <InlineSpan>[]) {
            walk(child);
          }
        }
      }

      walk(span);
      return runs;
    }

    Future<List<({String text, FontWeight? weight})>> pumpAndCollectRuns(
      WidgetTester tester,
      String raw,
    ) async {
      await tester.pumpWidget(
        wrap(
          TafsirText(
            text: raw,
            baseStyle: const TextStyle(fontSize: 14),
            tafsirId: TafsirId.ibnKathir,
          ),
        ),
      );

      final richText = tester.widget<ScopedSelectableRichText>(
        find.byType(ScopedSelectableRichText),
      );
      return styledRuns(richText.textSpan);
    }

    testWidgets('styles attached لقوله تعالى as one qawl lead', (tester) async {
      const raw = 'لقوله تعالى: '
          '<span class="t3">( ولقد آتيناك سبعا من المثاني )</span>';

      final runs = await pumpAndCollectRuns(tester, raw);
      final qawlRuns = runs.where((run) => run.weight == FontWeight.w700);

      expect(qawlRuns, hasLength(1));
      expect(qawlRuns.first.text, 'لقوله تعالى:');
      expect(runs.first.text, isNot('ل'));
    });

    testWidgets('styles prefixed qawl leads without detaching particles', (
      tester,
    ) async {
      for (final lead in ['وقوله:', 'بقوله:', 'فقوله:', 'كقوله:']) {
        final runs = await pumpAndCollectRuns(
          tester,
          '$lead <span class="t3">( text )</span>',
        );
        final qawlRuns = runs.where((run) => run.weight == FontWeight.w700);

        expect(qawlRuns, hasLength(1), reason: lead);
        expect(qawlRuns.first.text, startsWith(lead), reason: lead);
      }
    });

    testWidgets('merges parser-split prefix particle with following qawl lead', (
      tester,
    ) async {
      const raw =
          'ل<span class="t2">قوله تعالى: ( ولقد آتيناك سبعا من المثاني )</span>';

      final runs = await pumpAndCollectRuns(tester, raw);
      final plain = runs.map((run) => run.text).join();
      final qawlRuns = runs.where((run) => run.weight == FontWeight.w700);

      expect(plain, contains('لقوله تعالى:'));
      expect(plain, isNot(contains('ل قوله')));
      expect(qawlRuns, isNotEmpty);
      expect(qawlRuns.first.text, startsWith('لقوله تعالى:'));
    });
  });

  group("Abī ibn Ka'b hadith ayah classification", () {
    const raw =
        'حديث '
        '<span class="t2">[ قال ]</span> '
        ': ما منعك أي أبي إذ دعوتك أن تجيبني ۞ قال: أي رسول الله ۞ كنت في الصلاة ۞ '
        'قال: أولست تجد فيما أوحى الله إلي استجيبوا لله وللرسول إذا دعاكم لما يحييكم ) '
        '<span class="t2">[ الأنفال : 24 ]</span> '
        'قال: بلى.';

    test('keeps hadith dialogue in commentary and promotes only the ayah', () {
      final segments = TafsirTextParser.parse(raw, tafsirId: TafsirId.ibnKathir);

      final ayah = segments.firstWhere((s) => s.kind == TafsirSegmentKind.ayah);
      expect(
        ayah.text,
        '﴿استجيبوا لله وللرسول إذا دعاكم لما يحييكم﴾',
      );
      expect(ayah.text, isNot(contains('ما منعك')));
      expect(ayah.text, isNot(contains('كنت في الصلاة')));

      final hadithCommentary = segments.firstWhere(
        (s) =>
            s.kind == TafsirSegmentKind.commentary &&
            s.text.contains('ما منعك'),
      );
      expect(hadithCommentary.text, contains('أولست تجد'));
      expect(hadithCommentary.text, isNot(contains('استجيبوا')));
    });
  });
}
