import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mushaf_reader/src/data/models/revelation_type.dart';

part 'surah.freezed.dart';

/// Represents metadata for a Surah (chapter) of the Quran.
///
/// This is a lightweight model containing only Surah identification
/// and display information, without page-specific layout data.
///
/// ## Usage
///
/// Typically obtained from [MushafReaderController.getSurah] or by
/// converting a [SurahBlock] via [SurahConvertor.toSurah]:
///
/// ```dart
/// // Async fetch
/// final surah = await controller.getSurah(1);
/// print('Surah ${surah.number}: ${surah.nameArabic}');
/// print('Revelation: ${surah.revelationType}'); // meccan or medinan
///
/// // From SurahBlock
/// final block = page.surahs.first;
/// final surah = block.toSurah();
/// ```
///
/// See also:
/// - [SurahBlock], which contains page-specific Ayah data
/// - [SurahNameWidget], which displays the Surah name
/// - [SurahHeaderWidget], which displays the decorative banner
@freezed
abstract class Surah with _$Surah {
  /// Creates a [Surah] with all required properties.
  ///
  /// All parameters are required to ensure data integrity when working
  /// with Quran data.
  factory Surah({
    /// The Surah (chapter) number (1-114).
    required int number,

    /// The QCF4-encoded glyph for the Surah name.
    ///
    /// Rendered using [MushafFonts.basmalahFamily] font.
    required String glyph,

    /// Whether this Surah should display the Basmalah.
    ///
    /// `true` for all Surahs except At-Tawbah (Surah 9).
    required bool hasBasmalah,

    /// The Arabic name of the Surah (e.g., "سُورَةُ ٱلْفَاتِحَةِ").
    ///
    /// This is the human-readable Arabic name, distinct from the
    /// QCF4 glyph which is for rendering in the Mushaf font.
    String? nameArabic,

    /// The English transliterated name of the Surah (e.g., "Al-Faatiha").
    String? nameEnglish,

    /// The page number where this Surah begins (1-604).
    int? startPage,

    /// The revelation type of this Surah.
    ///
    /// Indicates whether the Surah was revealed in Mecca or Medina.
    RevelationType? revelationType,

    /// The English translation of the Surah name meaning.
    ///
    /// For example, "The Opening" for Al-Fatiha.
    String? englishNameTranslation,

    /// The total number of Ayahs (verses) in this Surah.
    int? ayahCount,
  }) = _Surah;

  const Surah._();

  /// Returns the display name, preferring Arabic if available, then English.
  String get displayName => nameArabic ?? nameEnglish ?? 'Surah $number';

  /// Returns the Arabic name without diacritics (Imlaei/simplified script).
  ///
  /// Removes tashkeel (harakat) like fatha, damma, kasra, sukun, shadda,
  /// and other Arabic punctuation marks for cleaner display or search.
  ///
  /// Example: "سُورَةُ ٱلْفَاتِحَةِ" → "سورة الفاتحة"
  String? get nameArabicSimplified {
    if (nameArabic == null) return null;
    // Arabic diacritics Unicode range: U+064B to U+0652, plus others
    return nameArabic!.replaceAll(
      RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]'),
      '',
    );
  }
}
