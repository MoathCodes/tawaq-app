import 'package:flutter/material.dart';

/// A function that modifies a [TextStyle] and returns a new [TextStyle].
///
/// Used to customize default styles by applying modifications on top of them.
/// This is the easiest way to customize styles while preserving defaults.
///
/// ## Example
///
/// ```dart
/// // Simple color change
/// StyleModifier colorModifier = (style) => style.copyWith(color: Colors.brown);
///
/// // Multiple modifications
/// StyleModifier multiModifier = (style) => style.copyWith(
///   color: Colors.green,
///   fontWeight: FontWeight.bold,
///   shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
/// );
/// ```
///
/// See also:
/// - [MushafStyle], which uses this for style customization
typedef StyleModifier = TextStyle Function(TextStyle defaultStyle);

/// Scaling configuration for the Mushaf reader.
///
/// Controls how text and elements scale based on available screen space.
/// Use this to ensure readable text on all screen sizes, from phones to tablets.
///
/// ## Auto Scaling (Default)
///
/// By default, the Mushaf uses the available width to calculate an optimal
/// scale factor. The reference width is 500 logical pixels.
///
/// ## Custom Scale Factor
///
/// Override auto-scaling with a fixed multiplier:
///
/// ```dart
/// MushafScale(factor: 1.2) // 20% larger than default
/// MushafScale(factor: 0.8) // 20% smaller than default
/// ```
///
/// ## Fixed Font Sizes
///
/// For complete control, specify exact font sizes:
///
/// ```dart
/// MushafScale(
///   ayahFontSize: 24,
///   basmalahFontSize: 18,
///   pageNumberFontSize: 16,
/// )
/// ```
///
/// ## Constraints
///
/// Limit scaling to a range:
///
/// ```dart
/// MushafScale(
///   minScale: 0.6,  // Don't go smaller than 60%
///   maxScale: 1.5,  // Don't go larger than 150%
/// )
/// ```
class MushafScale {
  /// Fixed scale factor. If provided, auto-scaling is disabled.
  final double? factor;

  /// Fixed font size for Ayah text. Overrides scaling for this element.
  final double? ayahFontSize;

  /// Fixed font size for Basmalah text. Overrides scaling for this element.
  final double? basmalahFontSize;

  /// Fixed font size for page numbers. Overrides scaling for this element.
  final double? pageNumberFontSize;

  /// Minimum scale factor when auto-scaling. Defaults to 0.5.
  final double minScale;

  /// Maximum scale factor when auto-scaling. Defaults to 2.0.
  final double maxScale;

  /// Reference width for scale calculations. Defaults to 500.
  final double referenceWidth;

  const MushafScale({
    this.factor,
    this.ayahFontSize,
    this.basmalahFontSize,
    this.pageNumberFontSize,
    this.minScale = 0.5,
    this.maxScale = 2.0,
    this.referenceWidth = 500.0,
  });

  /// Gets the effective Ayah font size for a given scale.
  double getAyahFontSize(double scale) {
    if (ayahFontSize != null) return ayahFontSize!;
    return 28.0 * scale; // Base size is 28
  }

  /// Gets the effective Basmalah font size for a given scale.
  double getBasmalahFontSize(double scale) {
    if (basmalahFontSize != null) return basmalahFontSize!;
    return 21.0 * scale; // Base size is 21
  }

  /// Gets the effective page number font size for a given scale.
  double getPageNumberFontSize(double scale) {
    if (pageNumberFontSize != null) return pageNumberFontSize!;
    return 20.0 * scale; // Base size is 20
  }

  /// Calculates the effective scale factor for a given width.
  double scaleForWidth(double availableWidth) {
    if (factor != null) return factor!.clamp(minScale, maxScale);
    return (availableWidth / referenceWidth).clamp(minScale, maxScale);
  }
}

/// Styling options for customizing the Mushaf reader appearance.
///
/// This class provides configuration options for visual aspects of
/// the Mushaf display, including text styles, scaling, and colors.
///
/// ## Text Style Customization
///
/// You can customize the appearance of various text elements while the
/// library ensures correct font rendering. The following properties are
/// preserved from your [TextStyle]:
///
/// - `color`, `backgroundColor`
/// - `fontWeight`, `fontStyle`
/// - `letterSpacing`, `wordSpacing`
/// - `height` (line height)
/// - `decoration`, `decorationColor`, `decorationStyle`, `decorationThickness`
/// - `shadows`, `fontFeatures`, `fontVariations`
///
/// **Note:** The `fontFamily` and `package` properties are always overridden
/// to ensure correct QCF4 font rendering.
///
/// ## Example
///
/// ```dart
/// MushafPage(
///   page: 1,
///   style: MushafStyle(
///     // Custom text colors
///     ayahStyle: TextStyle(color: Color(0xFF1B4332)),
///     activeAyahStyle: TextStyle(
///       color: Colors.white,
///       backgroundColor: Color(0xFF2D6A4F),
///     ),
///     basmalahStyle: TextStyle(color: Color(0xFF40916C)),
///     surahNameStyle: TextStyle(color: Color(0xFF52B788)),
///     juzStyle: TextStyle(color: Color(0xFF74C69D)),
///     pageNumberStyle: TextStyle(color: Color(0xFF95D5B2)),
///
///     // Background and scaling
///     backgroundColor: Color(0xFFFFFBF0),
///     scale: MushafScale(minScale: 0.7, maxScale: 1.5),
///   ),
/// )
/// ```
///
/// See also:
/// - [MushafPage], which uses this style for rendering
/// - [MushafScale], for detailed scaling control
/// - [MushafPageController], for controlling Ayah selection
class MushafStyle {
  /// The text style applied to Ayah text content.
  ///
  /// Customize color, weight, decoration, etc. The `fontFamily` and `package`
  /// are always overridden with the appropriate page-specific QCF4 font.
  ///
  /// If null, default styling is used (black text, 1.6 line height).
  final TextStyle? ayahStyle;

  /// The text style applied to the currently selected/highlighted Ayah.
  ///
  /// When an Ayah is selected (via tap or programmatically), this style
  /// is applied to distinguish it from other Ayahs. If null, the default
  /// style with [highlightColor] as background is used.
  ///
  /// The `fontFamily` and `package` are always overridden with the
  /// appropriate page-specific QCF4 font.
  final TextStyle? activeAyahStyle;

  /// The text style applied to Basmalah (Bismillah) text.
  ///
  /// Uses the shared QCF4_BSML font. Customize color, weight, etc.
  /// The `fontFamily` and `package` are always overridden.
  final TextStyle? basmalahStyle;

  /// The text style applied to Surah name text in headers.
  ///
  /// Uses the shared QCF4_BSML font. Customize color, weight, etc.
  /// The `fontFamily` and `package` are always overridden.
  final TextStyle? surahNameStyle;

  /// The text style applied to Juz number indicators.
  ///
  /// Uses the shared QCF4_BSML font. Customize color, weight, etc.
  /// The `fontFamily` and `package` are always overridden.
  final TextStyle? juzStyle;

  /// The text style applied to page numbers.
  ///
  /// Customize color, weight, decoration, etc.
  /// Note: Page numbers use standard numerals, not QCF4 fonts.
  final TextStyle? pageNumberStyle;

  /// A function to modify the default Ayah text style.
  ///
  /// Receives the resolved style (from [ayahStyle] or library default) and
  /// returns a modified style. Use this for easy customization:
  ///
  /// ```dart
  /// MushafStyle(
  ///   ayahStyleModifier: (style) => style.copyWith(color: Colors.brown),
  /// )
  /// ```
  ///
  /// If both [ayahStyle] and [ayahStyleModifier] are provided, the modifier
  /// receives the merged result of [ayahStyle] and can further customize it.
  final StyleModifier? ayahStyleModifier;

  /// A function to modify the default active/highlighted Ayah style.
  ///
  /// See [ayahStyleModifier] for usage pattern.
  final StyleModifier? activeAyahStyleModifier;

  /// A function to modify the default Basmalah text style.
  ///
  /// See [ayahStyleModifier] for usage pattern.
  final StyleModifier? basmalahStyleModifier;

  /// A function to modify the default Surah name text style.
  ///
  /// See [ayahStyleModifier] for usage pattern.
  final StyleModifier? surahNameStyleModifier;

  /// A function to modify the default Juz indicator text style.
  ///
  /// See [ayahStyleModifier] for usage pattern.
  final StyleModifier? juzStyleModifier;

  /// A function to modify the default page number text style.
  ///
  /// See [ayahStyleModifier] for usage pattern.
  final StyleModifier? pageNumberStyleModifier;

  /// The background color for highlighted/selected Ayahs.
  ///
  /// This color is used when [activeAyahStyle] is null or doesn't
  /// specify a background color. Defaults to a semi-transparent amber.
  final Color highlightColor;

  /// The background color for the entire Mushaf page.
  ///
  /// If null, the page will use the parent widget's background color.
  /// For an authentic look, consider using cream or ivory colors.
  final Color? backgroundColor;

  /// Scaling configuration for responsive text sizing.
  ///
  /// Controls how text scales on different screen sizes. If null,
  /// default auto-scaling is used based on available width.
  final MushafScale scale;

  /// Creates a [MushafStyle] with the given styling options.
  ///
  /// All parameters are optional with sensible defaults:
  /// - [highlightColor] defaults to a semi-transparent amber
  /// - [scale] defaults to auto-scaling with min 0.5, max 2.0
  /// - All style parameters default to null (uses library defaults)
  const MushafStyle({
    this.ayahStyle,
    this.ayahStyleModifier,
    this.activeAyahStyle,
    this.activeAyahStyleModifier,
    this.basmalahStyle,
    this.basmalahStyleModifier,
    this.surahNameStyle,
    this.surahNameStyleModifier,
    this.juzStyle,
    this.juzStyleModifier,
    this.pageNumberStyle,
    this.pageNumberStyleModifier,
    this.highlightColor = const Color.fromARGB(202, 245, 205, 110),
    this.backgroundColor,
    this.scale = const MushafScale(),
  });

  /// Creates a copy of this style with the given fields replaced.
  ///
  /// Note: Style objects are passed through as-is. The `fontFamily` and
  /// `package` enforcement happens at render time via [MushafTextStyleMerger].
  MushafStyle copyWith({
    TextStyle? ayahStyle,
    StyleModifier? ayahStyleModifier,
    TextStyle? activeAyahStyle,
    StyleModifier? activeAyahStyleModifier,
    TextStyle? basmalahStyle,
    StyleModifier? basmalahStyleModifier,
    TextStyle? surahNameStyle,
    StyleModifier? surahNameStyleModifier,
    TextStyle? juzStyle,
    StyleModifier? juzStyleModifier,
    TextStyle? pageNumberStyle,
    StyleModifier? pageNumberStyleModifier,
    Color? highlightColor,
    Color? backgroundColor,
    MushafScale? scale,
  }) {
    return MushafStyle(
      ayahStyle: ayahStyle ?? this.ayahStyle,
      ayahStyleModifier: ayahStyleModifier ?? this.ayahStyleModifier,
      activeAyahStyle: activeAyahStyle ?? this.activeAyahStyle,
      activeAyahStyleModifier:
          activeAyahStyleModifier ?? this.activeAyahStyleModifier,
      basmalahStyle: basmalahStyle ?? this.basmalahStyle,
      basmalahStyleModifier:
          basmalahStyleModifier ?? this.basmalahStyleModifier,
      surahNameStyle: surahNameStyle ?? this.surahNameStyle,
      surahNameStyleModifier:
          surahNameStyleModifier ?? this.surahNameStyleModifier,
      juzStyle: juzStyle ?? this.juzStyle,
      juzStyleModifier: juzStyleModifier ?? this.juzStyleModifier,
      pageNumberStyle: pageNumberStyle ?? this.pageNumberStyle,
      pageNumberStyleModifier:
          pageNumberStyleModifier ?? this.pageNumberStyleModifier,
      highlightColor: highlightColor ?? this.highlightColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      scale: scale ?? this.scale,
    );
  }
}
