import 'package:flutter_test/flutter_test.dart';
import 'package:hivez_flutter/hivez_flutter.dart';
import 'package:tawaq/feature/hadith/data/database/hadith_local_database.dart';
import 'package:tawaq/feature/hadith/data/models/hadith_recent_search.dart';
import 'package:tawaq/hive/hive_registrar.g.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    Hive
      ..init('./test/hive_test_db')
      ..registerAdapters();
  });

  group('HadithLocalDatabase recent searches', () {
    late Box<String, dynamic> favoritesBox;
    late Box<int, HadithRecentSearch> recentsBox;
    late HadithLocalDatabase db;

    setUp(() async {
      final suffix = DateTime.now().microsecondsSinceEpoch;
      favoritesBox = Box<String, dynamic>('hadith_fav_test_$suffix');
      recentsBox = Box<int, HadithRecentSearch>('hadith_recents_test_$suffix');
      await favoritesBox.clear();
      await recentsBox.clear();
      db = HadithLocalDatabase(
        favoritesBox: favoritesBox,
        recentsBox: recentsBox,
      );
    });

    tearDown(() async {
      await favoritesBox.clear();
      await recentsBox.clear();
      await favoritesBox.deleteFromDisk();
      await recentsBox.deleteFromDisk();
    });

    test('prunes stored recents to 12 on write', () async {
      for (var i = 0; i < 50; i++) {
        await db.addRecentSearch('query-$i');
      }

      expect(await recentsBox.length, lessThanOrEqualTo(12));

      final recents = await db.getRecentSearches();
      expect(recents, hasLength(12));
      expect(recents.first.query, 'query-49');
      expect(recents.last.query, 'query-38');
    });

    test('getRecentSearches prunes legacy overflow on read', () async {
      final now = DateTime.now();
      for (var i = 0; i < 20; i++) {
        await recentsBox.put(
          i,
          HadithRecentSearch(
            id: i,
            query: 'legacy-$i',
            searchedAt: now.subtract(Duration(minutes: 20 - i)),
          ),
        );
      }

      expect(await recentsBox.length, 20);

      final recents = await db.getRecentSearches();
      expect(recents, hasLength(12));
      expect(await recentsBox.length, 12);
      expect(recents.first.query, 'legacy-19');
    });
  });
}
