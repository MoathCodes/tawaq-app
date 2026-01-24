import 'package:flutter/material.dart';

/// Widget that renders tafsir text with proper font styling.
///
/// The tafsir text contains HTML-like span tags to distinguish between
/// the Quranic ayah text (Uthmanic Hafs font) and commentary (Naskh font).
class TafsirText extends StatelessWidget {
  /// Creates a tafsir text widget.
  const TafsirText({
    required this.text,
    required this.baseStyle,
    super.key,
  });

  /// The raw tafsir text containing potential span tags.
  final String text;

  /// The base text style for the tafsir commentary.
  final TextStyle baseStyle;

  /// Font family for tafsir/commentary text (Naskh style).
  static const String tafsirFontFamily = 'UthmanTN';

  /// Font family for Quranic ayah text (Uthmanic Hafs style).
  static const String ayahFontFamily = 'UthmanicHafs';

  @override
  Widget build(BuildContext context) {
    final spans = _parseText(text);

    return RichText(
      textDirection: TextDirection.rtl,
      text: TextSpan(
        children: spans.map((segment) {
          if (segment.isAyah) {
            // Quranic text - use Uthmanic Hafs font
            return TextSpan(
              text: segment.text,
              style: baseStyle.copyWith(
                fontFamily: ayahFontFamily,
                fontWeight: FontWeight.w400,
                color: baseStyle.color?.withAlpha(230),
              ),
            );
          } else {
            // Commentary text - use Uthman TN Naskh font
            return TextSpan(
              text: segment.text,
              style: baseStyle.copyWith(
                fontFamily: tafsirFontFamily,
                fontWeight: FontWeight.w400,
              ),
            );
          }
        }).toList(),
      ),
    );
  }

  /// Parses the tafsir text and extracts segments.
  List<_TextSegment> _parseText(String rawText) {
    final segments = <_TextSegment>[];

    // Match span tags with class 'aya' - both single and double quotes
    final pattern = RegExp(
      '<span\\s+class=["\']aya["\']>(.*?)</span>',
      caseSensitive: false,
      dotAll: true,
    );

    var lastEnd = 0;

    for (final match in pattern.allMatches(rawText)) {
      // Add text before the match (commentary)
      if (match.start > lastEnd) {
        final beforeText = rawText.substring(lastEnd, match.start).trim();
        if (beforeText.isNotEmpty) {
          segments.add(_TextSegment(beforeText, isAyah: false));
        }
      }

      // Add the ayah text
      final ayahText = match.group(1)?.trim() ?? '';
      if (ayahText.isNotEmpty) {
        segments.add(_TextSegment(ayahText, isAyah: true));
      }

      lastEnd = match.end;
    }

    // Add remaining text after last match (commentary)
    if (lastEnd < rawText.length) {
      final afterText = rawText.substring(lastEnd).trim();
      if (afterText.isNotEmpty) {
        segments.add(_TextSegment(afterText, isAyah: false));
      }
    }

    // If no matches found, return the whole text as commentary
    if (segments.isEmpty) {
      segments.add(_TextSegment(rawText.trim(), isAyah: false));
    }

    return segments;
  }
}

/// A segment of parsed tafsir text.
class _TextSegment {
  const _TextSegment(this.text, {required this.isAyah});
  final String text;
  final bool isAyah;
}
