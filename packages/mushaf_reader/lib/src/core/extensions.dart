import 'package:mushaf_reader/src/data/models/surah.dart';
import 'package:mushaf_reader/src/data/models/surah_block.dart';

/// Extension on [int] to convert to Hindu-Arabic (Eastern Arabic) numerals.
///
/// Standard Mushafs use Hindu-Arabic numerals (٠١٢٣٤٥٦٧٨٩) for:
/// - Page numbers
/// - Ayah markers
/// - Juz numbers
///
/// ## Character Mapping
///
/// | Western | Hindu-Arabic |
/// |---------|-------------|
/// | 0       | ٠ (U+0660) |
/// | 1       | ١ (U+0661) |
/// | 2       | ٢ (U+0662) |
/// | 3       | ٣ (U+0663) |
/// | 4       | ٤ (U+0664) |
/// | 5       | ٥ (U+0665) |
/// | 6       | ٦ (U+0666) |
/// | 7       | ٧ (U+0667) |
/// | 8       | ٨ (U+0668) |
/// | 9       | ٩ (U+0669) |
///
/// ## Usage
///
/// ```dart
/// 123.toHinduArabic() // Returns '١٢٣'
/// 604.toHinduArabic() // Returns '٦٠٤'
/// ```
///
/// See also:
/// - [PageNumberWidget], which uses this for page display
extension IntHinduArabicExtension on int {
  /// Converts this integer to Hindu-Arabic numeral string.
  ///
  /// Returns a string with all digits replaced by their
  /// Hindu-Arabic equivalents (٠١٢٣٤٥٦٧٨٩).
  String toHinduArabic() {
    return toString()
        .replaceAll('0', '٠')
        .replaceAll('1', '١')
        .replaceAll('2', '٢')
        .replaceAll('3', '٣')
        .replaceAll('4', '٤')
        .replaceAll('5', '٥')
        .replaceAll('6', '٦')
        .replaceAll('7', '٧')
        .replaceAll('8', '٨')
        .replaceAll('9', '٩');
  }
}

/// Extension to convert [SurahBlock] to [Surah].
///
/// Used by presentation widgets that need Surah metadata
/// without the page-specific Ayah fragment data.
///
/// See also:
/// - [SurahBlock], the source model with page layout data
/// - [Surah], the simplified Surah metadata model
extension SurahConvertor on SurahBlock {
  /// Converts this [SurahBlock] to a [Surah].
  ///
  /// Extracts the Surah metadata (number, glyph, hasBasmalah)
  /// from the page-specific block data.
  Surah toSurah() {
    return Surah(number: surahNumber, glyph: glyph, hasBasmalah: hasBasmalah);
  }
}
