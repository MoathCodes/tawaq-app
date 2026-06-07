import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_sharh_segment.dart';
import 'package:tawaq/feature/hadith/domain/services/hadith_sharh_segment_tokenizer.dart';
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

  List<HadithSharhSegment> segmentsFor(String id) {
    final sample = fixture(id);
    final zones = HadithSharhZoneSplitter.split(sample['sharh'] as String);
    return HadithSharhSegmentTokenizer.tokenize(zones.commentary);
  }

  group('Sharh 113371 — أي chain pairs', () {
    test('detects gloss chain segments', () {
      final segments = segmentsFor('113371');
      final chains = segments
          .where((s) => s.kind == HadithSharhSegmentKind.glossChain)
          .toList();

      expect(chains, isNotEmpty);
      expect(chains.first.quotedPhrase, isNotNull);
      expect(chains.first.glossText, isNotNull);
    });

    test('detects section lead segments', () {
      final segments = segmentsFor('113371');
      expect(
        segments.any((s) => s.kind == HadithSharhSegmentKind.sectionLead),
        isTrue,
      );
    });
  });

  group('Sharh 15844 — وقيل stack', () {
    test('detects alternate opinion segments', () {
      final segments = segmentsFor('15844');
      final waqil = segments
          .where((s) => s.kind == HadithSharhSegmentKind.alternateOpinion)
          .toList();

      expect(waqil.length, greaterThanOrEqualTo(3));
    });
  });

  group('Sharh 225404 — gloss chain density', () {
    test('detects many gloss chain segments', () {
      final segments = segmentsFor('225404');
      final chains = segments
          .where((s) => s.kind == HadithSharhSegmentKind.glossChain)
          .toList();

      expect(chains.length, greaterThanOrEqualTo(5));
    });
  });

  group('editorial bracket tokenizer', () {
    test('detects [هذا] editorial brackets in prose', () {
      const sample = 'قالوا: [هذا] رسولُ اللهِ ﷺ، أي: النبيُّ.';
      final segments = HadithSharhSegmentTokenizer.tokenize(sample);

      expect(
        segments.any((s) => s.kind == HadithSharhSegmentKind.editorialBracket),
        isTrue,
      );
    });
  });

  group('Sharh 4730 — guillemet gloss chain', () {
    test('keeps «quote»، أي: on one gloss chain segment', () {
      final segments = segmentsFor('4730');
      final chain = segments.firstWhere(
        (s) => s.quotedPhrase?.contains('تَرى ما لا أرى') ?? false,
      );

      expect(chain.kind, HadithSharhSegmentKind.glossChain);
      expect(chain.quotedPhrase, '«تَرى ما لا أرى»');
      expect(chain.glossText, startsWith('إنَّكَ'));
      expect(
        segments.any(
          (s) => s.kind == HadithSharhSegmentKind.prose && s.text.trim() == '،',
        ),
        isFalse,
        reason: 'orphan comma must not be its own prose segment',
      );
    });
  });

  group('Sharh 4742 — guillemet gloss chain', () {
    test('matches sharh 4730 guillemet gloss behavior', () {
      final segments = segmentsFor('4742');
      final chain = segments.firstWhere(
        (s) => s.quotedPhrase?.contains('تَرى ما لا أرى') ?? false,
      );

      expect(chain.kind, HadithSharhSegmentKind.glossChain);
      expect(
        segments.any(
          (s) => s.kind == HadithSharhSegmentKind.prose && s.text.trim() == '،',
        ),
        isFalse,
      );
    });
  });

  group('Sharh 211278 — scholar leads', () {
    test('detects scholar lead segments', () {
      final segments = segmentsFor('211278');
      expect(
        segments.any((s) => s.kind == HadithSharhSegmentKind.scholarLead),
        isTrue,
      );
    });
  });

  group('Sharh 30638 — gloss chain density', () {
    test('detects gloss chains despite orphan quote marks', () {
      final segments = segmentsFor('30638');
      final chains = segments
          .where((s) => s.kind == HadithSharhSegmentKind.glossChain)
          .toList();

      expect(chains.length, greaterThanOrEqualTo(20));
      expect(
        chains.any((s) => s.quotedPhrase?.contains('أنا رسولُ اللهِ') ?? false),
        isTrue,
      );
      expect(
        chains.any((s) => s.quotedPhrase?.contains('فَدْعوتَه') ?? false),
        isTrue,
      );
    });
  });
}
