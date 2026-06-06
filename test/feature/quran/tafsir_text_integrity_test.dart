import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/quran/domain/services/tafsir_text_integrity.dart';

void main() {
  group('TafsirTextIntegrity', () {
    test('returns not truncated for empty text', () {
      final report = TafsirTextIntegrity.analyze('');

      expect(report.isLikelyTruncated, isFalse);
      expect(report.reasons, isEmpty);
    });

    test('flags IK 1:1 orphan closing div and mid-word ending', () {
      const raw = '…بسم ا</div>';

      final report = TafsirTextIntegrity.analyze(raw);

      expect(report.isLikelyTruncated, isTrue);
      expect(
        report.reasons,
        containsAll([
          TafsirTruncationReason.orphanClosingDiv,
          TafsirTruncationReason.midWordEnding,
        ]),
      );
    });

    test('flags unclosed parenthesis at end (IK 1:4 pattern)', () {
      const raw =
          'نص طويل عن التفسير يذكر الحديث (رواه البخاري في صحيحه';

      final report = TafsirTextIntegrity.analyze(raw);

      expect(report.isLikelyTruncated, isTrue);
      expect(
        report.reasons,
        contains(TafsirTruncationReason.unbalancedDelimiters),
      );
    });

    test('flags orphan </div> without matching <div> open', () {
      const raw = 'تفسير كامل للآية.</div>';

      final report = TafsirTextIntegrity.analyze(raw);

      expect(report.isLikelyTruncated, isTrue);
      expect(
        report.reasons,
        contains(TafsirTruncationReason.orphanClosingDiv),
      );
    });

    test('does not flag balanced div markup', () {
      const raw = '<div>تفسير كامل.</div>';

      final report = TafsirTextIntegrity.analyze(raw);

      expect(report.isLikelyTruncated, isFalse);
    });

    test('does not flag complete commentary ending with punctuation', () {
      const raw =
          'هذا تفسير مكتمل يشرح معنى الآية بشكل وافٍ، '
          'ويختم بجملة سليمة.';

      final report = TafsirTextIntegrity.analyze(raw);

      expect(report.isLikelyTruncated, isFalse);
    });

    test('does not flag complete parenthetical citation', () {
      const raw = 'قال تعالى (الحمد لله رب العالمين) في بداية السورة.';

      final report = TafsirTextIntegrity.analyze(raw);

      expect(report.isLikelyTruncated, isFalse);
    });

    test('flags abrupt short tail after long content', () {
      final prefix = 'تفسير مطول. ' * 60;
      const tail = 'بسم ا';
      final raw = '$prefix$tail';

      final report = TafsirTextIntegrity.analyze(raw);

      expect(report.isLikelyTruncated, isTrue);
      expect(report.reasons, contains(TafsirTruncationReason.abruptTail));
    });

    test('flags unbalanced guillemets', () {
      const raw = 'ذكر القول «ما لم يعلم';

      final report = TafsirTextIntegrity.analyze(raw);

      expect(report.isLikelyTruncated, isTrue);
      expect(
        report.reasons,
        contains(TafsirTruncationReason.unbalancedDelimiters),
      );
    });

    test('flags unbalanced square brackets', () {
      const raw = 'انظر [11 - الإسراء';

      final report = TafsirTextIntegrity.analyze(raw);

      expect(report.isLikelyTruncated, isTrue);
      expect(
        report.reasons,
        contains(TafsirTruncationReason.unbalancedDelimiters),
      );
    });

    test('does not flag short complete entries', () {
      const raw = 'تفسير قصير.';

      final report = TafsirTextIntegrity.analyze(raw);

      expect(report.isLikelyTruncated, isFalse);
    });

    test('ignores HTML tags when checking delimiters', () {
      const raw =
          '<span class="t2">[ الحديث ]</span> '
          'نص مكتمل عن الآية.';

      final report = TafsirTextIntegrity.analyze(raw);

      expect(report.isLikelyTruncated, isFalse);
    });
  });
}
