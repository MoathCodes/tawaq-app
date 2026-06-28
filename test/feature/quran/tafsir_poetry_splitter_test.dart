import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/core/text/arabic_text_normalizer.dart';
import 'package:tawaq/feature/quran/domain/models/tafsir_models.dart';
import 'package:tawaq/feature/quran/domain/services/tafsir_poetry_splitter.dart';
import 'package:tawaq/feature/quran/domain/services/tafsir_text_parser.dart';

void main() {
  group('TafsirPoetrySplitter', () {
    List<TafsirTextSegment> expandFromRaw(String raw) {
      final text = ArabicTextNormalizer.normalize(raw.replaceAll('<br>', '\n'));
      return TafsirPoetrySplitter.expand([
        TafsirTextSegment(text: text, kind: TafsirSegmentKind.commentary),
      ]);
    }

    test('splits wide-gap lines into poetry segments', () {
      const commentary = TafsirTextSegment(
        text: 'مقدمة\n'
            "ya man alooz beh fima a'miluh     la yajbur al-nasa 'adhan anta kasirah\n"
            'khatima',
        kind: TafsirSegmentKind.commentary,
      );
      final expanded = TafsirPoetrySplitter.expand([commentary]);
      expect(expanded, hasLength(3));
      expect(expanded[1].kind, TafsirSegmentKind.poetry);
    });

    test('splits IK 1:2 br-separated poetry after qala al-shaair', () {
      const raw = 'يكون بالجنان واللسان والأركان ، كما قال الشاعر :<br>أفادتكم النعماء مني ثلاثة يدي ولساني والضمير المحجبا<br>';
      final segments = expandFromRaw(raw);
      expect(
        segments.any(
          (s) =>
              s.kind == TafsirSegmentKind.commentary &&
              s.text.contains('أفادتكم النع'),
        ),
        isTrue,
      );
    });

    test('merges cross-line second hemistich for ibn al-Mutazz bayt', () {
      const raw = 'كما قال ابن المعتز :<br>فيا عجبا كيف يعصى الإله أم كيف يجحده الجاحد     وفي كل شيء له آية<br>تدل على أنه واحد';
      final poetry = expandFromRaw(raw).where((s) => s.kind == TafsirSegmentKind.poetry);
      expect(poetry, hasLength(1));
      expect(poetry.first.text, contains('يعصى الإله'));
      expect(poetry.first.poetryHemistichs?.last, contains('تدل على أنه واحد'));
    });

    test('keeps parallel Mutanabbi hemistich on next line as separate commentary', () {
      const raw = 'كما قال المتنبي :<br>يا من ألوذ به فيما أؤمله ومن أعوذ به ممن أحاذره     لا يجبر الناس عظما أنت كاسره<br>ولا يهيضون عظما أنت جابره<br><br>fasl';
      final segments = expandFromRaw(raw);
      final poetry = segments.where((s) => s.kind == TafsirSegmentKind.poetry);
      expect(poetry, hasLength(1));
      expect(poetry.first.text, contains('ه فيما أؤمله'));
      expect(
        segments.any(
          (s) =>
              s.kind == TafsirSegmentKind.commentary &&
              s.text.contains('ولا يهيضون'),
        ),
        isTrue,
      );
    });

    test('splits Baghawi br-separated hemistichs after qala al-shaair', () {
      const raw = 'قال الشاعر<br>ألهت إليها والحوادث جمة<br>فكأن الخلق يسكنون إليه ويطمئنون بذكره و';
      final poetry = expandFromRaw(raw).where((s) => s.kind == TafsirSegmentKind.poetry);
      expect(poetry, hasLength(1));
      expect(poetry.first.text, contains('ألهت إليها'));
    });

    test('detects single-line bayt after dhi al-Rumma attribution', () {
      const raw = 'استشهد بقول ذي الرمة :<br>على رأسه أم لنا نقتدي بها جماع أمور ليس نعصي لها أمرا<br>';
      final segments = expandFromRaw(raw);
      expect(
        segments.any(
          (s) =>
              s.kind == TafsirSegmentKind.commentary &&
              s.text.contains('على رأسه أم '),
        ),
        isTrue,
      );
    });

    test('detects single-line bayt after umayya attribution', () {
      const raw = 'قال أمية بن أبي الصلت في ذكر ما أوتي سليمان ، عليه السلام :<br>أيما شاطن عصاه عكاه ثم يلقى في السجن والأغلال<br>';
      final segments = expandFromRaw(raw);
      expect(
        segments.any(
          (s) =>
              s.kind == TafsirSegmentKind.commentary &&
              s.text.contains('أيما شاطن عص'),
        ),
        isTrue,
      );
    });

    test('splits jarir br-separated hemistichs', () {
      const raw = 'قول جرير بن عطية الخطفي :<br>أمير المؤمنين على صراط<br>إذا اعوج الموارد مستقيم<br>';
      final poetry = expandFromRaw(raw).where((s) => s.kind == TafsirSegmentKind.poetry);
      expect(poetry, hasLength(1));
      expect(poetry.first.poetryHemistichs, hasLength(2));
    });

    test('end-to-end parser keeps poetry for wide-gap fixtures', () {
      const raw = 'كما قال المتنبي :<br>يا من ألوذ به فيما أؤمله ومن أعوذ به ممن أحاذره     لا يجبر الناس عظما أنت كاسره<br>ولا يهيضون عظما أنت جابره<br>';
      final poetry = TafsirTextParser.parse(raw).segments.where((s) => s.kind == TafsirSegmentKind.poetry);
      expect(poetry, isNotEmpty);
    });
  });
}
