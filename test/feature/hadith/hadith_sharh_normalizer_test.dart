import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/hadith/domain/services/hadith_sharh_normalizer.dart';

void main() {
  group('HadithSharhNormalizer', () {
    test('preserves ASCII pedagogical quotes through normalization', () {
      const input = 'قال "السلام" أي: التحية';
      final normalized = HadithSharhNormalizer.normalize(input);

      expect(normalized, contains('"السلام"'));
      expect(normalized, isNot(contains('<<<SHQ')));
    });

    test('strips pipe and slash artifacts', () {
      const input = 'نص |  آخر // زائد / بين';
      final normalized = HadithSharhNormalizer.normalize(input);

      expect(normalized, 'نص آخر زائد بين');
    });

    test('masks multiple quotes independently', () {
      const input = '"أ" و "ب"';
      final normalized = HadithSharhNormalizer.normalize(input);

      expect(normalized, contains('"أ"'));
      expect(normalized, contains('"ب"'));
    });
  });
}
