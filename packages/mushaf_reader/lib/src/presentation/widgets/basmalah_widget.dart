import 'package:flutter/material.dart';
import 'package:mushaf_reader/src/core/fonts.dart';
import 'package:mushaf_reader/src/data/models/mushaf_style.dart'
    show StyleModifier;
import 'package:mushaf_reader/src/data/repository/hive_quran_repo.dart';

/// A widget that displays the Basmalah (بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ).
///
/// This widget renders "In the name of Allah, the Most Gracious, the Most
/// Merciful" in decorative QCF4 glyph form. It's typically displayed at the
/// beginning of each Surah (except At-Tawbah).
///
/// ## Usage
///
/// ```dart
/// BasmalahWidget()
/// ```
///
/// With a pre-loaded glyph (for better performance):
///
/// ```dart
/// BasmalahWidget(glyph: cachedBasmalah)
/// ```
///
/// With custom styling:
///
/// ```dart
/// BasmalahWidget(
///   textStyle: TextStyle(
///     fontSize: 24,
///     color: Colors.brown,
///   ),
/// )
/// ```
///
/// ## Behavior
///
/// - Returns [SizedBox.shrink] if the Basmalah glyph is not available
/// - Automatically uses the Basmalah font family (QCF4_BSML)
/// - Text is centered and displayed right-to-left
///
/// See also:
/// - [SurahHeaderWidget], which is typically shown with the Basmalah
/// - [MushafPage], which handles Basmalah display logic
/// - [MushafFonts], for font constants
class BasmalahWidget extends StatelessWidget {
  /// The font size for the Basmalah text.
  ///
  /// If not provided, uses the base Basmalah font size (21).
  final double? fontSize;

  /// Custom text style for the Basmalah.
  ///
  /// The [TextStyle.fontFamily] will be overridden with [MushafFonts.basmalahFamily].
  /// Other properties like [fontSize] and [color] are preserved.
  final TextStyle? textStyle;

  /// A function to modify the resolved text style.
  ///
  /// Use this for easy customization:
  /// ```dart
  /// BasmalahWidget(
  ///   styleModifier: (style) => style.copyWith(color: Colors.brown),
  /// )
  /// ```
  final StyleModifier? styleModifier;

  /// The pre-loaded Basmalah glyph.
  ///
  /// If provided, this is used directly. Otherwise, the widget loads
  /// the glyph from the repository.
  final String? glyph;

  /// Creates a BasmalahWidget.
  ///
  /// [fontSize] and [textStyle] optionally customize the text appearance.
  /// [glyph] can be provided if you have pre-loaded the basmalah glyph.
  const BasmalahWidget({
    super.key,
    this.fontSize,
    this.textStyle,
    this.styleModifier,
    this.glyph,
  });

  @override
  Widget build(BuildContext context) {
    // If glyph provided, use it directly
    if (glyph != null && glyph!.isNotEmpty) {
      return _buildText(glyph!);
    }

    // Try to get from repository cache
    final cachedGlyph = HiveQuranRepository().getBasmalahSync();
    if (cachedGlyph != null && cachedGlyph.isNotEmpty) {
      return _buildText(cachedGlyph);
    }

    // Fallback: load asynchronously
    return FutureBuilder<String?>(
      future: HiveQuranRepository().getBasmalah(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          return _buildText(snapshot.data!);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildText(String glyphText) {
    final effectiveStyle = MushafTextStyleMerger.mergeBasmalahStyle(
      userStyle: textStyle,
      modifier: styleModifier,
      baseSize: fontSize ?? textStyle?.fontSize ?? MushafBaseFontSizes.basmalah,
      scaleFactor: 1.0,
    );

    return Text(
      glyphText,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
      style: effectiveStyle,
    );
  }
}
