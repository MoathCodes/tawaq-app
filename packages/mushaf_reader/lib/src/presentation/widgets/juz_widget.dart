import 'package:flutter/material.dart';
import 'package:mushaf_reader/src/core/fonts.dart';
import 'package:mushaf_reader/src/data/models/juz_model.dart';
import 'package:mushaf_reader/src/data/models/mushaf_style.dart'
    show StyleModifier;
import 'package:mushaf_reader/src/data/repository/hive_quran_repo.dart';

/// A widget that displays the Juz (part) glyph marker.
///
/// The Quran is divided into 30 Juzs for ease of reading. This widget
/// displays the decorative glyph marker for a specific Juz, typically
/// shown in the page header.
///
/// ## Usage
///
/// ```dart
/// JuzWidget(number: 1) // Displays Juz 1 marker
/// ```
///
/// With pre-loaded data (for better performance):
///
/// ```dart
/// JuzWidget(number: 15, juzData: cachedJuz)
/// ```
///
/// With custom styling:
///
/// ```dart
/// JuzWidget(
///   number: 15,
///   textStyle: TextStyle(
///     fontSize: 18,
///     color: Colors.green,
///   ),
/// )
/// ```
///
/// ## Behavior
///
/// - Returns [SizedBox.shrink] if the Juz data is not available
/// - Automatically uses the Basmalah font family (QCF4_BSML)
/// - Text is displayed right-to-left
///
/// See also:
/// - [MushafPage], which displays the Juz widget in the header
/// - [JuzModel], the data model for Juz information
class JuzWidget extends StatelessWidget {
  /// The Juz number to display (1-30).
  final int number;

  /// The font size for the Juz glyph.
  ///
  /// If not provided, uses 40 (approximately 2x the base Basmalah size).
  final double? fontSize;

  /// Custom text style for the Juz glyph.
  ///
  /// The [TextStyle.fontFamily] will be overridden with [MushafFonts.basmalahFamily].
  /// Other properties like [fontSize] and [color] are preserved.
  final TextStyle? textStyle;

  /// A function to modify the resolved text style.
  ///
  /// Use this for easy customization:
  /// ```dart
  /// JuzWidget(
  ///   number: 1,
  ///   styleModifier: (style) => style.copyWith(color: Colors.green),
  /// )
  /// ```
  final StyleModifier? styleModifier;

  /// Callback invoked when the Juz glyph is tapped.
  ///
  /// Receives the Juz number (1-30).
  final void Function(int juzNumber)? onTap;

  /// Callback invoked when the Juz glyph is long-pressed.
  ///
  /// Receives the Juz number (1-30).
  final void Function(int juzNumber)? onLongPress;

  /// Pre-loaded Juz data for better performance.
  ///
  /// If provided, this is used directly. Otherwise, the widget loads
  /// the data from the repository.
  final JuzModel? juzData;

  /// Creates a JuzWidget for the specified Juz number.
  ///
  /// [number] must be in the range 1-30.
  const JuzWidget({
    super.key,
    required this.number,
    this.fontSize,
    this.textStyle,
    this.styleModifier,
    this.onTap,
    this.onLongPress,
    this.juzData,
  });

  @override
  Widget build(BuildContext context) {
    // If data provided, use it directly
    if (juzData != null) {
      return _buildContent(juzData!);
    }

    // Try to get from repository cache
    final cachedJuz = HiveQuranRepository().getJuzSync(number);
    if (cachedJuz != null) {
      return _buildContent(cachedJuz);
    }

    // Fallback: load asynchronously
    return FutureBuilder<JuzModel?>(
      future: HiveQuranRepository().getJuz(number),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return _buildContent(snapshot.data!);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildContent(JuzModel juz) {
    // fontSize priority: fontSize param → textStyle.fontSize → 40.0
    final effectiveFontSize = fontSize ?? textStyle?.fontSize ?? 40.0;
    final effectiveStyle = MushafTextStyleMerger.mergeBasmalahStyle(
      userStyle: textStyle,
      modifier: styleModifier,
      baseSize: effectiveFontSize,
      scaleFactor: 1.0,
    );

    return onTap != null || onLongPress != null
        ? GestureDetector(
            onTap: () => onTap?.call(number),
            onLongPress: () => onLongPress?.call(number),
            child: Text(
              juz.codeV4,
              textDirection: TextDirection.rtl,
              style: effectiveStyle,
            ),
          )
        : Text(
            juz.codeV4,
            textDirection: TextDirection.rtl,
            style: effectiveStyle,
          );
  }
}
