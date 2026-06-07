import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/hadith/domain/services/hadith_sharh_zone_splitter.dart';

void main() {
  late List<Map<String, dynamic>> fixtures;

  setUpAll(() {
    final raw = File('test/fixtures/hadith_sharh_samples.json').readAsStringSync();
    fixtures = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  });

  Map<String, dynamic> fixture(String id) {
    return fixtures.firstWhere((entry) => entry['id'] == id);
  }

  group('Sharh 113371 — zone split strips metadata', () {
    test('splits metadata-rich sharh into zones', () {
      final sample = fixture('113371');
      final zones = HadithSharhZoneSplitter.split(sample['sharh'] as String);

      expect(zones.isMetadataRich, isTrue);
      expect(zones.matnPrefix, isNotNull);
      expect(zones.metadata, contains('الراوي'));
      expect(zones.metadata, contains('التخريج'));
      expect(zones.commentary, isNot(contains('الراوي :')));
      expect(zones.commentary, contains('وفي هذا الح'));
    });
  });

  group('Sharh 15844 — pure essay no metadata', () {
    test('treats entire text as commentary', () {
      final sample = fixture('15844');
      final zones = HadithSharhZoneSplitter.split(sample['sharh'] as String);

      expect(zones.isMetadataRich, isFalse);
      expect(zones.matnPrefix, isNull);
      expect(zones.metadata, isNull);
      expect(zones.commentary, contains('وقيل:'));
      expect(zones.commentary.length, greaterThan(500));
    });
  });

  group('Sharh 210557 — thematic opener intact', () {
    test('preserves essay opener in commentary', () {
      final sample = fixture('210557');
      final zones = HadithSharhZoneSplitter.split(sample['sharh'] as String);

      expect(zones.isMetadataRich, isFalse);
      expect(
        zones.commentary,
        startsWith('الصَّحابةُ'),
      );
    });
  });

  group('Sharh 30638 — metadata and commentary split', () {
    test('extracts commentary with bracket patterns', () {
      final sample = fixture('30638');
      final zones = HadithSharhZoneSplitter.split(sample['sharh'] as String);

      expect(zones.isMetadataRich, isTrue);
      expect(zones.commentary, isNot(contains('التخريج :')));
    });
  });

  group('Sharh 211278 — takhrij citation in metadata zone', () {
    test('keeps takhrij in metadata not commentary', () {
      final sample = fixture('211278');
      final zones = HadithSharhZoneSplitter.split(sample['sharh'] as String);

      expect(zones.metadata, contains('التخريج'));
      expect(zones.metadata, contains('أخرجه'));
      expect(zones.commentary, isNot(contains('أخرجه')));
    });
  });

  group('Sharh 64144 — Dorar stub returns linked sharh ID', () {
    test('strips numeric placeholder from commentary zone', () {
      const stubSharh = '''
صَلَّيتُ مع رَسولِ اللهِ صلَّى اللهُ عليه وسلَّم فكُنَّا إذا سَلَّمنا قُلنا بأيدينا: السَّلامُ علَيكُم، السَّلامُ علَيكُم، فنَظَرَ إلَينا رَسولُ اللهِ صلَّى اللهُ عليه وسلَّم فقال: ما شَأنُكُم تُشيرونَ بأيديكُم كَأنَّها أذنابُ خَيلٍ شُمسٍ؟ إذا سَلَّمَ أحَدُكُم فليَلتَفِتْ إلى صاحِبِه، ولا يومِئُ بيَدِه.
     الراوي :
        جابر بن سمرة |  المحدث :
        مسلم
        |
        المصدر :
        صحيح مسلم


        الصفحة أو الرقم: 431 |  خلاصة حكم المحدث : [صحيح]

          التخريج :
        أخرجه أبو ادود (1000)، وأحمد (20964)، وابن حبان (1878) جميعهم باختلاف يسير.



113343''';

      final zones = HadithSharhZoneSplitter.split(stubSharh);

      expect(zones.isMetadataRich, isTrue);
      expect(zones.metadata, contains('صحيح مسلم'));
      expect(zones.metadata, contains('431'));
      expect(zones.commentary, isEmpty);
    });
  });

  group('Sharh 113343 — valid commentary preserved', () {
    test('keeps prose commentary when sharh page has full text', () {
      const sharh = '''
ثلاثةٌ من الكُفرِ باللهِ : شَقُّ الجيبِ ، والنِّياحةُ ، والطَّعنُ في النَّسَبِ .
     الراوي :
        أبو هريرة |  المحدث :
        الألباني
        |
        المصدر :
        صحيح الترغيب


        الصفحة أو الرقم: 3525 |  خلاصة حكم المحدث : صحيح

          التخريج :
        أخرجه ابن حبان (1465)، والحاكم (1415)



كان النَّبيُّ صلَّى اللهُ عليهِ وسلَّم حَريصًا على إخراجِ أُمَّتِهِ منَ الجاهليَّةِ''';

      final zones = HadithSharhZoneSplitter.split(sharh);

      expect(zones.commentary, isNotEmpty);
      expect(zones.commentary, contains('كان النَّبيُّ'));
      expect(zones.commentary, isNot(contains('113343')));
    });
  });
}
