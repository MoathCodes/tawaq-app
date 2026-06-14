import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:hisn_elmoslem/hisn_elmoslem.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/feature/muslim_fortress/data/sources/hisn_data_source.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_category.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_default_bookmarks.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_dua_item.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_search_results.dart';

part 'hisn_repository.g.dart';

const _assetPrefix = 'packages/hisn_elmoslem/assets/database/';
const _lockAssetPath = 'packages/hisn_elmoslem/assets/upstream.lock.json';
const _persistedLockFileName = 'install.lock.json';

const List<String> _databaseFiles = [
  HisnDatabaseNames.hisn,
  HisnDatabaseNames.commentary,
  HisnDatabaseNames.fakeHadith,
  HisnDatabaseNames.uthmani,
];

/// Copies bundled Hisn databases to app storage and exposes [HisnClient].
@Riverpod(keepAlive: true)
Future<HisnDataSource> hisnDataSource(Ref ref) async {
  final directory = await _ensureDatabasesDirectory();
  final client = await HisnClient.openFromDirectory(directory);
  ref.onDispose(client.close);
  return HisnDataSource(client);
}

/// Repository mapping Hisn data to fortress domain models.
@Riverpod(keepAlive: true)
Future<HisnRepository> hisnRepository(Ref ref) async {
  final source = await ref.watch(hisnDataSourceProvider.future);
  return HisnRepository(source);
}

Future<String> _ensureDatabasesDirectory() async {
  final documentsDir = await getApplicationDocumentsDirectory();
  final dbDir = p.join(
    documentsDir.path,
    'tawaq',
    'databases',
    'hisn_elmoslem',
  );
  await Directory(dbDir).create(recursive: true);

  final bundledVersion = await _resolveBundledVersionKey();
  final persistedVersion = await _readPersistedVersionKey(dbDir);
  final missingFile = _databaseFiles.any(
    (fileName) => !File(p.join(dbDir, fileName)).existsSync(),
  );
  final needsSync = missingFile || bundledVersion != persistedVersion;

  if (needsSync) {
    for (final fileName in _databaseFiles) {
      final target = File(p.join(dbDir, fileName));
      final data = await rootBundle.load('$_assetPrefix$fileName');
      await target.writeAsBytes(data.buffer.asUint8List(), flush: true);
    }
    await _writePersistedVersionKey(dbDir, bundledVersion);
  }

  return dbDir;
}

/// Upstream commit from the bundled lock file, or a DB size fingerprint.
Future<String> _resolveBundledVersionKey() async {
  try {
    final lockJson = await rootBundle.loadString(_lockAssetPath);
    final lock = jsonDecode(lockJson) as Map<String, dynamic>;
    final commit = lock['source_commit'];
    if (commit is String && commit.isNotEmpty && commit != 'unknown') {
      return commit;
    }
  } on Object {
    // Missing or invalid lock asset — fall back to size fingerprint.
  }
  return _bundledDatabasesSizeFingerprint();
}

Future<String> _bundledDatabasesSizeFingerprint() async {
  final parts = <String>[];
  for (final fileName in _databaseFiles) {
    final data = await rootBundle.load('$_assetPrefix$fileName');
    parts.add('$fileName:${data.lengthInBytes}');
  }
  return 'size:${parts.join('|')}';
}

Future<String?> _readPersistedVersionKey(String dbDir) async {
  final file = File(p.join(dbDir, _persistedLockFileName));
  if (!file.existsSync()) return null;

  try {
    final persisted =
        jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final versionKey = persisted['version_key'];
    return versionKey is String && versionKey.isNotEmpty ? versionKey : null;
  } on Object {
    return null;
  }
}

Future<void> _writePersistedVersionKey(String dbDir, String versionKey) async {
  final file = File(p.join(dbDir, _persistedLockFileName));
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert({'version_key': versionKey}),
    flush: true,
  );
}

/// Maps Hisn al-Muslim package data to Muslim Fortress domain models.
class HisnRepository {
  /// Creates the repository.
  HisnRepository(this._source);

  final HisnDataSource _source;

  HisnClient get _client => _source.client;

  /// All titles as sidebar/browse categories.
  List<FortressCategory> loadChapters() {
    final counts = _client.contents.countByTitleId();
    final featuredIds = _featuredTitleIds();

    return [
      for (final title in _client.titles.all())
        FortressCategory(
          chapterId: title.id,
          title: title.name.trim(),
          recurrence: title.recurrence,
          supplicationCount: counts[title.id] ?? 0,
          featured: featuredIds.contains(title.id),
        ),
    ];
  }

  /// Dhikr items for a title id.
  ///
  /// [titleId] is the Hisn title id.
  /// [categoryTitle] is shown on mapped items when non-empty.
  List<FortressDuaItem> loadItemsForTitleId(
    int titleId, {
    String categoryTitle = '',
  }) {
    return [
      for (final item in _client.contents.byTitleId(titleId))
        _mapContent(item, categoryTitle: categoryTitle),
    ];
  }

  /// Dhikr items for a category model.
  List<FortressDuaItem> loadItemsForChapter(
    FortressCategory category,
  ) => loadItemsForTitleId(
    category.chapterId,
    categoryTitle: category.title,
  );

  /// Global search across titles and dhikr contents.
  ///
  /// [query] is trimmed; empty input returns [FortressSearchResults.empty].
  /// [limit] caps matches returned for each of titles and contents.
  FortressSearchResults search(String query, {int limit = 30}) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return FortressSearchResults.empty;

    final titleQuery = HisnSearchQuery(
      value: trimmed,
      target: HisnSearchTarget.title,
      limit: limit,
    );
    final contentQuery = HisnSearchQuery(
      value: trimmed,
      limit: limit,
    );

    final (totalTitles, titles) = _client.search.searchTitles(titleQuery);
    final (totalContents, contents) = _client.search.searchContents(
      contentQuery,
    );
    final counts = _client.contents.countByTitleId();
    final titleNames = {
      for (final title in _client.titles.all()) title.id: title.name.trim(),
    };

    return FortressSearchResults(
      totalTitles: totalTitles,
      totalContents: totalContents,
      titles: [
        for (final title in titles)
          FortressCategory(
            chapterId: title.id,
            title: title.name.trim(),
            recurrence: title.recurrence,
            supplicationCount: counts[title.id] ?? 0,
            featured: _featuredTitleIds().contains(title.id),
          ),
      ],
      contents: [
        for (final item in contents)
          FortressSearchContentHit(
            chapterId: item.titleId,
            categoryTitle: titleNames[item.titleId] ?? '',
            item: _mapContent(
              item,
              categoryTitle: titleNames[item.titleId] ?? '',
            ),
          ),
      ],
    );
  }

  /// Full commentary for a content id (load on demand for study sheets).
  HisnCommentary? loadCommentaryForContent(int contentId) {
    return _client.commentary.byContentId(contentId);
  }

  /// Resolves default bookmark chapter ids from [fortressDefaultBookmarkFragments].
  ///
  /// Each fragment maps to the first matching title; duplicate ids are skipped
  /// while preserving fragment order.
  List<int> defaultBookmarkChapterIds() {
    final seen = <int>{};
    final ids = <int>[];

    for (final fragment in fortressDefaultBookmarkFragments) {
      final matches = _client.titles.byNameFragments([fragment]);
      if (matches.isEmpty) continue;

      final id = matches.first.id;
      if (seen.add(id)) {
        ids.add(id);
      }
    }

    return ids;
  }

  FortressDuaItem _mapContent(
    HisnContent item, {
    required String categoryTitle,
  }) {
    final flags = _client.commentary.flagsForContentId(item.id);

    return FortressDuaItem(
      contentId: item.id,
      category: categoryTitle,
      text: item.plainText.isNotEmpty
          ? item.plainText
          : item.toPlainText(_client.uthmani),
      targetCount: item.repeatCount <= 0 ? 1 : item.repeatCount,
      source: item.source.isEmpty ? null : item.source,
      virtue: item.virtue.isEmpty ? null : item.virtue,
      commentaryFlags: flags,
      audioUrl: item.audio?.remoteUrl.toString(),
      lines: item.lines,
    );
  }

  Set<int> _featuredTitleIds() {
    return {
      for (final title in _client.titles.byNameFragments(
        HisnFeaturedTitles.fragments,
      ))
        title.id,
    };
  }
}
