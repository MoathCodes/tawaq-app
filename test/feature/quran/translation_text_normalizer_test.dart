import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/quran/domain/services/translation_text_normalizer.dart';

void main() {
  group('TranslationTextNormalizer', () {
    test('repairs three-digit corrupted entities', () {
      const input = 'দারিদ্রে?480; আশংকা';
      expect(
        TranslationTextNormalizer.normalize(input),
        'দারিদ্রের আশংকা',
      );
    });

    test('repairs four-digit corrupted entities', () {
      const input = 'সামর্থ?2470;িয়েছেন';
      expect(
        TranslationTextNormalizer.normalize(input),
        'সামর্থদিয়েছেন',
      );
    });

    test('repairs hash-prefixed corrupted entities', () {
      const input = 'চিহিߦ#2468; ঘোড়ার';
      expect(
        TranslationTextNormalizer.normalize(input),
        'চিহিত ঘোড়ার',
      );
    });

    test('repairs known 451 override to yophola', () {
      const input = 'তারা এর সামর্থ?451; রাখে না';
      expect(
        TranslationTextNormalizer.normalize(input),
        'তারা এর সামর্থ্য রাখে না',
      );
    });

    test('leaves clean text unchanged', () {
      const input = 'তারা কি চিন্তা কর না?';
      expect(TranslationTextNormalizer.normalize(input), input);
    });
  });
}
