import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivez_flutter/hivez_flutter.dart';
import 'package:tawaq/feature/hadith/data/database/hadith_local_database.dart';
import 'package:tawaq/feature/hadith/data/models/hadith_recent_search.dart';
import 'package:tawaq/feature/hadith/data/models/hadith_favorite.dart';
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

    test('invalid enrichments recover exact scalars without writing or pruning originals', () async {
      const source = 'saved — 😀 religious wording';
      final hash = sha256.convert(utf8.encode('1\n$source')).toString();
      for (final defect in ['hash', 'schema', 'range']) {
        final raw = {
          'savedAt': '2020-01-01T00:00:00.000',
          'hadith': {
            'hadith': source,
            'rawi': 'saved narrator',
            'mohdith': 'saved scholar',
            'book': 'saved book',
            'numberOrPage': 'raw locator',
            'grade': 'saved ruling',
            'content': {
              'schemaVersion': defect == 'schema' ? 99 : 1,
              'sourceHtml': '',
              'sourceText': source,
              'contentHash': defect == 'hash' ? 'invalid' : hash,
              'blocks': [
                {
                  'kind': 'paragraph',
                  'range': {
                    'start': 0,
                    'end': defect == 'range' ? 1000 : source.length,
                  },
                },
              ],
            },
          },
        };
        final original = jsonEncode(raw);
        await favoritesBox.put('legacy-$defect', original);
        for (var read = 0; read < 2; read++) {
          final entries = await db.getFavoriteEntries();
          final entry = entries.singleWhere(
            (entry) => entry.key == 'legacy-$defect',
          );
          expect(entry.hadith!.hadith, source);
          expect(entry.hadith!.content, isNull);
          expect(entry.richContentUnavailable, isTrue);
          expect(await favoritesBox.get('legacy-$defect'), original);
        }
      }
      for (var i = 0; i <= HadithLocalDatabase.maxFavorites; i++) {
        await db.addFavorite(
          'neighbor-$i',
          const DetailedHadith(
            hadith: 'neighbor',
            rawi: 'r',
            mohdith: 'm',
            book: 'b',
            numberOrPage: '1',
            grade: 'g',
          ),
        );
      }
      final favoriteName = favoritesBox.name;
      await favoritesBox.flushBox();
      await favoritesBox.closeBox();
      favoritesBox = Box<String, dynamic>(favoriteName);
      final restarted = HadithLocalDatabase(
        favoritesBox: favoritesBox,
        recentsBox: recentsBox,
      );
      expect(
        (await restarted.getFavoriteEntries()).where(
          (entry) => entry.richContentUnavailable,
        ),
        hasLength(3),
      );
      expect(await favoritesBox.containsKey('neighbor-500'), isTrue);
    });

    test('legacy favorite JSON and Hive objects keep their wording and stored keys', () async {
      final favorite = HadithFavorite(
        key: 'old-inner-key',
        hadith: 'historical wording',
        rawi: 'r',
        mohdith: 'm',
        book: 'b',
        numberOrPage: '1',
        hukm: 'source ruling',
        savedAt: DateTime(2020),
      );
      await favoritesBox.put('actual-json-key', jsonEncode(favorite.toJson()));
      await favoritesBox.put('actual-hive-key', favorite);
      final entries = await db.getFavoriteEntries();
      expect(entries.map((entry) => entry.key).toSet(), {
        'actual-json-key',
        'actual-hive-key',
      });
      expect(
        entries.every(
          (entry) =>
              entry.hadith!.hadith == favorite.hadith &&
              !entry.richContentUnavailable,
        ),
        isTrue,
      );
      expect(
        entries.every((entry) => entry.savedAt == favorite.savedAt),
        isTrue,
      );
    });

    test('original ID-less keys survive reads and explicit removal', () async {
      const value =
          '{"hadith":"legacy text","rawi":"r","mohdith":"m","book":"b","numberOrPage":"1","grade":"g"}';
      await favoritesBox.put('old-key-123', value);
      final entry = (await db.getFavoriteEntries()).single;
      expect(entry.key, 'old-key-123');
      expect(entry.hadith!.hadith, 'legacy text');
      await db.deleteFavorite(entry.key);
      expect(await db.getFavoriteEntries(), isEmpty);
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
      expect(await favoritesBox.get('bad'), '{not-json');
      final entries = await db.getFavoriteEntries();
      expect(entries.singleWhere((entry) => entry.key == 'bad').hadith, isNull);
      await db.getAllFavorites();
      expect(await favoritesBox.get('bad'), '{not-json');
    });
  });
}
