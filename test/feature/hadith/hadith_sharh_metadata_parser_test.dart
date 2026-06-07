import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/hadith/domain/services/hadith_sharh_metadata_parser.dart';

void main() {
  late List<Map<String, dynamic>> fixtures;

  setUpAll(() {
    final raw =
        File('test/fixtures/hadith_sharh_samples.json').readAsStringSync();
    fixtures = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  });

  Map<String, dynamic> fixture(String id) {
    return fixtures.firstWhere((entry) => entry['id'] == id);
  }

  String metadataZone(String id) {
    final zones = fixture(id)['zones'] as Map<String, dynamic>;
    return zones['metadata'] as String;
  }

  group('empty input', () {
    test('returns all-null fields', () {
      final fields = HadithSharhMetadataParser.parse(null);
      expect(fields.hasAny, isFalse);
      expect(fields.rawi, isNull);
      expect(fields.mohdith, isNull);
      expect(fields.source, isNull);
      expect(fields.pageOrNumber, isNull);
      expect(fields.grade, isNull);
      expect(fields.takhrij, isNull);
    });
  });

  group('Sharh 113371 — metadata-rich', () {
    test('parses all header fields from zone metadata', () {
      final fields = HadithSharhMetadataParser.parse(metadataZone('113371'));

      expect(fields.rawi, 'عبدالله بن مسعود');
      expect(fields.mohdith, 'الألباني');
      expect(fields.source, 'صحيح الجامع');
      expect(fields.pageOrNumber, '3697');
      expect(fields.grade, 'صحيح');
      expect(
        fields.takhrij,
        startsWith('أخرجه البخاري في ((الأدب المفرد))'),
      );
      expect(fields.takhrij, contains('الطبراني'));
    });
  });

  group('Sharh 4730 — bracketed grade', () {
    test('parses metadata with bracketed grade summary', () {
      final fields = HadithSharhMetadataParser.parse(metadataZone('4730'));

      expect(fields.rawi, 'عائشة أم المؤمنين');
      expect(fields.mohdith, 'البخاري');
      expect(fields.source, 'صحيح البخاري');
      expect(fields.pageOrNumber, '3217');
      expect(fields.grade, '[صحيح]');
      expect(
        fields.takhrij,
        'أخرجه مسلم (2447)، وأبو داود (5232)، والنسائي (3953) جميعهم بلفظه.',
      );
    });
  });

  group('pipe and slash normalization', () {
    test('strips pipes and collapses slash runs before parsing', () {
      const raw = '''
الراوي : foo |  المحدث : bar
        |
        المصدر : baz // extra
        الصفحة أو الرقم: 1 |  خلاصة حكم المحدث : hasan
          التخريج :
        cited here
''';

      final fields = HadithSharhMetadataParser.parse(raw);

      expect(fields.rawi, 'foo');
      expect(fields.mohdith, 'bar');
      expect(fields.source, 'baz extra');
      expect(fields.pageOrNumber, '1');
      expect(fields.grade, 'hasan');
      expect(fields.takhrij, 'cited here');
    });
  });
}
