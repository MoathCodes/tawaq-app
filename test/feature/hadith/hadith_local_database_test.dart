import 'package:dorar_hadith/dorar_hadith.dart';
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

    test('prunes stored favorites to 500 on write', () async {
      for (var i = 0; i < 520; i++) {
        await db.addFavorite(
          'key-$i',
          DetailedHadith(
            hadith: 'hadith-$i',
            rawi: 'rawi',
            mohdith: 'mohdith',
            book: 'book',
            numberOrPage: '$i',
            grade: 'صحيح',
            explainGrade: 'صحيح',
          ),
        );
      }

      expect(await favoritesBox.length, lessThanOrEqualTo(500));
      expect(await favoritesBox.containsKey('key-0'), isFalse);
      expect(await favoritesBox.containsKey('key-519'), isTrue);
    });

    test('prunes favorites by savedAt, not string key order', () async {
      // Lexicographically first key is "z-old"; newest keys are "a-new-*".
      // Key-order prune would keep "z-old"; time-order prune must drop it.
      await favoritesBox.put(
        'z-old',
        '{"savedAt":"2020-01-01T00:00:00.000","hadith":{"hadith":"old","rawi":"r","mohdith":"m","book":"b","numberOrPage":"1","grade":"g","explainGrade":"g"}}',
      );

      for (var i = 0; i < HadithLocalDatabase.maxFavorites; i++) {
        await db.addFavorite(
          'a-new-$i',
          DetailedHadith(
            hadith: 'new-$i',
            rawi: 'rawi',
            mohdith: 'mohdith',
            book: 'book',
            numberOrPage: '$i',
            grade: 'صحيح',
            explainGrade: 'صحيح',
          ),
        );
      }

      expect(await favoritesBox.length, HadithLocalDatabase.maxFavorites);
      expect(await favoritesBox.containsKey('z-old'), isFalse);
      expect(await favoritesBox.containsKey('a-new-0'), isTrue);
    });

    test('skips corrupt favorite entries without failing the list', () async {
      await db.addFavorite(
        'ok',
        const DetailedHadith(
          hadith: 'good-hadith',
          rawi: 'rawi',
          mohdith: 'mohdith',
          book: 'book',
          numberOrPage: '1',
          grade: 'صحيح',
          explainGrade: 'صحيح',
        ),
      );
      await favoritesBox.put('bad', '{not-json');

      final favorites = await db.getAllFavorites();
      expect(favorites, hasLength(1));
      expect(favorites.single.hadith, 'good-hadith');
      expect(await favoritesBox.containsKey('bad'), isFalse);
    });
  });
}
