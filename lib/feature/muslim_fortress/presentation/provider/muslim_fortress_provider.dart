import 'package:hisn_elmoslem/hisn_elmoslem.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_category.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_dua_item.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_search_results.dart';
import 'package:tawaq/feature/muslim_fortress/domain/services/fortress_service.dart';

part 'muslim_fortress_provider.g.dart';

/// All Hisn al-Muslim titles for the fortress UI.
@riverpod
Future<List<FortressCategory>> muslimFortressChapters(Ref ref) async {
  final service = await ref.watch(fortressServiceProvider.future);
  return service.loadChapters();
}

/// Dhikr items for a single Hisn title.
///
/// [chapterId] is the Hisn title id.
@riverpod
Future<List<FortressDuaItem>> muslimFortressDuas(
  Ref ref,
  int chapterId,
) async {
  final service = await ref.watch(fortressServiceProvider.future);
  final chapters = await ref.watch(muslimFortressChaptersProvider.future);
  return service.loadDuasForChapter(chapterId, chapters: chapters);
}

/// In-memory global search query (trimmed; debounced in the screen).
@riverpod
class MuslimFortressSearchQuery extends _$MuslimFortressSearchQuery {
  @override
  String build() => '';

  /// Updates the active search query.
  void setQuery(String query) => state = query.trim();
}

/// Search results for [muslimFortressSearchQueryProvider].
@riverpod
Future<FortressSearchResults> muslimFortressSearchResults(Ref ref) async {
  final query = ref.watch(muslimFortressSearchQueryProvider);
  final service = await ref.watch(fortressServiceProvider.future);
  return service.search(query);
}

/// On-demand sharh commentary for a Hisn content id.
@riverpod
Future<HisnCommentary?> muslimFortressCommentary(
  Ref ref,
  int contentId,
) async {
  final service = await ref.watch(fortressServiceProvider.future);
  return service.loadCommentaryForContent(contentId);
}
