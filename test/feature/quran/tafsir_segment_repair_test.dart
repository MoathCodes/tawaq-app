import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/quran/domain/models/tafsir_source.dart';
import 'package:tawaq/feature/quran/domain/models/tafsir_models.dart';
import 'package:tawaq/feature/quran/domain/services/tafsir_segment_repair.dart';
import 'package:tawaq/feature/quran/domain/services/tafsir_text_parser.dart';

void main() {
  group('TafsirSegmentRepair', () {
    test('detects surah-name cross references', () {
      expect(
        TafsirSegmentRepair.isSurahCrossReference('( سورة النحل ، 98 )'),
        isTrue,
      );
      expect(
        TafsirSegmentRepair.isSurahCrossReference('(بسم الله الرحمن الرحيم)'),
        isFalse,
      );
    });

    test('splits unclosed ayah quote before reference segment', () {
      const raw =
          'أي: إذا أردت القراءة كقوله: ( إذا قمتم إلى الصلاة فاغسلوا وجوهكم '
          'وأيديكم الآية '
          '<span class="t2">[ المائدة : 6 ]</span>';

      final segments = TafsirTextParser.parse(raw).segments;

      expect(
        segments.map((s) => s.kind).toList(),
        contains(TafsirSegmentKind.ayah),
      );
      final ayah = segments.firstWhere((s) => s.kind == TafsirSegmentKind.ayah);
      expect(ayah.text, contains('الصلاة'));
      expect(
        segments.any((s) => s.kind == TafsirSegmentKind.reference),
        isTrue,
      );
    });

    test('promotes IK 1:5 orphan close-paren ayah before reference', () {
      const raw =
          'كما قال تعالى: '
          '<span class="t3">( فاعبده وتوكل عليه وما ربك بغافل عما تعملون )</span> '
          '<span class="t2">[ هود : 123 ]</span> '
          'قل هو الرحمن آمنا به وعليه توكلنا ) '
          '<span class="t2">[ الملك : 29 ]</span>';

      final segments = TafsirTextParser.parse(raw).segments;
      final ayahBeforeRef = _ayahBeforeReference(segments, '[الملك: 29]');

      expect(ayahBeforeRef, isNotNull);
      expect(ayahBeforeRef!.text, contains('توكلنا'));
    });

    test('promotes bare ayah text before IK الكهف reference', () {
      const raw =
          'قال الله تعالى : المال والبنون زينة الحياة الدنيا والباقيات الصالحات '
          'خير عند ربك ثوابا وخير أملا '
          '<span class="t2">[ الكهف : 46 ]</span>';

      final segments = TafsirTextParser.parse(raw).segments;
      final ayahBeforeRef = _ayahBeforeReference(segments, '[الكهف: 46]');

      expect(ayahBeforeRef, isNotNull);
      expect(ayahBeforeRef!.text, contains('المال والبنون'));
    });

    test('promotes unclosed open-paren ayah before t2 reference', () {
      const raw =
          'وقال : ( ويوم يقول كن فيكون ، '
          '<span class="t2">[ الأنعام : 73 ]</span>';

      final segments = TafsirTextParser.parse(raw).segments;
      final ayahBeforeRef = _ayahBeforeReference(segments, '[الأنعام: 73]');

      expect(ayahBeforeRef, isNotNull);
      expect(ayahBeforeRef!.text, contains('كن فيكون'));
    });

    test('anchors unclosed الآية repair to last open paren with length guard', () {
      const prefix = 'مقدمة طويلة ( افتتاح ';
      const longHadith = '( حمدني عبدي ، وإذا قال : ( الرحمن الرحيم )';
      const ayahTail =
          '( يا أيها الذين آمنوا آمنوا بالله ورسوله والكتاب الذي نزل '
          'على رسوله والكتاب الذي أنزل من قبل الآية ';
      const raw =
          '$prefix$longHadith$ayahTail'
          '<span class="t2">[ النساء : 136 ]</span>';

      final segments = TafsirTextParser.parse(raw).segments;
      final ayahBeforeRef = _ayahBeforeReference(segments, '[النساء: 136]');

      expect(ayahBeforeRef, isNotNull);
      expect(ayahBeforeRef!.text.length, lessThan(250));
      expect(ayahBeforeRef.text, contains('يا أيها الذين آمنوا'));
      expect(ayahBeforeRef.text, isNot(contains('حمدني عبدي')));
    });

    test('promotes cross-br orphan close-paren before reference (IK 1:7)', () {
      const raw =
          'قال : <span class="t3">( غير المغضوب عليهم )</span> '
          'اليهود ، ولا الضالين ) '
          '<span class="t2">[ الفاتحة : 7 ]</span>';

      final segments = TafsirTextParser.parse(raw).segments;
      final ayahBeforeRef = _ayahBeforeReference(segments, '[الفاتحة: 7]');

      expect(ayahBeforeRef, isNotNull);
      expect(ayahBeforeRef!.text, contains('الضالين'));
    });

    test('promotes chained bare ayah quotes in IK 1:4 editorial t2', () {
      const raw =
          '<span class="t2">'
          '[ … ورجح الزمخشري '
          '<span class="t1">" ملك "</span>'
          '؛ لأنها قراءة أهل الحرمين ولقوله: (لمن الملك اليوم وقوله: '
          '(قوله الحق وله الملك وحكي عن أبي حنيفة … غريب جدا ]'
          '</span>';

      final segments = TafsirTextParser.parse(raw, tafsirId: TafsirId.ibnKathir).segments;
      final ayahs = segments
          .where((s) => s.kind == TafsirSegmentKind.ayah)
          .map((s) => s.text)
          .toList();

      expect(ayahs, contains('﴿لمن الملك اليوم﴾'));
      expect(ayahs, contains('﴿قوله الحق وله الملك﴾'));
    });

    test('splits hadith dialogue from embedded ayah before reference (IK 1:1)', () {
      const raw =
          'حديث '
          '<span class="t2">[ قال ]</span> '
          ': ما منعك أي أبي إذ دعوتك أن تجيبني ۞ قال: أي رسول الله ۞ كنت في الصلاة ۞ '
          'قال: أولست تجد فيما أوحى الله إلي استجيبوا لله وللرسول إذا دعاكم لما يحييكم ) '
          '<span class="t2">[ الأنفال : 24 ]</span>';

      final segments = TafsirTextParser.parse(raw, tafsirId: TafsirId.ibnKathir).segments;
      final ayahBeforeRef = _ayahBeforeReference(segments, '[الأنفال: 24]');

      expect(ayahBeforeRef, isNotNull);
      expect(ayahBeforeRef!.text, contains('استجيبوا لله'));
      expect(ayahBeforeRef.text, isNot(contains('ما منعك')));
    });
  });

  group('TafsirTextParser surah cross refs', () {
    test('classifies ( سورة النحل ، 98 ) as cross-reference', () {
      const raw = '<span class="t3">( سورة النحل ، 98 )</span>';

      final segments = TafsirTextParser.parse(raw).segments;

      expect(segments.single.kind, TafsirSegmentKind.crossReference);
    });
  });
}

TafsirTextSegment? _ayahBeforeReference(
  List<TafsirTextSegment> segments,
  String referenceNeedle,
) {
  for (var i = 0; i < segments.length - 1; i++) {
    if (segments[i].kind == TafsirSegmentKind.ayah &&
        segments[i + 1].kind == TafsirSegmentKind.reference &&
        segments[i + 1].text.replaceAll(' ', '').contains(
              referenceNeedle.replaceAll(' ', ''),
            )) {
      return segments[i];
    }
  }
  return null;
}
