import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/quran/domain/models/tafsir_models.dart';
import 'package:tawaq/feature/quran/domain/services/tafsir_text_normalizer.dart';
import 'package:tawaq/feature/quran/domain/services/tafsir_text_parser.dart';

void main() {
  group('Mouaser PUA ayah brackets', () {
    const mouaserOpen = '\uFD61';
    const mouaserClose = '\uFD60';

    test('formatAyahDisplay strips Mouaser font brackets', () {
      expect(
        TafsirTextNormalizer.formatAyahDisplay(
          '$mouaserOpen\u200aٱللَّهِ$mouaserClose',
        ),
        '﴿ٱللَّهِ﴾',
      );
    });

    test('parses Mouaser ayah spans without double brackets', () {
      const raw =
          '[1] أبتدئ قراءة القرآن باسم الله مستعيناً به، '
          "<span class='aya'>\uFD61\u200aٱللَّهِ\uFD60</span> "
          'علم على الرب';

      final segments = TafsirTextParser.parse(raw).segments;

      expect(segments, hasLength(3));
      expect(segments[1].kind, TafsirSegmentKind.ayah);
      expect(segments[1].text, '﴿ٱللَّهِ﴾');
      expect(segments[1].text, isNot(contains(mouaserOpen)));
      expect(segments[1].text, isNot(contains(mouaserClose)));
      expect(segments[1].text, isNot(contains('(')));
      expect(segments[1].text, isNot(contains(')')));
    });
  });
}
