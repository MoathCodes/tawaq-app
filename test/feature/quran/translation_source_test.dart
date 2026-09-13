import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/quran/domain/models/translation_source.dart';

void main() {
  test('every bundled translation carries a language tag and direction', () {
    final expected = <TranslationId, (String, TranslationDirection)>{
      TranslationId.saheehInternational: ('en', TranslationDirection.ltr),
      TranslationId.bengali: ('bn', TranslationDirection.ltr),
      TranslationId.spanish: ('es', TranslationDirection.ltr),
      TranslationId.french: ('fr', TranslationDirection.ltr),
      TranslationId.indonesian: ('id', TranslationDirection.ltr),
      TranslationId.russian: ('ru', TranslationDirection.ltr),
      TranslationId.swedish: ('sv', TranslationDirection.ltr),
      TranslationId.turkish: ('tr', TranslationDirection.ltr),
      TranslationId.urdu: ('ur', TranslationDirection.rtl),
      TranslationId.chinese: ('zh', TranslationDirection.ltr),
    };

    expect(TranslationId.values, hasLength(expected.length));
    for (final source in TranslationId.values) {
      expect((source.languageCode, source.direction), expected[source]);
    }
  });
}
