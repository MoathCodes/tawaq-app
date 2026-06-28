import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Renders a Juz QCF4 glyph using the mushaf basmalah font.
class JuzNameText extends StatelessWidget {
  /// Creates a [JuzNameText].
  const JuzNameText(
    this.glyph, {
    this.style,
    this.fontSize = 36,
    super.key,
  });

  /// QCF4-encoded Juz marker glyph.
  final String glyph;

  /// Optional base style; [fontSize] overrides size when set.
  final TextStyle? style;

  /// Glyph size in logical pixels.
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        glyph,
        textDirection: TextDirection.rtl,
        style: (style ?? const TextStyle()).copyWith(
          fontFamily: 'QCF4_BSML',
          package: 'mushaf_reader',
          fontSize: fontSize,
        ),
      ),
    );
  }
}

/// Renders a Surah QCF4 name glyph for Arabic Juz subtitles.
class SurahGlyphText extends StatelessWidget {
  /// Creates a [SurahGlyphText].
  const SurahGlyphText(
    this.glyph, {
    this.style,
    this.fontSize = 28,
    super.key,
  });

  /// QCF4-encoded surah name glyph.
  final String glyph;

  /// Optional base style.
  final TextStyle? style;

  /// Glyph size in logical pixels.
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        glyph,
        textDirection: TextDirection.rtl,
        style: (style ?? const TextStyle()).copyWith(
          fontFamily: 'QCF4_BSML',
          package: 'mushaf_reader',
          fontSize: fontSize,
        ),
      ),
    );
  }
}
