import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/quran/domain/models/tafsir_source.dart';
import 'package:tawaq/feature/quran/domain/models/tafsir_text_segment.dart';
import 'package:tawaq/feature/quran/domain/services/tafsir_span_classifier.dart';
import 'package:tawaq/feature/quran/domain/services/tafsir_text_parser.dart';

void main() {
  group('TafsirSpanClassifier t3 heuristics', () {
    test('classifies unclosed partial verse prefix as commentary', () {
      final segments = TafsirSpanClassifier.classifySpan(
        cssClass: 't3',
        content: '( الرحمن الرحيم ',
        tafsirId: TafsirId.ibnKathir,
      );

      expect(segments.single.kind, TafsirSegmentKind.commentary);
    });

    test('classifies IK editorial ( قلt ) as commentary', () {
      final segments = TafsirTextParser.parse(
        '<span class="t3">( قلt )</span>',
        tafsirId: TafsirId.ibnKathir,
      ).segments;

      expect(segments, hasLength(1));
      expect(segments.single.kind, TafsirSegmentKind.commentary);
      expect(segments.single.text, '(قلt)');
    });

    test('classifies IK editorial ( مسألة ) as commentary', () {
      final segments = TafsirTextParser.parse(
        'نص <span class="t3">( مسألة )</span> باقي',
        tafsirId: TafsirId.ibnKathir,
      ).segments;

      expect(segments[1].kind, TafsirSegmentKind.commentary);
      expect(segments[1].text, '(مسألة)');
    });

    test('classifies Baghawi editorial ( قال ) as commentary', () {
      final segments = TafsirTextParser.parse(
        '<span class="t3">( قال )</span>',
        tafsirId: TafsirId.baghawi,
      ).segments;

      expect(segments.single.kind, TafsirSegmentKind.commentary);
    });

    test('classifies partial verse fragment as commentary', () {
      final segments = TafsirTextParser.parse(
        '<span class="t3">( الرحمن الرحيم )</span>',
        tafsirId: TafsirId.ibnKathir,
      ).segments;

      expect(segments.single.kind, TafsirSegmentKind.commentary);
    });

    test('keeps t3 surah cross-reference separate from ayah', () {
      final segments = TafsirTextParser.parse(
        '<span class="t3">( 1 - العلق )</span>',
        tafsirId: TafsirId.ibnKathir,
      ).segments;

      expect(segments.single.kind, TafsirSegmentKind.crossReference);
    });

    test('splits mega-t3 span at first balanced paren with prose pivot', () {
      const raw =
          '<span class="t3">( اقرأ باسم ربك ) وفي هذا قال ابن عباس...</span>';

      final segments = TafsirTextParser.parse(
        raw,
        tafsirId: TafsirId.ibnKathir,
      ).segments;

      expect(segments, hasLength(2));
      expect(segments[0].kind, TafsirSegmentKind.ayah);
      expect(segments[0].text, '﴿اقرأ باسم ربك﴾');
      expect(segments[1].kind, TafsirSegmentKind.commentary);
      expect(segments[1].text, contains('وفي هذا'));
    });

    test('classifies composite t3 with كما في حديث as commentary', () {
      final segments = TafsirTextParser.parse(
        '<span class="t3">( نص ) كما في حديث النبي</span>',
        tafsirId: TafsirId.ibnKathir,
      ).segments;

      expect(segments, hasLength(2));
      expect(segments[0].kind, TafsirSegmentKind.ayah);
      expect(segments[1].kind, TafsirSegmentKind.commentary);
    });
  });

  group('TafsirSpanClassifier t2 source-aware', () {
    test("classifies As-Sa'di gloss [الحسنى] as gloss not reference", () {
      final segments = TafsirTextParser.parse(
        'نص <span class="t2">[الحسنى]</span> باقي',
        tafsirId: TafsirId.asSadi,
      ).segments;

      expect(segments[1].kind, TafsirSegmentKind.gloss);
      expect(segments[1].text, '[الحسنى]');
    });

    test('classifies IK editorial [قال] as commentary', () {
      final segments = TafsirTextParser.parse(
        '<span class="t2">[قال]</span>',
        tafsirId: TafsirId.ibnKathir,
      ).segments;

      expect(segments.single.kind, TafsirSegmentKind.commentary);
    });

    test('classifies IK editorial [ فقال ] as commentary', () {
      final segments = TafsirTextParser.parse(
        '<span class="t2">[ فقال ]</span>',
        tafsirId: TafsirId.ibnKathir,
      ).segments;

      expect(segments.single.kind, TafsirSegmentKind.commentary);
    });

    test('keeps surah citation [الفاتحة: 5] as reference', () {
      final segments = TafsirTextParser.parse(
        '<span class="t2">[الفاتحة: 5]</span>',
        tafsirId: TafsirId.asSadi,
      ).segments;

      expect(segments.single.kind, TafsirSegmentKind.reference);
    });

    test('keeps numeric surah citation [11 - الإسراء] as reference', () {
      final segments = TafsirTextParser.parse(
        '<span class="t2">[11 - الإسراء]</span>',
        tafsirId: TafsirId.ibnKathir,
      ).segments;

      expect(segments.single.kind, TafsirSegmentKind.reference);
    });

    test('classifies long t2 prose as commentary', () {
      final longText = '[${'أ' * 90}]';

      final segments = TafsirSpanClassifier.classifySpan(
        cssClass: 't2',
        content: longText,
        tafsirId: TafsirId.ibnKathir,
      );

      expect(segments.single.kind, TafsirSegmentKind.commentary);
    });

    test('classifies mid-word emphasis [ الله ] as gloss', () {
      final segments = TafsirTextParser.parse(
        '<span class="t2">[ الله ]</span>',
        tafsirId: TafsirId.ibnKathir,
      ).segments;

      expect(segments.single.kind, TafsirSegmentKind.gloss);
    });
  });
}
