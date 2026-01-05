import 'package:freezed_annotation/freezed_annotation.dart';

part 'ayah_info.freezed.dart';

/// Rich information about an Ayah for use in tap/long-press callbacks.
///
/// This model provides all context a developer needs when handling
/// ayah interaction events, eliminating the need to perform additional
/// lookups after receiving a callback.
///
/// ## Example
///
/// ```dart
/// MushafReader(
///   onAyahTap: (info) {
///     print('Tapped ${info.surahNumber}:${info.verseNumber}');
///     print('Ayah ID: ${info.ayahId}, Page: ${info.page}');
///   },
///   onAyahLongPress: (info) {
///     showContextMenu(
///       ayahRef: '${info.surahNumber}:${info.verseNumber}',
///     );
///   },
/// )
/// ```
///
/// See also:
/// - [AyahModel], the full ayah data model with glyph text
/// - [MushafReader], the convenience widget that uses this in callbacks
@freezed
abstract class AyahInfo with _$AyahInfo {
  /// Creates an [AyahInfo] with all context about the ayah.
  factory AyahInfo({
    /// The global unique identifier for this Ayah (1-6236).
    required int ayahId,

    /// The Surah (chapter) number (1-114).
    required int surahNumber,

    /// The verse number within the Surah.
    required int verseNumber,

    /// The Mushaf page number where this Ayah appears (1-604).
    required int page,

    /// The Juz (part) number this Ayah belongs to (1-30).
    required int juz,
  }) = _AyahInfo;

  const AyahInfo._();

  /// Returns a formatted reference string like "2:255" (Al-Baqarah, Ayat Al-Kursi).
  String get reference => '$surahNumber:$verseNumber';
}
