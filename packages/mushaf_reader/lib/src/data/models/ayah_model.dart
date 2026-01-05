import 'package:freezed_annotation/freezed_annotation.dart';

part 'ayah_model.freezed.dart';

/// Represents a single Ayah (verse) from the Holy Quran.
///
/// This model contains all the metadata and glyph text needed to display
/// an Ayah using the QCF4 (Quran Complex Fonts) encoding.
///
/// ## Properties
///
/// - [id]: Global unique identifier for the Ayah (1-6236)
/// - [juz]: The Juz (part) number this Ayah belongs to (1-30)
/// - [page]: The Mushaf page number where this Ayah appears (1-604)
/// - [surah]: The Surah (chapter) number (1-114)
/// - [numberInSurah]: The Ayah number within its Surah
/// - [text]: The QCF4-encoded glyph text for rendering
///
/// ## Example
///
/// ```dart
/// final ayah = AyahModel(
///   id: 1,
///   juz: 1,
///   page: 1,
///   surah: 1,
///   numberInSurah: 1,
///   text: '...',
/// );
///
/// print('Surah ${ayah.surah}, Ayah ${ayah.numberInSurah}');
/// ```
@freezed
abstract class AyahModel with _$AyahModel {
  /// Creates an [AyahModel] with all required properties.
  ///
  /// All parameters are required to ensure data integrity when working
  /// with Quran data.
  factory AyahModel({
    /// The global unique identifier for this Ayah (1-6236).
    ///
    /// This ID is sequential across the entire Quran, starting from
    /// Al-Fatiha verse 1 (id=1) to An-Nas verse 6 (id=6236).
    required int id,

    /// The Juz (part) number this Ayah belongs to (1-30).
    ///
    /// The Quran is divided into 30 Juzs of roughly equal length
    /// for ease of reading over a month.
    required int juz,

    /// The Mushaf page number where this Ayah appears (1-604).
    ///
    /// Based on the Madinah Mushaf printing standard.
    required int page,

    /// The Surah (chapter) number this Ayah belongs to (1-114).
    required int surah,

    /// The Ayah number within its Surah.
    ///
    /// Starts from 1 for each Surah. The Basmalah at the beginning
    /// of each Surah (except Al-Tawbah) is not counted as an Ayah,
    /// except in Al-Fatiha where it is Ayah 1.
    required int numberInSurah,

    /// The QCF4-encoded glyph text for this Ayah.
    ///
    /// This text uses special Unicode Private Use Area characters
    /// that map to glyphs in the QCF4 page-specific fonts.
    required String text,
  }) = _AyahModel;

  const AyahModel._();

  /// Returns the QCF4 glyph text for rendering with the appropriate font.
  ///
  /// This is an alias for [text] for semantic clarity when working
  /// with font rendering code.
  String get codeV4 => text;
}
