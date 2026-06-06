import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/quran/domain/models/tafsir_text_segment.dart';
import 'package:tawaq/feature/quran/domain/services/tafsir_text_parser.dart';

void main() {
  group('TafsirTextParser', () {
    test('parses Mouaser ayah spans into segments', () {
      const raw =
          'Commentary before '
          '<span class="aya">﴿بِسْمِ اللَّهِ﴾</span> '
          'commentary after';

      final segments = TafsirTextParser.parse(raw);

      expect(segments, hasLength(3));
      expect(segments[0].kind, TafsirSegmentKind.commentary);
      expect(segments[0].text, 'Commentary before');
      expect(segments[1].kind, TafsirSegmentKind.ayah);
      expect(segments[1].text, '﴿بِسْمِ اللَّهِ﴾');
      expect(segments[2].kind, TafsirSegmentKind.commentary);
      expect(segments[2].text, 'commentary after');
    });

    test('parses compact t3 ayah and t1 qiraat quote', () {
      const raw =
          '<span class="t3">( اقرأ باسم ربك الذي خلق )</span> '
          'تفسير '
          '<span class="t1">" ما لم يعلم "</span>';

      final segments = TafsirTextParser.parse(raw);

      expect(segments, hasLength(3));
      expect(segments[0].kind, TafsirSegmentKind.ayah);
      expect(segments[0].text, '﴿اقرأ باسم ربك الذي خلق﴾');
      expect(segments[1].kind, TafsirSegmentKind.commentary);
      expect(segments[2].kind, TafsirSegmentKind.qiraatQuote);
      expect(segments[2].text, '«ما لم يعلم»');
    });

    test('classifies t3 surah cross-reference separately from ayah text', () {
      const raw =
          'نص '
          '<span class="t3">( 1 - العلق )</span> '
          'باقي';

      final segments = TafsirTextParser.parse(raw);

      expect(segments[1].kind, TafsirSegmentKind.crossReference);
      expect(segments[1].text, '(1 - العلق)');
    });

    test('parses t4 ayah citations and t2 references', () {
      const raw =
          'قوله: <span class="t4">{الحمد لله}</span> '
          'و<span class="t2">[11 - الإسراء]</span>';

      final segments = TafsirTextParser.parse(raw);

      expect(segments, hasLength(4));
      expect(segments[0].kind, TafsirSegmentKind.commentary);
      expect(segments[1].kind, TafsirSegmentKind.ayah);
      expect(segments[1].text, '﴿الحمد لله﴾');
      expect(segments[2].kind, TafsirSegmentKind.commentary);
      expect(segments[3].kind, TafsirSegmentKind.reference);
      expect(segments[3].text, '[11 - الإسراء]');
    });

    test('converts br tags to line breaks in commentary', () {
      const raw = 'سطر أول<br>سطر ثان';

      final segments = TafsirTextParser.parse(raw);

      expect(segments.single.kind, TafsirSegmentKind.commentary);
      expect(segments.single.text, 'سطر أول\nسطر ثان');
    });

    test('strips orphan div closers and residual html tags', () {
      const raw =
          'نص</div> '
          '<span class="t2">[ الحديث ]</span>';

      final segments = TafsirTextParser.parse(raw);

      expect(segments[0].text, 'نص');
      expect(segments[1].kind, TafsirSegmentKind.reference);
    });

    test('returns commentary-only segment when no spans exist', () {
      const raw = 'Plain tafsir text';

      final segments = TafsirTextParser.parse(raw);

      expect(segments, hasLength(1));
      expect(segments.single.kind, TafsirSegmentKind.commentary);
      expect(segments.single.text, raw);
    });

    test('inserts gap after br when commentary follows ayah span', () {
      const raw =
          '<span class="t3">( بسم الله )</span><br>يقال لها';

      final segments = TafsirTextParser.parse(raw);

      expect(segments, hasLength(2));
      expect(segments[1].text, '\nيقال لها');
    });

    test('preserves inter-span spacing from source markup', () {
      const raw =
          '<span class="t3">( verse )</span> يقال';

      final segments = TafsirTextParser.parse(raw);

      expect(segments[1].text, 'يقال');
    });

    group('nested spans', () {
      test('IK 1:1 — t3 wrapping t2 inside prayer-hadith', () {
        const raw =
            '<span class="t3">'
            '( الرحمن الرحيم '
            '<span class="t2">[ الفاتحة : 3 ]</span>'
            ' ، قال الله … ( مالك يوم الدين )'
            '</span>';

        final segments = TafsirTextParser.parse(raw);

        expect(segments, hasLength(3));
        expect(segments[0].kind, TafsirSegmentKind.commentary);
        expect(segments[0].text, '(الرحمن الرحيم');
        expect(segments[1].kind, TafsirSegmentKind.reference);
        expect(segments[1].text, '[الفاتحة: 3]');
        expect(segments[2].kind, TafsirSegmentKind.commentary);
        expect(segments[2].text, contains('مالك يوم الدين'));
      });

      test('IK 1:4 — t2 wrapping t1 qiraat quote', () {
        const raw =
            '<span class="t2">'
            '[ … ورجح الزمخshari '
            '<span class="t1">" ملك "</span>'
            ' … ]'
            '</span>';

        final segments = TafsirTextParser.parse(raw);

        expect(segments, hasLength(3));
        expect(segments[0].kind, TafsirSegmentKind.reference);
        expect(segments[0].text, '[… ورجح الزمخshari ');
        expect(segments[1].kind, TafsirSegmentKind.qiraatQuote);
        expect(segments[1].text, '«ملك»');
        expect(segments[2].kind, TafsirSegmentKind.reference);
        expect(segments[2].text, '…]');
      });

      test('IK 1:6 — t2 wrapping t3 ayah citation', () {
        const raw =
            '<span class="t2">'
            '[ … بقوله : '
            '<span class="t3">( اهدنا الصراط المستقيم )</span>'
            ' … ]'
            '</span>';

        final segments = TafsirTextParser.parse(raw);

        expect(segments, hasLength(3));
        expect(segments[0].kind, TafsirSegmentKind.reference);
        expect(segments[1].kind, TafsirSegmentKind.ayah);
        expect(segments[1].text, '﴿اهدنا الصراط المستقيم﴾');
        expect(segments[2].kind, TafsirSegmentKind.reference);
      });

      test('IK 1:7 — t2 wrapping t3 qiraat note', () {
        const raw =
            '<span class="t2">'
            '[ قراءة بلا ألف : '
            '<span class="t3">( اهدنا الصراط )</span>'
            ' ]'
            '</span>';

        final segments = TafsirTextParser.parse(raw);

        expect(segments, hasLength(3));
        expect(segments[0].kind, TafsirSegmentKind.reference);
        expect(segments[1].kind, TafsirSegmentKind.ayah);
        expect(segments[1].text, '﴿اهدنا الصراط﴾');
        expect(segments[2].kind, TafsirSegmentKind.reference);
      });

      test('Baghawi 1:1 — t1 wrapping t3 cross-reference', () {
        const raw =
            '<span class="t1">'
            '" '
            '<span class="t3">( 1 - الأعلى )</span>'
            ' ، وتبارك اسم ربك '
            '"'
            '</span>';

        final segments = TafsirTextParser.parse(raw);

        expect(segments, hasLength(3));
        expect(segments[0].kind, TafsirSegmentKind.qiraatQuote);
        expect(segments[0].text, '" ');
        expect(segments[1].kind, TafsirSegmentKind.crossReference);
        expect(segments[1].text, '(1 - الأعلى)');
        expect(segments[2].kind, TafsirSegmentKind.qiraatQuote);
        expect(segments[2].text, 'وتبارك اسم ربك "');
      });

      test('non-nested spans remain unchanged', () {
        const raw =
            'before '
            '<span class="aya">﴿text﴾</span> '
            '<span class="t2">[ref]</span> '
            'after';

        final segments = TafsirTextParser.parse(raw);

        expect(segments, hasLength(4));
        expect(segments[0].kind, TafsirSegmentKind.commentary);
        expect(segments[1].kind, TafsirSegmentKind.ayah);
        expect(segments[2].kind, TafsirSegmentKind.reference);
        expect(segments[3].kind, TafsirSegmentKind.commentary);
      });
    });
  });
}
