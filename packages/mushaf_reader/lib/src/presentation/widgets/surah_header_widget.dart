import 'package:flutter/material.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:mushaf_reader/src/data/repository/hive_quran_repo.dart';
import 'package:mushaf_reader/src/data/repository/i_quran_repo.dart';

/// A decorative banner widget displaying a Surah name.
///
/// This widget renders an ornate PNG banner with the Surah name centered
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
class SurahHeaderWidget extends StatefulWidget {
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

  /// A function to modify the resolved text style.
  ///
  /// Use this for easy customization.
  final StyleModifier? styleModifier;

  /// Callback invoked when the Surah header is tapped.
  ///
  /// Receives the Surah number (1-114).
  final void Function(int surahNumber)? onTap;

  /// Callback invoked when the Surah header is long-pressed.
  ///
  /// Receives the Surah number (1-114).
  final void Function(int surahNumber)? onLongPress;

  /// Optional custom image asset path for the header banner.
  ///
  /// If provided, this image will be used instead of the default mainframe.png.
  final String? customHeaderImage;

  /// Optional repository for testing.
  final IQuranRepository? repository;

  const SurahHeaderWidget({
    super.key,
    required SurahModel surahData,
    this.fontSize,
    this.textStyle,
    this.styleModifier,
    this.isDark = false,
    this.width = 500,
    this.onTap,
    this.onLongPress,
    this.customHeaderImage,
    this.repository,
  }) : _surahData = surahData,
       _surahNumber = null;

  const SurahHeaderWidget.fromSurahNumber(
    int surahNumber, {
    super.key,
    this.fontSize,
    this.textStyle,
    this.styleModifier,
    this.isDark = false,
    this.width = 500,
    this.onTap,
    this.onLongPress,
    this.customHeaderImage,
    this.repository,
  }) : _surahData = null,
       _surahNumber = surahNumber;

  @override
  State<SurahHeaderWidget> createState() => _SurahHeaderWidgetState();
}

class _SurahHeaderWidgetState extends State<SurahHeaderWidget> {
  Future<SurahModel?>? _future;

  @override
  void initState() {
    super.initState();
    if (widget._surahData == null && widget._surahNumber != null) {
      _loadFuture();
    }
  }

  @override
  void didUpdateWidget(SurahHeaderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget._surahNumber != oldWidget._surahNumber) {
      _loadFuture();
    }
  }

  void _loadFuture() {
    _future = (widget.repository ?? HiveQuranRepository()).getSurah(
      widget._surahNumber!,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use custom header image if provided, otherwise use default
    final bannerImage = Image.asset(
      widget.customHeaderImage ?? 'assets/images/mainframe.png',
      package: widget.customHeaderImage == null ? 'mushaf_reader' : null,
      width: widget.width,
      fit: BoxFit.contain,
    );

    final effectiveFontSize = widget.fontSize ?? 25.0;

    // If we have surah data, render directly
    if (widget._surahData != null) {
      return _buildStack(bannerImage, effectiveFontSize, widget._surahData!);
    }

    // Otherwise, load asynchronously
    return FutureBuilder<SurahModel?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData ||
            snapshot.data == null) {
          // Show just the banner while loading
          return bannerImage;
        }
        return _buildStack(bannerImage, effectiveFontSize, snapshot.data!);
      },
    );
  }

  Widget _buildStack(
    Widget bannerImage,
    double effectiveFontSize,
    SurahModel surahData,
  ) {
    return GestureDetector(
      onTap: () => widget.onTap?.call(surahData.number),
      onLongPress: () => widget.onLongPress?.call(surahData.number),
      child: Stack(
        alignment: Alignment.center,
        children: [
          bannerImage,
          SurahNameWidget(
            surahData: surahData,
            fontSize: effectiveFontSize,
            textStyle: widget.textStyle,
            styleModifier: widget.styleModifier,
          ),
        ],
      ),
    );
  }
}
