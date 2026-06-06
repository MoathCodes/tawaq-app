import 'package:json_annotation/json_annotation.dart';
import 'package:tawaq/gen/assets.gen.dart';

/// Database layout used by a bundled tafsir SQLite file.
enum TafsirSchema {
  /// Standard schema: `tafseer` table with `sura_no`, `aya_no`, `aya_tafseer`.
  mouaser,

  /// Compact schema: single-letter table with `SURA_num`, `AYA_num`, `Tafsir`.
  compact,
}

/// Available tafsir (commentary) sources as an enum with metadata.
///
/// Use this enum instead of strings to reference tafsirs.
/// Add new tafsirs by adding new enum values.
@JsonEnum()
enum TafsirId {
  /// التفسير الميسر - Arabic tafsir.
  tafseerMouaser(
    arabicName: 'التفسير الميسر',
    englishName: 'Tafsir Al-Muyassar',
    language: 'Arabic',
    schema: TafsirSchema.mouaser,
  ),

  /// تفسير البغوي (معالم التنزيل).
  baghawi(
    arabicName: 'تفسير البغوي',
    englishName: 'Tafsir Al-Baghawi',
    language: 'Arabic',
    schema: TafsirSchema.compact,
    tableName: 'Ba',
  ),

  /// تفسير ابن كثير.
  ibnKathir(
    arabicName: 'تفسير ابن كثير',
    englishName: 'Tafsir Ibn Kathir',
    language: 'Arabic',
    schema: TafsirSchema.compact,
    tableName: 'IK',
  ),

  /// تفسير السعدي.
  asSadi(
    arabicName: 'تفسير السعدي',
    englishName: "Tafsir As-Sa'di",
    language: 'Arabic',
    schema: TafsirSchema.compact,
    tableName: 'AS',
  ),
  ;

  const TafsirId({
    required this.arabicName,
    required this.englishName,
    required this.language,
    required this.schema,
    this.tableName,
  });

  /// Human-readable name (Arabic).
  final String arabicName;

  /// English display name for LTR locales.
  final String englishName;

  /// Language of the tafsir.
  final String language;

  /// SQLite schema variant for this source.
  final TafsirSchema schema;

  /// Table name for [TafsirSchema.compact] databases.
  final String? tableName;

  /// Asset path to the SQLite database file.
  String get databasePath {
    return switch (this) {
      TafsirId.tafseerMouaser => Assets.database.tafseerAr.tafseerMouaser,
      TafsirId.baghawi => Assets.database.tafseerAr.quraanBa,
      TafsirId.ibnKathir => Assets.database.tafseerAr.quraanIK,
      TafsirId.asSadi => Assets.database.tafseerAr.quraanAS,
    };
  }

  /// Localized label for UI display.
  String displayLabel({required bool isArabic}) =>
      isArabic ? arabicName : englishName;
}
