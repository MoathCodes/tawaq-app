library azkar;
part 'src/type.dart';
part 'src/data/about.dart';
part 'src/data/categories.dart';
part 'src/data/chapters.dart';
part 'src/data/items.dart';

class Azkar {
  static AboutAzkar getAbout(AzkarLang language) {
    Map indtroduction = _About.data[language.name]['indtroduction'];
    Map goal = _About.data[language.name]['benefit'];
    Introduction intro = Introduction(indtroduction['title'], indtroduction['content']);
    Benefit benefit = Benefit(goal['title'], goal['content']);

    return AboutAzkar(intro, benefit);
  }

  static List<Category> getCategories(AzkarLang language) {
    List categories = _Categories.data[language.name];

    return categories.map((e) => Category(e['id'], e['name'])).toList();
  }

  static List<ChapterCategory> getChapters(AzkarLang language) {
    List chapters = _Chapters.data[language.name];

    return chapters.map((e) => ChapterCategory(e['category_id'], e['id'], e['name'])).toList();
  }

  static List<ChapterCategory> getChaptersByCategory(AzkarLang language, int categoryID) {
    return getChapters(language).where((e) => e.categoryID == categoryID).toList();
  }

  static List<ItemChapter> getItemsByChapter(AzkarLang language, int chapterID) {
    final List<dynamic> raw = _Items.data[language.name];
    return raw
        .map<ItemChapter>(
          (e) => ItemChapter(
            e['chapter_id'] as int,
            e['id'] as int,
            e['reference'] as String,
            e['item'] as String,
          ),
        )
        .where((e) => e.chapterID == chapterID)
        .toList();
  }

  /// All azkar items for [language] (used for efficient chapter counts).
  static List<ItemChapter> getItems(AzkarLang language) {
    final List<dynamic> raw = _Items.data[language.name];
    return raw
        .map<ItemChapter>(
          (e) => ItemChapter(
            e['chapter_id'] as int,
            e['id'] as int,
            e['reference'] as String,
            e['item'] as String,
          ),
        )
        .toList();
  }
}
