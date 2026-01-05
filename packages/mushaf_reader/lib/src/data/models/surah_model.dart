import 'package:freezed_annotation/freezed_annotation.dart';

part 'surah_model.freezed.dart';

/// Represents metadata for a Surah (chapter) of the Quran.
///
/// This is a lightweight model containing only Surah identification
/// and display information, without page-specific layout data.
///
/// ## Usage
///
/// Typically obtained from [MushafReaderController.getSurah] or by
/// converting a [SurahBlock] via [SurahConvertor.toSurahModel]:
///
/// ```dart
/// // Async fetch
/// final surah = await controller.getSurah(1);
/// print('Surah ${surah.number}: ${surah.nameArabic}');
///
/// // From SurahBlock
/// final block = page.surahs.first;
/// final surahModel = block.toSurahModel();
/// ```
///
/// See also:
/// - [SurahBlock], which contains page-specific Ayah data
/// - [SurahNameWidget], which displays the Surah name
/// - [SurahHeaderWidget], which displays the decorative banner
@freezed
abstract class SurahModel with _$SurahModel {
  /// Creates a [SurahModel] with all required properties.
  ///
  /// All parameters are required to ensure data integrity when working
  /// with Quran data.
  factory SurahModel({
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
  }) = _SurahModel;

  const SurahModel._();

  /// Returns the display name, preferring Arabic if available, then English.
  String get displayName => nameArabic ?? nameEnglish ?? 'Surah $number';
}
