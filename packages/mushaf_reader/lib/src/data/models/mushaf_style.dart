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
/// - [composeStyleModifiers], for chaining multiple modifiers
typedef StyleModifier = TextStyle Function(TextStyle defaultStyle);

/// Chains two [StyleModifier]s so [next] runs after [existing].
///
/// Returns `null` when both inputs are `null`.
StyleModifier? composeStyleModifiers(
  StyleModifier? existing,
  StyleModifier? next,
) {
  if (next == null) return existing;
  if (existing == null) return next;
  return (style) => next(existing(style));
}

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
///
/// ## Reading boost
///
/// Apply a comfort multiplier after the page fits the viewport:
///
/// ```dart
/// MushafScale(readingBoost: 1.08)
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

  /// User reading comfort multiplier applied after width/height fit.
  ///
  /// Defaults to `1.0`. Typical range: `0.9` (compact) to `1.12` (extra large).
  /// Ignored when [ayahFontSize] is set (fixed-size mode).
  final double readingBoost;

  /// Minimum allowed [readingBoost]. Defaults to `0.85`.
  final double minReadingBoost;

  /// Maximum allowed [readingBoost]. Defaults to `1.15`.
  final double maxReadingBoost;

  const MushafScale({
    this.factor,
    this.ayahFontSize,
    this.basmalahFontSize,
    this.pageNumberFontSize,
    this.minScale = 0.5,
    this.maxScale = 2.0,
    this.referenceWidth = 500.0,
    this.readingBoost = 1,
    this.minReadingBoost = 0.85,
    this.maxReadingBoost = 1.15,
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
/// Two complementary APIs:
///
/// - **[MushafStyle.modify]** / **[MushafStyleCustomization.modify]** — tweak
///   library defaults with short modifier hooks (`ayah`, `basmalah`, …).
/// - **Constructor** — full control with explicit [TextStyle] bases and/or
///   `*StyleModifier` fields when you need both.
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
/// // Modifier-only (most common) — tweak defaults with copyWith
/// MushafPage(
///   page: 1,
///   style: MushafStyle.modify(
///     ayah: (s) => s.copyWith(color: Color(0xFF1B4332)),
///     activeAyah: (s) => s.copyWith(
///       color: Colors.white,
///       backgroundColor: Color(0xFF2D6A4F),
///     ),
///     backgroundColor: Color(0xFFFFFBF0),
///     scale: MushafScale(minScale: 0.7, maxScale: 1.5),
///   ),
/// )
///
/// // Full override — explicit TextStyle bases
/// MushafPage(
///   page: 1,
///   style: MushafStyle(
///     ayahStyle: TextStyle(color: Color(0xFF1B4332)),
///     activeAyahStyle: TextStyle(
///       color: Colors.white,
///       backgroundColor: Color(0xFF2D6A4F),
///     ),
///   ),
/// )
/// ```
///
/// See also:
/// - [MushafPage], which uses this style for rendering
/// - [MushafScale], for detailed scaling control
/// - [MushafReaderController.selectAyah], for controlling Ayah selection
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

  /// The text style applied to Surah name text at the top of the page.
  ///
  /// Uses the shared QCF4_BSML font. Customize color, weight, etc.
  /// The `fontFamily` and `package` are always overridden.
  final TextStyle? surahNameStyle;

  /// The text style applied to Surah name text displayed in the header banner.
  ///
  /// This is separate from [surahNameStyle] to allow different styling for
  /// the surah name when it appears inside the decorative header vs. at the top.
  /// Uses the shared QCF4_BSML font. Customize color, weight, etc.
  /// The `fontFamily` and `package` are always overridden.
  final TextStyle? headerSurahNameStyle;

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

  /// A function to modify the default header Surah name text style.
  ///
  /// See [ayahStyleModifier] for usage pattern.
  final StyleModifier? headerSurahNameStyleModifier;

  /// A function to modify the default Juz indicator text style.
  ///
  /// See [ayahStyleModifier] for usage pattern.
  final StyleModifier? juzStyleModifier;

  /// A function to modify the default page number text style.
  ///
  /// See [ayahStyleModifier] for usage pattern.
  final StyleModifier? pageNumberStyleModifier;

  /// Optional custom image asset path for the light surah header decoration.
  ///
  /// If provided, this image will be used instead of the default light header
  /// banner. For dark mode, see [surahHeaderImageDark].
  /// The image should be an asset path (e.g., 'assets/images/custom_header.svg').
  final String? surahHeaderImage;

  /// Optional custom image asset path for the dark surah header decoration.
  ///
  /// If provided, this image will be used instead of the default dark header
  /// banner. When null, the package default dark SVG is used.
  final String? surahHeaderImageDark;

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

  /// Creates a [MushafStyle] with explicit [TextStyle] bases and/or modifiers.
  ///
  /// Prefer [MushafStyle.modify] when you only need to tweak library defaults.
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
    this.headerSurahNameStyle,
    this.headerSurahNameStyleModifier,
    this.juzStyle,
    this.juzStyleModifier,
    this.pageNumberStyle,
    this.pageNumberStyleModifier,
    this.surahHeaderImage,
    this.surahHeaderImageDark,
    this.highlightColor = const Color.fromARGB(202, 245, 205, 110),
    this.backgroundColor,
    this.scale = const MushafScale(),
  });

  /// Creates a [MushafStyle] that tweaks library defaults via modifiers.
  ///
  /// Short parameter names map to the `*StyleModifier` fields. Use the
  /// constructor when you need explicit [TextStyle] bases, or both base +
  /// modifier for the same element.
  ///
  /// Chain further tweaks with [MushafStyleCustomization.modify]:
  ///
  /// ```dart
  /// MushafStyle.modify(ayah: (s) => s.copyWith(color: Colors.brown))
  ///     .modify(scale: MushafScale(readingBoost: 1.08));
  /// ```
  factory MushafStyle.modify({
    StyleModifier? ayah,
    StyleModifier? activeAyah,
    StyleModifier? basmalah,
    StyleModifier? surahName,
    StyleModifier? headerSurahName,
    StyleModifier? juz,
    StyleModifier? pageNumber,
    String? surahHeaderImage,
    String? surahHeaderImageDark,
    Color highlightColor = const Color.fromARGB(202, 245, 205, 110),
    Color? backgroundColor,
    MushafScale scale = const MushafScale(),
  }) {
    return MushafStyle(
      ayahStyleModifier: ayah,
      activeAyahStyleModifier: activeAyah,
      basmalahStyleModifier: basmalah,
      surahNameStyleModifier: surahName,
      headerSurahNameStyleModifier: headerSurahName,
      juzStyleModifier: juz,
      pageNumberStyleModifier: pageNumber,
      surahHeaderImage: surahHeaderImage,
      surahHeaderImageDark: surahHeaderImageDark,
      highlightColor: highlightColor,
      backgroundColor: backgroundColor,
      scale: scale,
    );
  }

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
    TextStyle? headerSurahNameStyle,
    StyleModifier? headerSurahNameStyleModifier,
    TextStyle? juzStyle,
    StyleModifier? juzStyleModifier,
    TextStyle? pageNumberStyle,
    StyleModifier? pageNumberStyleModifier,
    String? surahHeaderImage,
    String? surahHeaderImageDark,
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
      headerSurahNameStyle: headerSurahNameStyle ?? this.headerSurahNameStyle,
      headerSurahNameStyleModifier:
          headerSurahNameStyleModifier ?? this.headerSurahNameStyleModifier,
      juzStyle: juzStyle ?? this.juzStyle,
      juzStyleModifier: juzStyleModifier ?? this.juzStyleModifier,
      pageNumberStyle: pageNumberStyle ?? this.pageNumberStyle,
      pageNumberStyleModifier:
          pageNumberStyleModifier ?? this.pageNumberStyleModifier,
      surahHeaderImage: surahHeaderImage ?? this.surahHeaderImage,
      surahHeaderImageDark: surahHeaderImageDark ?? this.surahHeaderImageDark,
      highlightColor: highlightColor ?? this.highlightColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      scale: scale ?? this.scale,
    );
  }
}
