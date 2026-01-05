import 'package:flutter/material.dart';
import 'package:mushaf_reader/src/core/extensions.dart';
import 'package:mushaf_reader/src/core/fonts.dart';
import 'package:mushaf_reader/src/data/models/mushaf_style.dart'
    show StyleModifier;

/// A widget that displays a Mushaf page number in Hindu-Arabic numerals.
///
/// This widget converts the Western Arabic page number (1-604) to its
/// Hindu-Arabic numeral equivalent (۱-۶۰۴) for authentic Quran typography.
///
/// ## Hindu-Arabic Numerals
///
/// Standard Mushafs use Hindu-Arabic numerals (٠١٢٣٤٥٦٧٨٩) for page
/// numbers and Ayah markers, matching the traditional Arabic script.
///
/// ## Usage
///
/// ```dart
/// PageNumberWidget(page: 1)   // Displays: ۱
/// PageNumberWidget(page: 604) // Displays: ۶۰۴
/// ```
///
/// With custom styling:
///
/// ```dart
/// PageNumberWidget(
///   page: 1,
///   textStyle: TextStyle(
///     color: Colors.brown,
///     fontWeight: FontWeight.bold,
///   ),
/// )
/// ```
///
/// See also:
/// - [IntHinduArabicExtension], which provides the conversion
/// - [MushafFonts.pageNumberStyle], for the styling used
class PageNumberWidget extends StatelessWidget {
  /// The page number to display (1-604).
  ///
  /// Will be converted to Hindu-Arabic numerals for display.
  final int page;

  /// The font size for the page number.
  ///
  /// If not provided, uses the base page number font size (20).
  final double? fontSize;

  /// Custom text style for the page number.
  ///
  /// Properties like [color], [fontWeight], and [decoration] are preserved.
  /// The [fontSize] parameter takes precedence over [textStyle.fontSize].
  final TextStyle? textStyle;

  /// A function to modify the resolved text style.
  ///
  /// Use this for easy customization:
  /// ```dart
  /// PageNumberWidget(
  ///   page: 1,
  ///   styleModifier: (style) => style.copyWith(color: Colors.brown),
  /// )
  /// ```
  final StyleModifier? styleModifier;

  /// Creates a PageNumberWidget.
  const PageNumberWidget({
    super.key,
    required this.page,
    this.fontSize,
    this.textStyle,
    this.styleModifier,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = MushafTextStyleMerger.mergePageNumberStyle(
      userStyle: textStyle,
      modifier: styleModifier,
      baseSize:
          fontSize ?? textStyle?.fontSize ?? MushafBaseFontSizes.pageNumber,
      scaleFactor: 1.0,
    );

    return Text(
      page.toHinduArabic(),
      style: effectiveStyle,
      textAlign: TextAlign.center,
    );
  }
}
