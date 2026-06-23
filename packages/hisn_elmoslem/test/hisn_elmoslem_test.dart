import 'package:hisn_elmoslem/hisn_elmoslem.dart';
import 'package:test/test.dart';

void main() {
  group('QuranTextParser', () {
    test('parses single ayah marker', () {
      final ranges = QuranTextParser.parseLine('QuranText[(2:152:152)]');
      expect(ranges, hasLength(1));
      expect(ranges.first.surah, 2);
      expect(ranges.first.startAyah, 152);
      expect(ranges.first.endAyah, 152);
    });

    test('parses multiple ranges in one marker', () {
      final ranges = QuranTextParser.parseLine(
        'QuranText[(2:1:3),(3:190:200)]',
      );
      expect(ranges, hasLength(2));
      expect(ranges.first.surah, 2);
      expect(ranges.last.surah, 3);
      expect(ranges.last.endAyah, 200);
    });

    test('splits mixed content into lines', () {
      final lines = QuranTextParser.parseContent(
        'QuranText[(2:152:152)]\nبعدها نص',
      );
      expect(lines, hasLength(2));
      expect(lines.first, isA<HisnQuranLine>());
      expect(lines.last, isA<HisnPlainLine>());
    });
  });

  group('QuranPresentationClassifier', () {
    test('classifies single ayah as HisnQuranSingleAyah', () {
      final presentation = QuranTextParser.classifyLine(
        'QuranText[(2:255:255)]',
      );
      expect(presentation, isA<HisnQuranSingleAyah>());
      expect(
        (presentation as HisnQuranSingleAyah).range.surah,
        2,
      );
    });

    test('classifies Muawwidhat as HisnQuranMushafPages', () {
      final presentation = QuranTextParser.classifyLine(
        'QuranText[(112:1:4),(113:1:5),(114:1:6)]',
      );
      expect(presentation, isA<HisnQuranMushafPages>());
      final pages = (presentation as HisnQuranMushafPages).pages;
      expect(pages, isNotEmpty);
    });

    test('classifies full surah range as HisnQuranMushafPages', () {
      final presentation = QuranTextParser.classifyLine(
        'QuranText[(32:1:30)]',
      );
      expect(presentation, isA<HisnQuranMushafPages>());
    });

    test('classifies partial surah as HisnQuranPassage', () {
      final presentation = QuranTextParser.classifyLine(
        'QuranText[(2:1:3)]',
      );
      expect(presentation, isA<HisnQuranPassage>());
    });

    test('HisnQuranLine stores classified presentation', () {
      final lines = QuranTextParser.parseContent(
        'QuranText[(112:1:4),(113:1:5),(114:1:6)]',
      );
      final line = lines.single as HisnQuranLine;
      expect(line.presentation, isA<HisnQuranMushafPages>());
    });
  });

  group('HisnClient integration', () {
    late HisnClient client;

    setUp(() async {
      client = await HisnClient.open();
    });

    tearDown(() {
      client.close();
    });

    test('loads expected row counts from lock expectations', () {
      final titles = client.titles.all();
      final contents = client.contents.all();
      final fakeHadiths = client.fakeHadith.all();

      expect(titles.length, 135);
      expect(contents.length, 335);
      expect(fakeHadiths.length, 20);
    });

    test('finds featured titles by name fragment', () {
      for (final fragment in HisnFeaturedTitles.fragments) {
        final matches = client.titles.byNameFragments([fragment]);
        expect(matches, isNotEmpty, reason: 'Missing title for $fragment');
      }
    });

    test('parses Quranic content with verse ranges', () {
      final quranic = client.contents
          .all()
          .where((item) => item.isQuranic)
          .toList();
      expect(quranic, isNotEmpty);

      final firstRange = quranic.first.quranRanges.first;
      expect(firstRange.surah, inInclusiveRange(1, 114));
      expect(firstRange.startAyah, greaterThan(0));
    });

    test('batch flags lookup matches single-id lookup', () {
      final single = client.commentary.flagsForContentId(15);
      final batch = client.commentary.flagsForContentIds({15, 16, 17});

      expect(single, isNotNull);
      final batchFlags = batch[15];
      expect(batchFlags, isNotNull);
      expect(batchFlags!.hasSharh, single!.hasSharh);
      expect(batchFlags.hasHadith, single.hasHadith);
      expect(batchFlags.hasBenefit, single.hasBenefit);
      expect(batch.length, lessThanOrEqualTo(3));
    });

    test('loads commentary for known content', () {
      final commentary = client.commentary.byContentId(15);
      expect(commentary, isNotNull);
      expect(commentary!.isNotEmpty, isTrue);
    });

    test('search finds morning adhkar titles', () {
      final (total, titles) = client.search.searchTitles(
        const HisnSearchQuery(
          value: 'الصباح',
          mode: HisnSearchMode.typical,
        ),
      );
      expect(total, greaterThan(0));
      expect(titles, isNotEmpty);
    });

    test('resolves plain text for Quranic content', () {
      final item = client.contents.all().firstWhere((c) => c.isQuranic);
      final plain = item.toPlainText(client.uthmani);
      expect(plain, isNotEmpty);
      expect(plain, isNot(contains('QuranText')));
    });

    test('filters by authenticity when enabled', () {
      final items = client.contents.byTitleId(29);
      final filtered = client.filterContents(
        items,
        const HisnFilterCriteria(
          filterByAuthenticity: true,
          activeAuthenticities: {HisnAuthenticity.sahih},
        ),
      );
      for (final item in filtered) {
        expect(item.hokm, HisnAuthenticity.sahih.dbValue);
      }
    });
  });
}
