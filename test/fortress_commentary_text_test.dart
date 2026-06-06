import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/muslim_fortress/domain/services/fortress_commentary_parser.dart';

void main() {
  group('FortressCommentaryParser', () {
    test('splits numbered items and extracts citations', () {
      const raw = '''
شرح مفردات الحديث:
1- قوله: «أصبحنا» أي دخلنا /55 تحفة الأحوذي، 9/ 236 /55 .
7- قوله: «وله الحمد»: أي الحمد المطلق.
8- قوله: «وهو على كل شيء قدير»: قال ابن جرير : «تفسير» /55 تفسير الطبري، 15/ 232 /55 .
''';

      final blocks = FortressCommentaryParser.parse(raw);

      expect(blocks, hasLength(4));
      expect(blocks[0].listNumber, isNull);
      expect(blocks[0].body, contains('شرح مفردات الحديث'));
      expect(blocks[0].citations, isEmpty);

      expect(blocks[1].listNumber, 1);
      expect(blocks[1].body, isNot(contains('/55')));
      expect(blocks[1].citations, ['تحفة الأحوذي، 9/ 236']);

      expect(blocks[2].listNumber, 7);
      expect(blocks[2].citations, isEmpty);

      expect(blocks[3].listNumber, 8);
      expect(blocks[3].citations, ['تفسير الطبري، 15/ 232']);
      expect(blocks[3].body, contains('قال ابن جرير'));
    });

    test('returns empty list for blank input', () {
      expect(FortressCommentaryParser.parse('   '), isEmpty);
    });

    test('keeps surah reference in body for inline verse styling', () {
      const raw = '''
4- قوله: «text» ﴿إِنَّ إِلَىٰ رَبِّكَ الرُّجْعَىٰ﴾ سورة العلق، الآية: 8 .
''';

      final blocks = FortressCommentaryParser.parse(raw);

      expect(blocks, hasLength(1));
      expect(blocks.single.body, contains('سورة العلق، الآية: 8'));
      expect(blocks.single.body, contains('﴿إِنَّ إِلَىٰ رَبِّكَ الرُّجْعَىٰ﴾'));
    });
  });
}
