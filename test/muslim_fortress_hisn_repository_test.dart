import 'package:flutter_test/flutter_test.dart';
import 'package:hisn_elmoslem/hisn_elmoslem.dart';
import 'package:tawaq/feature/muslim_fortress/data/repository/fortress_repository.dart';

void main() {
  test('repository loads chapters and items from hisn_elmoslem', () async {
    final client = await HisnClient.openFromDirectory(
      'packages/hisn_elmoslem/assets/database',
    );
    addTearDown(client.close);

    final repo = FortressRepository(client);
    final chapters = repo.loadChapters();
    expect(chapters, isNotEmpty);
    expect(chapters.first.supplicationCount, greaterThan(0));

    final items = repo.loadDuas(chapters.first.chapterId);
    expect(items, isNotEmpty);
    expect(items.first.text, isNotEmpty);
  });
}
