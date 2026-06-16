import 'package:json_annotation/json_annotation.dart';
import 'package:tawaq/gen/assets.gen.dart';
import 'package:tawaq/gen/fonts.gen.dart';
/// Available translation sources as an enum with metadata.
///
/// Use this enum instead of strings to reference translations.
/// Add new translations by adding new enum values.
@JsonEnum()
enum TranslationId {
  /// Saheeh International English translation.
  saheehInternational(
    displayName: 'Saheeh International',
    language: 'English',
  ),

  /// Bengali translation.
  bengali(
    displayName: 'Muhiuddin Khan',
    language: 'Bengali',
  ),

  /// Spanish translation.
  spanish(
    displayName: 'Muhammad Isa García',
    language: 'Spanish',
  ),

  /// French translation by Muhammad Hamidullah.
  french(
    displayName: 'Muhammad Hamidullah',
    language: 'French',
  ),

  /// Indonesian translation.
  indonesian(
    displayName: 'DEPAGIS',
    language: 'Indonesian',
  ),

  /// Russian translation by Elmir Kuliev.
  russian(
    displayName: 'Elmir Kuliev',
    language: 'Russian',
  ),

  /// Swedish translation.
  swedish(
    displayName: 'Knut Bernström',
    language: 'Swedish',
  ),

  /// Turkish translation by Diyanet İşleri.
  turkish(
    displayName: 'Diyanet İşleri',
    language: 'Turkish',
  ),

  /// Urdu translation by Fateh Muhammad Jalandhari.
  urdu(
    displayName: 'Fateh Muhammad Jalandhari',
    language: 'Urdu',
  ),

  /// Chinese translation by Ma Jian.
  chinese(
    displayName: 'Ma Jian',
    language: 'Chinese',
  ),
  ;

  const TranslationId({
    required this.displayName,
    required this.language,
  });

  /// Human-readable translator or edition name.
  final String displayName;

  /// Language of the translation.
  final String language;

  /// Asset path to the SQLite database file.
  String get databasePath {
    return switch (this) {
      TranslationId.saheehInternational =>
        Assets.database.saheehInternational,
      TranslationId.bengali => Assets.database.quranBn,
      TranslationId.spanish => Assets.database.quranEs,
      TranslationId.french => Assets.database.quranFr,
      TranslationId.indonesian => Assets.database.quranId,
      TranslationId.russian => Assets.database.quranRu,
      TranslationId.swedish => Assets.database.quranSv,
      TranslationId.turkish => Assets.database.quranTr,
      TranslationId.urdu => Assets.database.quranUr,
      TranslationId.chinese => Assets.database.quranZh,
    };
  }

  /// Font family for rendering this translation's text.
  ///
  /// When null, the UI inherits the theme's default typography.
  String? get fontFamily => switch (this) {
    TranslationId.bengali => FontFamily.notoSansBengali,
    TranslationId.chinese => FontFamily.notoSansSC,
    TranslationId.russian => FontFamily.notoSans,
    TranslationId.urdu => FontFamily.notoNastaliqUrdu,
    _ => null,
  };

  /// Whether the study panel should render this translation in italic.
  ///
  /// Latin-script editions use a quoted italic style; other scripts use upright
  /// glyphs from their dedicated fonts.
  bool get usesItalicQuoteStyle => switch (this) {
    TranslationId.bengali ||
    TranslationId.chinese ||
    TranslationId.russian ||
    TranslationId.urdu => false,
    _ => true,
  };
}
