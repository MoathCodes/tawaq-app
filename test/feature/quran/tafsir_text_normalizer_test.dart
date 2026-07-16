import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/core/text/arabic_text_normalizer.dart';
import 'package:tawaq/feature/quran/domain/services/tafsir_text_normalizer.dart';

void main() {
  group('ArabicTextNormalizer (tafsir)', () {
    test('collapses spaced prefix particles before qawl leads', () {
      expect(
        ArabicTextNormalizer.normalize('ل قوله تعالى:'),
        'لقوله تعالى:',
      );
      expect(
        ArabicTextNormalizer.normalize('و قوله:'),
        'وقوله:',
      );
    });

    test('removes spaces before Arabic punctuation', () {
      expect(
        ArabicTextNormalizer.normalize('خطا ، وبها تفتح الصلاة ، أيضا :'),
        'خطا، وبها تفتح الصلاة، أيضا:',
      );
    });

    test('trims spaces inside parentheses and brackets', () {
      expect(
        ArabicTextNormalizer.normalize('( بسم الله الرحمن الرحيم )'),
        '(بسم الله الرحمن الرحيم)',
      );
      expect(
        ArabicTextNormalizer.normalize('[ الحديث ]'),
        '[الحديث]',
      );
      expect(
        ArabicTextNormalizer.normalize('{الحمد لله}'),
        '{الحمد لله}',
      );
      expect(
        ArabicTextNormalizer.normalize('{ الحمد لله }'),
        '{الحمد لله}',
      );
    });

    test('tightens verse reference colons', () {
      expect(
        ArabicTextNormalizer.normalize('[ الحجر : 87 ]'),
        '[الحجر: 87]',
      );
    });

    test('collapses redundant question mark and period', () {
      expect(
        ArabicTextNormalizer.normalize('وما يدريك أنها رقية ؟ .'),
        'وما يدريك أنها رقية؟',
      );
    });

    test('replaces sallallahu alayhi wasallam with ligature', () {
      expect(
        ArabicTextNormalizer.normalize('قال رسول الله صلى الله عليه وسلم'),
        'قال رسول الله ﷺ',
      );
    });

    test('replaces padded straight quotes with guillemets', () {
      expect(
        ArabicTextNormalizer.normalize('" بسم الله الرحمن الرحيم "'),
        '«بسم الله الرحمن الرحيم»',
      );
      expect(
        ArabicTextNormalizer.normalize('" ، ويمد "'),
        '«، ويمد»',
      );
    });

    test('removes stray punctuation after opening bracket', () {
      expect(
        ArabicTextNormalizer.normalize('[ . وقال وكيع عن الأعمش ]'),
        '[وقال وكيع عن الأعمش]',
      );
    });

    test('tightens verse-to-citation sequences', () {
      expect(
        ArabicTextNormalizer.normalize('( ... غرورا ) [ الأنعام : 112 ] .'),
        '(... غرورا)[الأنعام: 112].',
      );
    });

    test('strips orphan leading punctuation at segment boundaries', () {
      expect(
        ArabicTextNormalizer.normalize('.وهذا الذي ادعاه'),
        'وهذا الذي ادعاه',
      );
      expect(ArabicTextNormalizer.normalize('.'), '');
      expect(ArabicTextNormalizer.normalize('. '), '');
      expect(
        ArabicTextNormalizer.normalize(' يقال لها'),
        'يقال لها',
      );
      expect(
        ArabicTextNormalizer.normalize('\n يقال لها'),
        '\n يقال لها',
      );
      expect(
        ArabicTextNormalizer.normalize('، وقد قيل'),
        'وقد قيل',
      );
    });

    test('removes stray quote before closing reference bracket', () {
      expect(
        ArabicTextNormalizer.normalize('[ وضلوا عن سواء السبيل " ]'),
        '[وضلوا عن سواء السبيل]',
      );
    });

    test('converts latin commas to arabic commas', () {
      expect(
        ArabicTextNormalizer.normalize('أي: أبتدئ بكل اسم لله تعالى, لأن'),
        'أي: أبتدئ بكل اسم لله تعالى، لأن',
      );
    });

    test('preserves line breaks after colon from br markup', () {
      expect(
        ArabicTextNormalizer.normalize('كما قال الشاعر :\nأفادتكم النعماء'),
        'كما قال الشاعر:\nأفادتكم النعماء',
      );
    });

    test('normalizes honorific spacing and glued sahih muslim typo', () {
      expect(
        ArabicTextNormalizer.normalize('عن أبي هريرة رضي  الله  عنه'),
        'عن أبي هريرة رضي الله عنه',
      );
      expect(
        ArabicTextNormalizer.normalize('قال الإمام رحمه  الله'),
        'قال الإمام رحمه الله',
      );
      expect(
        ArabicTextNormalizer.normalize('عيسى عليه  السلام'),
        'عيسى عليه السلام',
      );
      expect(
        ArabicTextNormalizer.normalize('رواه صحيحمسلم عن أبي موسى'),
        'رواه صحيح مسلم عن أبي موسى',
      );
    });
  });

  group('TafsirTextNormalizer', () {
    test('wraps ayah text in Uthmani brackets', () {
      expect(
        TafsirTextNormalizer.formatAyahDisplay('{الحمد لله}'),
        '﴿الحمد لله﴾',
      );
      expect(
        TafsirTextNormalizer.formatAyahDisplay('( بسم الله )'),
        '﴿بسم الله﴾',
      );
      expect(
        TafsirTextNormalizer.formatAyahDisplay('﴿already wrapped﴾'),
        '﴿already wrapped﴾',
      );
      expect(
        TafsirTextNormalizer.formatAyahDisplay(
          '${TafsirTextNormalizer.mouaserAyahOpen}ٱللَّهِ${TafsirTextNormalizer.mouaserAyahClose}',
        ),
        '﴿ٱللَّهِ﴾',
      );
    });
  });
}
