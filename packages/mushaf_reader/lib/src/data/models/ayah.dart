import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mushaf_reader/src/core/hizb_quarter.dart';
import 'package:mushaf_reader/src/data/ayah_id_resolver.dart';
import 'package:mushaf_reader/src/data/models/surah.dart';

part 'ayah.freezed.dart';

/// Represents a single Ayah (verse) from the Holy Quran.
///
/// This model contains all the metadata and glyph text needed to display
/// an Ayah using the QCF4 (Quran Complex Fonts) encoding, as well as
/// context information for callbacks and navigation.
///
/// ## Properties
///
/// - [ayahId]: Global unique identifier for the Ayah (1-6236)
/// - [juz]: The Juz (part) number this Ayah belongs to (1-30)
/// - [page]: The Mushaf page number where this Ayah appears (1-604)
/// - [surahNumber]: The Surah (chapter) number (1-114)
/// - [numberInSurah]: The Ayah number within its Surah
/// - [text]: The QCF4-encoded glyph text for rendering
/// - [textPlain]: Plain Arabic text without tajweed marks
/// - [manzil]: The Manzil number (1-7, dividing Quran for weekly reading)
/// - [ruku]: The Ruku (section) number for prayer divisions
/// - [hizbQuarter]: The Hizb quarter number (1-240)
/// - [sajda]: Whether this Ayah contains a prostration (Sajdah)
/// - [pageInSurah]: The page number within the Surah
///
/// ## Example
///
/// ```dart
/// final ayah = Ayah(
///   ayahId: 1,
///   juz: 1,
///   page: 1,
///   surahNumber: 1,
///   numberInSurah: 1,
///   text: '...',
/// );
///
/// print('Surah ${ayah.surahNumber}, Ayah ${ayah.numberInSurah}');
/// print('Reference: ${ayah.reference}'); // "1:1"
/// if (ayah.sajda == true) print('This ayah has a sajdah');
/// ```
@freezed
abstract class Ayah with _$Ayah {
  /// Creates an [Ayah] with all required properties.
  ///
  /// All parameters are required to ensure data integrity when working
  /// with Quran data.
  factory Ayah({
    /// The global unique identifier for this Ayah (1-6236).
    ///
    /// This ID is sequential across the entire Quran, starting from
    /// Al-Fatiha verse 1 (ayahId=1) to An-Nas verse 6 (ayahId=6236).
    required int ayahId,

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
    required int surahNumber,

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

    /// Plain Arabic text without tajweed marks (Imlaei script).
    ///
    /// Useful for text-to-speech, search, and accessibility features.
    String? textPlain,

    /// The Manzil number this Ayah belongs to (1-7).
    ///
    /// The Quran is divided into 7 Manzils for weekly reading,
    /// completing the entire Quran in one week.
    int? manzil,

    /// The Ruku (section) number for this Ayah.
    ///
    /// Rukus are thematic sections used in some traditions to
    /// organize recitation during prayers.
    int? ruku,

    /// The Hizb quarter number (1-240).
    ///
    /// Each Juz is divided into 2 Hizbs, and each Hizb into 4 quarters,
    /// giving 240 quarters for detailed progress tracking.
    int? hizbQuarter,

    /// Whether this Ayah contains a Sajdah (prostration).
    ///
    /// There are 15 Sajdah verses in the Quran where prostration
    /// is recommended upon recitation.
    bool? sajda,

    /// The page number within the Surah (1-indexed).
    ///
    /// Useful for tracking progress within a Surah.
    int? pageInSurah,
  }) = _Ayah;

  const Ayah._();

  /// Hizb number (1–60) derived from [hizbQuarter].
  int? get hizb =>
      hizbQuarter == null ? null : hizbNumberFromQuarter(hizbQuarter!);

  /// Quarter within the hizb (1–4) derived from [hizbQuarter].
  int? get quarterInHizb =>
      hizbQuarter == null ? null : quarterInHizbFromQuarter(hizbQuarter!);

  /// Resolves a surah/verse pair to the global ayah id (1–6236) without I/O.
  ///
  /// Uses the standard Hafs verse-count table. Returns `null` when [surah] or
  /// [ayahInSurah] is out of range. Prefer this over [AyahIdResolver.globalId]
  /// when you do not have surah metadata from storage.
  static int? globalIdFor({
    required int surah,
    required int ayahInSurah,
  }) {
    final starts = AyahIdResolver.buildStarts(const {});
    return AyahIdResolver.globalId(
      surah: surah,
      ayahInSurah: ayahInSurah,
      startsBySurah: starts,
    );
  }

  /// Returns the QCF4 glyph text for rendering with the appropriate font.
  ///
  /// This is an alias for [text] for semantic clarity when working
  /// with font rendering code.
  String get codeV4 => text;

  /// Returns a compact numeric reference string like "2:255".
  ///
  /// Prefer [referenceWithSurahName] for user-facing labels.
  String get reference => '$surahNumber:$numberInSurah';

  /// Returns a human-readable reference with the surah name and ayah number.
  ///
  /// Example (English): "Al-Baqara 255"
  /// Example (Arabic): "سُورَةُ ٱلْبَقَرَةِ 255"
  String referenceWithSurahName(Surah surah, {bool preferArabic = true}) {
    final name = preferArabic
        ? (surah.nameArabic ?? surah.nameEnglish ?? 'Surah ${surah.number}')
        : (surah.nameEnglish ?? surah.nameArabic ?? 'Surah ${surah.number}');
    return '$name $numberInSurah';
  }

  /// Sanitizes a reference string for safe use in filenames.
  static String sanitizeReferenceForFilename(String reference) {
    return reference
        .replaceAll(RegExp(r'[<>:"/\\|?*•]'), '-')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }
}
