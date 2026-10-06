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
  test('unified search preserves symmetric Arabic chapter matching and source names', () async {
    final client = await HisnClient.open();
    addTearDown(client.close);
    final repository = FortressRepository(client);
    final chapter = repository.loadChapters()[3];
    expect(repository.search(chapter.title).titles.first.title, chapter.title);
    final plain = repository.search('اذكار');
    final vowelled = repository.search('أَذْكَار');
    expect(
      vowelled.titles.map((c) => c.chapterId),
      plain.titles.map((c) => c.chapterId),
    );
    expect(repository.search('مقدمه').titles.first.title, 'المقدمة');
    final limited = repository.search('اذكار', limit: 1);
    expect(limited.titles, hasLength(1));
    expect(limited.totalTitles, plain.totalTitles);
    // Composition evidence uses these queries; title ranking remains the same
    // as the unchanged upstream path used for the native captures.
    for (final query in ['النوم', 'الحمد', 'zzznomatchfortress']) {
      final (_, oldTitles) = client.search.searchTitles(
        HisnSearchQuery(
          value: query,
          target: HisnSearchTarget.title,
          limit: 30,
        ),
      );
      expect(
        repository.search(query).titles.map((c) => c.chapterId),
        oldTitles.map((c) => c.id),
      );
    }
  });
}
