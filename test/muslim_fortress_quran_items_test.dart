import 'package:flutter_test/flutter_test.dart';
import 'package:hisn_elmoslem/hisn_elmoslem.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/gen/fonts.gen.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/reading/fortress_text_spans.dart';
import 'package:tawaq/feature/muslim_fortress/data/repository/fortress_repository.dart';

void main() {
  test(
    'mixed Quran and prose sharing keeps every canonical source line',
    () async {
      final client = await HisnClient.openFromDirectory(
        'packages/hisn_elmoslem/assets/database',
      );
      addTearDown(client.close);
      final repository = FortressRepository(client);
      var mixed = 0;
      for (final chapter in repository.loadChapters()) {
        for (final item in repository.loadDuas(chapter.chapterId)) {
          if (!item.isQuranicPassage ||
              !item.lines.any(
                (line) => line is HisnPlainLine && line.text.trim().isNotEmpty,
              ))
            continue;
          mixed++;
          final source = client.contents.byId(item.contentId)!;
          expect(
            item.text,
            source.toPlainText(client.uthmani),
            reason: 'content ${item.contentId}',
          );
          expect(item.text, contains('﴿'));
        }
      }
      expect(mixed, greaterThan(0));
    },
  );
  test('bundled mixed quotation uses Quran typography without changing source or prose', () async {
    final client = await HisnClient.openFromDirectory(
      'packages/hisn_elmoslem/assets/database',
    );
    addTearDown(client.close);
    final source = client.contents.byId(336)!.toPlainText(client.uthmani);
    final span = fortressDhikrSpan(
      source,
      const TextStyle(fontFamily: FontFamily.uthmanTN),
    );
    final children = span.children!.cast<TextSpan>();
    final quotation = children.singleWhere(
      (s) => s.style?.fontFamily == FontFamily.uthmanicHafs,
    );
    final rawQuote = RegExp(
      r'﴿([^﴾]+)﴾',
      dotAll: true,
    ).firstMatch(source)!.group(0)!;
    expect(quotation.semanticsLabel, rawQuote);
    expect(quotation.text, isNot(contains('﴿')));
    expect(quotation.text, contains('١٣'));
    expect(quotation.text, isNot(contains('\u06DD')));
    expect(quotation.style!.fontWeight, FontWeight.w400);
    expect(children.last.text, source.substring(source.indexOf('﴾') + 1));
    expect(span.toPlainText(), source);
    expect(client.contents.byId(336)!.toPlainText(client.uthmani), source);
  });

  test(
    'repository marks quranic items from structured content lines',
    () async {
      final client = await HisnClient.openFromDirectory(
        'packages/hisn_elmoslem/assets/database',
      );
      addTearDown(client.close);

      final repo = FortressRepository(client);
      final morning = repo.loadChapters().firstWhere(
        (c) => c.title.contains(HisnFeaturedTitles.morning),
      );
      final items = repo.loadDuas(morning.chapterId);
      final quranic = items.where((i) => i.isQuranicPassage).toList();
      expect(quranic, isNotEmpty);
      expect(quranic.first.primaryQuranRange, isNotNull);
      expect(quranic.first.primaryQuranRange!.surah, inInclusiveRange(1, 114));
    },
  );
}
