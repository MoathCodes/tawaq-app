import '../database/hisn_database.dart';
import '../models/content.dart';
import '../models/models.dart';
import '../parsers/uthmani_text_resolver.dart';
import '../services/commentary_service.dart';
import '../services/content_service.dart';
import '../services/fake_hadith_service.dart';
import '../services/filter_service.dart';
import '../services/search_service.dart';
import '../services/title_service.dart';

/// Main entry point for Hisn al-Muslim data access.
final class HisnClient {
  HisnClient._(this._database)
    : titles = TitleService(_database),
      contents = ContentService(_database),
      commentary = CommentaryService(_database),
      fakeHadith = FakeHadithService(_database),
      search = SearchService(_database),
      uthmani = UthmaniTextResolver(_database);

  final HisnDatabase _database;

  /// Title operations.
  final TitleService titles;

  /// Content operations.
  final ContentService contents;

  /// Commentary operations.
  final CommentaryService commentary;

  /// Fake hadith warnings.
  final FakeHadithService fakeHadith;

  /// Search operations.
  final SearchService search;

  /// Uthmani Quranic text resolver.
  final UthmaniTextResolver uthmani;

  /// Opens a client with bundled databases.
  static Future<HisnClient> open() async {
    final database = await HisnDatabase.open();
    return HisnClient._(database);
  }

  /// Opens a client from a directory of `.db` files (Flutter asset copy).
  static Future<HisnClient> openFromDirectory(String directory) async {
    final database = await HisnDatabase.openFromDirectory(directory);
    return HisnClient._(database);
  }

  /// Loads a content row with its commentary attached.
  HisnContent? contentWithCommentary(int contentId) {
    final content = contents.byId(contentId);
    if (content == null) return null;

    final loadedCommentary = commentary.byContentId(contentId);
    if (loadedCommentary == null) return content;

    return HisnContent(
      id: content.id,
      titleId: content.titleId,
      order: content.order,
      repeatCount: content.repeatCount,
      lines: content.lines,
      rawContent: content.rawContent,
      virtue: content.virtue,
      source: content.source,
      hokm: content.hokm,
      searchText: content.searchText,
      audio: content.audio,
      commentary: loadedCommentary,
    );
  }

  /// Filters contents using [criteria].
  List<HisnContent> filterContents(
    List<HisnContent> items,
    HisnFilterCriteria criteria,
  ) =>
      HisnFilterService.apply(items, criteria);

  /// Closes all database handles.
  void close() => _database.close();
}

/// Well-known title name fragments for featured sections.
abstract final class HisnFeaturedTitles {
  /// Morning adhkar title fragment.
  static const morning = 'أَذْكَارُ الصَّبَاحِ';

  /// Evening adhkar title fragment.
  static const evening = 'أَذْكَارُ الْمَسَاءِ';

  /// Sleep adhkar title fragment.
  static const sleep = 'أَذْكَارُ النَّوْمِ';

  /// Waking adhkar title fragment.
  static const waking = 'أَذْكَارُ الاسْتِيقَاظِ';

  /// All featured title fragments in display order.
  static const fragments = [morning, evening, sleep, waking];
}
