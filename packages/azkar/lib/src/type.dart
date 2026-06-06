part of azkar;

enum AzkarLang {
  arabic, english, farsi, russian, kurdish
}

class Introduction {
  String title;
  String content;

  Introduction(this.title, this.content);
}

class Benefit {
  String title;
  String content;

  Benefit(this.title, this.content);
}

class AboutAzkar {
  Introduction introduction;
  Benefit benefit;

  AboutAzkar(this.introduction, this.benefit);
}

class Category {
  int id;
  String name;

  Category(this.id, this.name);
}

class ChapterCategory {
  int categoryID;
  int id;
  String name;

  ChapterCategory(this.categoryID, this.id, this.name);
}

class ItemChapter {
  int chapterID;
  int id;
  String reference;
  String text;

  ItemChapter(this.chapterID, this.id, this.reference, this.text);
}