import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:mushaf_reader/src/data/repository/hive_quran_repo.dart';

/// A decorative banner widget displaying a Surah name.
///
/// This widget renders an ornate SVG banner with the Surah name centered
/// on top, matching the traditional Mushaf surah header design.
///
/// ## Appearance
///
/// The banner features:
/// - An ornate SVG background (light or dark theme)
/// - The Surah name in QCF4_BSML (Basmalah) font
/// - Scalable width for different screen sizes
///
/// ## Caching
///
/// SVG widgets are cached to avoid redundant parsing. Call [clearCache]
/// when the widget tree is disposed or theme changes.
///
/// ## Usage
///
/// ```dart
/// // Light theme banner
/// SurahHeaderWidget(
///   name: 'سُورَةُ ٱلْفَاتِحَة',
///   width: 400,
/// )
///
/// // Dark theme banner
/// SurahHeaderWidget(
///   name: 'سُورَةُ ٱلْبَقَرَة',
///   isDark: true,
///   width: 500,
/// )
/// ```
///
/// See also:
/// - [SurahNameWidget], used internally for the text
/// - [MushafFonts.basmalahFamily], the font used for Surah names
class SurahHeaderWidget extends StatelessWidget {
  /// Cache for SVG widgets keyed by asset path and width.
  ///
  /// Avoids redundant SVG parsing for repeated renders.
  static final Map<String, Widget> _svgCache = {};

  /// The Surah data to display.
  ///
  /// If provided, the widget renders directly.
  /// If null, [_surahNumber] must be set to load data asynchronously.
  final SurahModel? _surahData;

  /// The Surah number to load asynchronously.
  ///
  /// Used when created via [SurahHeaderWidget.fromSurahNumber].
  final int? _surahNumber;

  /// Whether to use the dark theme banner variant.
  ///
  /// When `true`, uses `surah_banner_dark.svg`.
  /// When `false`, uses `surah_banner.svg`.
  final bool isDark;

  /// The width of the SVG banner.
  ///
  /// Height scales proportionally. Defaults to 500.
  final double width;

  /// The font size for the Surah name.
  ///
  /// If not provided, defaults to 25.
  final double? fontSize;

  /// Optional custom text style for the Surah name.
  ///
  /// If provided, the [MushafFonts.basmalahFamily] font is applied
  /// automatically while preserving other style properties.
  final TextStyle? textStyle;

  /// Callback invoked when the Surah header is tapped.
  ///
  /// Receives the Surah number (1-114).
  final void Function(int surahNumber)? onTap;

  /// Callback invoked when the Surah header is long-pressed.
  ///
  /// Receives the Surah number (1-114).
  final void Function(int surahNumber)? onLongPress;

  /// Creates a SurahHeaderWidget with surah data.
  const SurahHeaderWidget({
    super.key,
    required SurahModel surahData,
    this.fontSize,
    this.textStyle,
    this.isDark = false,
    this.width = 500,
    this.onTap,
    this.onLongPress,
  }) : _surahData = surahData,
       _surahNumber = null;

  /// Creates a SurahHeaderWidget that loads surah data asynchronously.
  ///
  /// The widget will show only the SVG banner while loading.
  const SurahHeaderWidget.fromSurahNumber(
    int surahNumber, {
    super.key,
    this.fontSize,
    this.textStyle,
    this.isDark = false,
    this.width = 500,
    this.onTap,
    this.onLongPress,
  }) : _surahData = null,
       _surahNumber = surahNumber;

  @override
  Widget build(BuildContext context) {
    final assetPath = isDark
        ? 'assets/images/surah_banner_dark.svg'
        : 'assets/images/surah_banner.svg';

    // Get cached SVG or create new one
    final svg = _svgCache.putIfAbsent(
      '${assetPath}_$width',
      () => SvgPicture.asset(assetPath, package: 'mushaf_reader', width: width),
    );

    final effectiveFontSize = fontSize ?? 25.0;

    // If we have surah data, render directly
    if (_surahData != null) {
      return _buildStack(svg, effectiveFontSize, _surahData);
    }

    // Otherwise, load asynchronously
    return FutureBuilder<SurahModel?>(
      future: HiveQuranRepository().getSurah(_surahNumber!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData ||
            snapshot.data == null) {
          // Show just the SVG banner while loading
          return svg;
        }
        return _buildStack(svg, effectiveFontSize, snapshot.data!);
      },
    );
  }

  Widget _buildStack(
    Widget svg,
    double effectiveFontSize,
    SurahModel surahData,
  ) {
    return GestureDetector(
      onTap: () => onTap?.call(surahData.number),
      onLongPress: () => onLongPress?.call(surahData.number),
      child: Stack(
        alignment: Alignment.center,
        children: [
          svg,
          SurahNameWidget(
            surahData: surahData,
            fontSize: effectiveFontSize,
            textStyle: textStyle,
          ),
        ],
      ),
    );
  }

  /// Clears the SVG widget cache.
  ///
  /// Call this when disposing the Mushaf widget tree or when
  /// switching between light and dark themes to release memory.
  static void clearCache() => _svgCache.clear();
}
