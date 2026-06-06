import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/quran/domain/models/tafsir_source.dart';
import 'package:tawaq/feature/quran/domain/models/tafsir_text_segment.dart';
import 'package:tawaq/feature/quran/domain/services/tafsir_text_integrity.dart';
import 'package:tawaq/feature/quran/domain/services/tafsir_text_parser.dart';

void main() {
  late String raw;

  setUpAll(() {
    final result = Process.runSync('sqlite3', [
      'assets/database/tafseer_ar/Quraan_IK.db',
      'SELECT Tafsir FROM IK WHERE SURA_num=1 AND AYA_num=4;',
    ]);
    raw = (result.stdout as String).trim();
  });

  group('IK 1:4 Zamakhshari passage', () {
    test('raw markup has nested t2>t1 and unmarked bare ayah parens', () {
      expect(raw, contains('ورجح الزمخشري'));
      expect(raw, contains('<span class="t1">" ملك "</span>'));
      expect(raw, contains('ولقوله : ( لمن الملك اليوم'));
      expect(raw, contains('وقوله : ( قوله الحق وله الملك'));
      expect(raw, contains('غريب جدا ]</span>'));
    });

    test('promotes chained bare ayah quotes after qawl leads', () {
      const snippet =
          '؛ لأنها قراءة أهل الحرمين ولقوله: (لمن الملك اليوم وقوله: '
          '(قوله الحق وله الملك وحكي عن أبي حنيفة أنه قرأ ملك يوم الدين '
          'على أنه فعل وفاعل ومفعول، وهذا شاذ غريب جدا]';

      final segments = TafsirTextParser.parse(
        '<span class="t2">[ ويقال: مليك أيضا، ورجح الزمخشري '
        '<span class="t1">" ملك "</span> '
        '$snippet'
        '</span>',
        tafsirId: TafsirId.ibnKathir,
      );

      final ayahs = segments
          .where((s) => s.kind == TafsirSegmentKind.ayah)
          .map((s) => s.text)
          .toList();

      expect(ayahs, contains('﴿لمن الملك اليوم﴾'));
      expect(ayahs, contains('﴿قوله الحق وله الملك﴾'));

      final zamakhshariTail = segments.firstWhere(
        (s) => s.text.contains('أبي حنيفة'),
      );
      expect(zamakhshariTail.kind, TafsirSegmentKind.commentary);
      expect(zamakhshariTail.text, contains('غريب جدا]'));
      expect(zamakhshariTail.text, isNot(contains('لمن الملك اليوم')));
    });

    test('flags truncation on full IK 1:4 row', () {
      final report = TafsirTextIntegrity.analyze(raw);

      expect(report.isLikelyTruncated, isTrue);
      expect(
        report.reasons,
        containsAll([
          TafsirTruncationReason.orphanClosingDiv,
          TafsirTruncationReason.unbalancedDelimiters,
        ]),
      );
    });
  });
}
