import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:tawaq/core/database/bundled_database_set_installer.dart';
import 'package:tawaq/core/text/arabic_search_normalize.dart';

import 'package:flutter/services.dart';
import 'package:hisn_elmoslem/hisn_elmoslem.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/feature/muslim_fortress/domain/fortress_models.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_dua_item.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_search_results.dart';

part 'fortress_repository.g.dart';

const _assetPrefix = 'packages/hisn_elmoslem/assets/database/';
const _lockAssetPath = 'packages/hisn_elmoslem/assets/upstream.lock.json';

const List<String> _databaseFiles = [
  HisnDatabaseNames.hisn,
  HisnDatabaseNames.commentary,
  HisnDatabaseNames.fakeHadith,
  HisnDatabaseNames.uthmani,
];

/// Minimum trimmed query length before global search runs.
const fortressSearchMinQueryLength = 2;

/// Copies bundled Hisn databases to app storage and exposes
/// [FortressRepository].
@Riverpod(keepAlive: true)
Future<FortressRepository> fortressRepository(Ref ref) async {
  final directory = await _ensureDatabasesDirectory();
  final client = await HisnClient.openFromDirectory(directory);
  ref.onDispose(client.close);
  return FortressRepository(client);
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
  return installBundledDatabaseSet(
    root: Directory(dbDir),
    versionKey: bundledVersion,
    fileNames: _databaseFiles,
    load: (name) async {
      final data = await rootBundle.load('$_assetPrefix$name');
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    },
  );
}

/// Keep the upstream commit identity; malformed metadata uses content digests.
Future<String> _resolveBundledVersionKey() async {
  try {
    final lock = jsonDecode(
      await rootBundle.loadString(_lockAssetPath),
    ) as Map<String, dynamic>;
    final commit = lock['source_commit'];
    if (commit is String && RegExp(r'^[a-fA-F0-9]{40}$').hasMatch(commit))
      return commit;
  } on Object {
    /* Preserve usable installed data until staging succeeds. */
  }
  final parts = <String>[];
  for (final name in _databaseFiles) {
    final data = await rootBundle.load('$_assetPrefix$name');
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    parts.add('$name:${sha256.convert(bytes)}');
  }
  return 'sha256:${parts.join('|')}';
}

/// Maps Hisn al-Muslim package data to Muslim Fortress domain models.
class FortressRepository {
  /// Creates the repository.
  new(this._client);

  final HisnClient _client;

  Map<int, int>? _countsByTitleId;
  Map<int, String>? _titleNamesById;
  Set<int>? _featuredTitleIds;

  List<FortressCategory>? _chaptersCache;
  final Map<int, List<FortressDuaItem>> _duasByChapterId = {};
  final Map<int, HisnCommentary?> _commentaryByContentId = {};

  void _ensureChapterCaches() {
    if (_countsByTitleId != null &&
        _titleNamesById != null &&
        _featuredTitleIds != null) {
      return;
    }

    _countsByTitleId = _client.contents.countByTitleId();
    _titleNamesById = {
      for (final title in _client.titles.all()) title.id: title.name.trim(),
    };
    _featuredTitleIds = _resolveFeaturedTitleIds();
  }

  /// All titles as sidebar/browse categories.
  ///
  /// Cached for the lifetime of this repository (client reopen invalidates).
  List<FortressCategory> loadChapters() {
    final cached = _chaptersCache;
    if (cached != null) return cached;

    _ensureChapterCaches();
    final counts = _countsByTitleId!;
    final featuredIds = _featuredTitleIds!;

    return _chaptersCache = [
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

  /// Dhikr items for a Hisn title id.
  ///
  /// Cached per [chapterId] until the repository/client is reopened.
  List<FortressDuaItem> loadDuas(int chapterId) {
    final cached = _duasByChapterId[chapterId];
    if (cached != null) return cached;

    _ensureChapterCaches();
    final categoryTitle = _titleNamesById![chapterId] ?? '';
    final items = _client.contents.byTitleId(chapterId);
    final flagsById = _client.commentary.flagsForContentIds({
      for (final item in items) item.id,
    });

    return _duasByChapterId[chapterId] = [
      for (final item in items)
        _mapContent(
          item,
          categoryTitle: categoryTitle,
          flags: flagsById[item.id],
        ),
    ];
  }

  /// Global search across titles and dhikr contents.
  ///
  /// Returns [FortressSearchResults.empty] when [query] is shorter than
  /// [fortressSearchMinQueryLength] characters (after trim).
  FortressSearchResults search(String query, {int limit = 30}) {
    final trimmed = query.trim();
    if (trimmed.length < fortressSearchMinQueryLength) {
      return FortressSearchResults.empty;
    }

    // Keep the catalog's symmetric title matching when the single field
    // switches from browsing to content search. The upstream title index only
    // strips tashkeel, so passing a sourced vowelled title to it loses matches.
    final titles = loadChapters()
        .where((chapter) => arabicSearchContains(chapter.title, trimmed))
        .toList();
    final contentQuery = HisnSearchQuery(value: trimmed, limit: limit);

    final (totalContents, contents) = _client.search.searchContents(
      contentQuery,
    );
    _ensureChapterCaches();
    final titleNames = _titleNamesById!;
    final flagsById = _client.commentary.flagsForContentIds({
      for (final item in contents) item.id,
    });

    return FortressSearchResults(
      totalTitles: titles.length,
      totalContents: totalContents,
      titles: titles.take(limit).toList(),
      contents: [
        for (final item in contents)
          FortressSearchContentHit(
            chapterId: item.titleId,
            categoryTitle: titleNames[item.titleId] ?? '',
            item: _mapContent(
              item,
              categoryTitle: titleNames[item.titleId] ?? '',
              flags: flagsById[item.id],
            ),
          ),
      ],
    );
  }

  /// Full commentary for a content id (load on demand for study sheets).
  ///
  /// Cached by [contentId] via existing Hisn commentary `byContentId`.
  HisnCommentary? loadCommentaryForContent(int contentId) {
    if (_commentaryByContentId.containsKey(contentId)) {
      return _commentaryByContentId[contentId];
    }
    final commentary = _client.commentary.byContentId(contentId);
    _commentaryByContentId[contentId] = commentary;
    return commentary;
  }

  /// Resolves default bookmark chapter ids from
  /// [fortressDefaultBookmarkFragments].
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
    HisnCommentaryFlags? flags,
  }) {
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

  Set<int> _resolveFeaturedTitleIds() {
    return {
      for (final title in _client.titles.byNameFragments(
        HisnFeaturedTitles.fragments,
      ))
        title.id,
    };
  }
}
