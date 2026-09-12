import 'package:json_annotation/json_annotation.dart';
import 'package:tawaq/gen/assets.gen.dart';
import 'package:tawaq/gen/fonts.gen.dart';

/// Available translation sources as an enum with metadata.
///
/// Use this enum instead of strings to reference translations.
/// Add new translations by adding new enum values.
enum TranslationDirection {
  /// Languages whose text flows from left to right.
  ltr,

  /// Languages whose text flows from right to left.
  rtl,
}

@JsonEnum()
enum TranslationId {
  /// Saheeh International English translation.
  saheehInternational(
    displayName: 'Saheeh International',
    language: 'English',
    languageCode: 'en',
    direction: TranslationDirection.ltr,
  ),

  /// Bengali translation.
  bengali(
    displayName: 'Muhiuddin Khan',
    language: 'Bengali',
    languageCode: 'bn',
    direction: TranslationDirection.ltr,
  ),

  /// Spanish translation.
  spanish(
    displayName: 'Muhammad Isa García',
    language: 'Spanish',
    languageCode: 'es',
    direction: TranslationDirection.ltr,
  ),

  /// French translation by Muhammad Hamidullah.
  french(
    displayName: 'Muhammad Hamidullah',
    language: 'French',
    languageCode: 'fr',
    direction: TranslationDirection.ltr,
  ),

  /// Indonesian translation.
  indonesian(
    displayName: 'DEPAGIS',
    language: 'Indonesian',
    languageCode: 'id',
    direction: TranslationDirection.ltr,
  ),

  /// Russian translation by Elmir Kuliev.
  russian(
    displayName: 'Elmir Kuliev',
    language: 'Russian',
    languageCode: 'ru',
    direction: TranslationDirection.ltr,
  ),

  /// Swedish translation.
  swedish(
    displayName: 'Knut Bernström',
    language: 'Swedish',
    languageCode: 'sv',
    direction: TranslationDirection.ltr,
  ),

  /// Turkish translation by Diyanet İşleri.
  turkish(
    displayName: 'Diyanet İşleri',
    language: 'Turkish',
    languageCode: 'tr',
    direction: TranslationDirection.ltr,
  ),

  /// Urdu translation by Fateh Muhammad Jalandhari.
  urdu(
    displayName: 'Fateh Muhammad Jalandhari',
    language: 'Urdu',
    languageCode: 'ur',
    direction: TranslationDirection.rtl,
  ),

  /// Chinese translation by Ma Jian.
  chinese(
    displayName: 'Ma Jian',
    language: 'Chinese',
    languageCode: 'zh',
    direction: TranslationDirection.ltr,
  );

  new({
    required this.displayName,
    required this.language,
    required this.languageCode,
    required this.direction,
  });

  /// Human-readable translator or edition name.
  final String displayName;

  /// Language of the translation.
  final String language;

  /// BCP-47 language tag for the bundled edition.
  final String languageCode;

  /// Reading direction for the translation's source language.
  final TranslationDirection direction;

  /// Asset path to the SQLite database file.
  String get databasePath {
    return switch (this) {
      TranslationId.saheehInternational => Assets.database.saheehInternational,
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
}

/// Default bundled translation source.
const TranslationId kDefaultTranslationId = TranslationId.saheehInternational;
