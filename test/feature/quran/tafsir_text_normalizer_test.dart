import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/quran/domain/services/tafsir_text_normalizer.dart';

void main() {
  group('TafsirTextNormalizer', () {
    test('collapses spaced prefix particles before qawl leads', () {
      expect(
        TafsirTextNormalizer.normalize('ل قوله تعالى:'),
        'لقوله تعالى:',
      );
      expect(
        TafsirTextNormalizer.normalize('و قوله:'),
        'وقوله:',
      );
    });

    test('removes spaces before Arabic punctuation', () {
      expect(
        TafsirTextNormalizer.normalize('خطا ، وبها تفتح الصلاة ، أيضا :'),
        'خطا، وبها تفتح الصلاة، أيضا:',
      );
    });

    test('trims spaces inside parentheses and brackets', () {
      expect(
        TafsirTextNormalizer.normalize('( بسم الله الرحمن الرحيم )'),
        '(بسم الله الرحمن الرحيم)',
      );
      expect(
        TafsirTextNormalizer.normalize('[ الحديث ]'),
        '[الحديث]',
      );
      expect(
        TafsirTextNormalizer.normalize('{الحمد لله}'),
        '{الحمد لله}',
      );
      expect(
        TafsirTextNormalizer.normalize('{ الحمد لله }'),
        '{الحمد لله}',
      );
    });

    test('tightens verse reference colons', () {
      expect(
        TafsirTextNormalizer.normalize('[ الحجر : 87 ]'),
        '[الحجر: 87]',
      );
    });

    test('collapses redundant question mark and period', () {
      expect(
        TafsirTextNormalizer.normalize('وما يدريك أنها رقية ؟ .'),
        'وما يدريك أنها رقية؟',
      );
    });

    test('replaces sallallahu alayhi wasallam with ligature', () {
      expect(
        TafsirTextNormalizer.normalize('قال رسول الله صلى الله عليه وسلم'),
        'قال رسول الله ﷺ',
      );
    });

    test('replaces padded straight quotes with guillemets', () {
      expect(
        TafsirTextNormalizer.normalize('" بسم الله الرحمن الرحيم "'),
        '«بسم الله الرحمن الرحيم»',
      );
      expect(
        TafsirTextNormalizer.normalize('" ، ويمد "'),
        '«، ويمد»',
      );
    });

    test('removes stray punctuation after opening bracket', () {
      expect(
        TafsirTextNormalizer.normalize('[ . وقال وكيع عن الأعمش ]'),
        '[وقال وكيع عن الأعمش]',
      );
    });

    test('tightens verse-to-citation sequences', () {
      expect(
        TafsirTextNormalizer.normalize('( ... غرورا ) [ الأنعام : 112 ] .'),
        '(... غرورا)[الأنعام: 112].',
      );
    });

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
    });

    test('strips orphan leading punctuation at segment boundaries', () {
      expect(
        TafsirTextNormalizer.normalize('.وهذا الذي ادعاه'),
        'وهذا الذي ادعاه',
      );
      expect(TafsirTextNormalizer.normalize('.'), '');
      expect(TafsirTextNormalizer.normalize('. '), '');
      expect(
        TafsirTextNormalizer.normalize(' يقال لها'),
        'يقال لها',
      );
      expect(
        TafsirTextNormalizer.normalize('\n يقال لها'),
        '\n يقال لها',
      );
      expect(
        TafsirTextNormalizer.normalize('، وقد قيل'),
        'وقد قيل',
      );
    });

    test('removes stray quote before closing reference bracket', () {
      expect(
        TafsirTextNormalizer.normalize('[ وضلوا عن سواء السبيل " ]'),
        '[وضلوا عن سواء السبيل]',
      );
    });

    test('converts latin commas to arabic commas', () {
      expect(
        TafsirTextNormalizer.normalize('أي: أبتدئ بكل اسم لله تعالى, لأن'),
        'أي: أبتدئ بكل اسم لله تعالى، لأن',
      );
    });

    test('preserves line breaks after colon from br markup', () {
      expect(
        TafsirTextNormalizer.normalize('كما قال الشاعر :\nأفادتكم النعماء'),
        'كما قال الشاعر:\nأفادتكم النعماء',
      );
    });

    test('normalizes honorific spacing and glued sahih muslim typo', () {
      expect(
        TafsirTextNormalizer.normalize('عن أبي هريرة رضي  الله  عنه'),
        'عن أبي هريرة رضي الله عنه',
      );
      expect(
        TafsirTextNormalizer.normalize('قال الإمام رحمه  الله'),
        'قال الإمام رحمه الله',
      );
      expect(
        TafsirTextNormalizer.normalize('عيسى عليه  السلام'),
        'عيسى عليه السلام',
      );
      expect(
        TafsirTextNormalizer.normalize('رواه صحيحمسلم عن أبي موسى'),
        'رواه صحيح مسلم عن أبي موسى',
      );
    });
  });
}
