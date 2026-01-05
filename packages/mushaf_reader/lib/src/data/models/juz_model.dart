import 'package:freezed_annotation/freezed_annotation.dart';

part 'juz_model.freezed.dart';

/// Represents a Juz (part) of the Holy Quran.
///
/// The Quran is traditionally divided into 30 Juzs of roughly equal length
/// to facilitate reading the entire Quran over a month (one Juz per day).
///
/// Each Juz has a decorative glyph marker that can be displayed in the
/// Mushaf header to indicate the current Juz.
///
/// ## Example
///
/// ```dart
/// // Get Juz information
/// final juz = await MushafController.instance.getJuz(1);
/// print('Juz ${juz.number}');
///
/// // Synchronous access (after init)
/// final juzSync = MushafController.instance.getJuzSync(1);
/// ```
///
/// See also:
/// - [JuzWidget], which displays the Juz glyph
/// - [MushafController], for retrieving Juz data
@freezed
abstract class JuzModel with _$JuzModel {
  /// Creates a [JuzModel] with the Juz number and display glyph.
  factory JuzModel({
    /// The Juz number (1-30).
    ///
    /// Juz 1 starts with Al-Fatiha, and Juz 30 ends with An-Nas.
    required int number,

    /// The QCF4-encoded glyph for displaying the Juz marker.
    ///
    /// This glyph should be rendered using the Basmalah font family
    /// (QCF4_BSML) for correct display.
    required String glyph,
  }) = _JuzModel;

  const JuzModel._();

  /// Returns the QCF4 glyph text for the Juz marker.
  ///
  /// Alias for [glyph] for consistency with other model classes.
  String get codeV4 => glyph;
}
