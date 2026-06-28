import 'package:flutter_test/flutter_test.dart';
import 'package:hisn_elmoslem/hisn_elmoslem.dart';
import 'package:tawaq/feature/muslim_fortress/data/repository/fortress_repository.dart';

void main() {
  test('repository marks quranic items from structured content lines', () async {
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
  });
}
