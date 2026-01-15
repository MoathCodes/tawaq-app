import 'package:flutter/material.dart';
import 'package:mushaf_reader/src/core/fonts.dart';
import 'package:mushaf_reader/src/data/models/mushaf_style.dart'
    show StyleModifier;
import 'package:mushaf_reader/src/data/models/surah_model.dart';
import 'package:mushaf_reader/src/data/repository/hive_quran_repo.dart';
import 'package:mushaf_reader/src/data/repository/i_quran_repo.dart';

/// A widget that displays a Surah name using the QCF4 Basmalah font.
///
/// This widget renders the Surah name glyph from QCF4_BSML font, which
/// contains special glyphs for Surah names, Bismillah, and header text.
///
/// ## Font Usage
///
/// Unlike page content which uses page-specific fonts (QCF4_001-604),
/// Surah names use the shared QCF4_BSML font that contains common
/// decorative glyphs.
///
/// ## Customization
///
/// When a custom [textStyle] is provided, the font family is always
/// overridden to [MushafFonts.basmalahFamily] to ensure correct rendering.
///
/// ## Usage
///
/// ```dart
/// // Default styling
/// SurahNameWidget(name: 'سُورَةُ ٱلْفَاتِحَة')
///
/// // Custom styling (font family is preserved)
/// SurahNameWidget(
///   name: 'سُورَةُ ٱلْبَقَرَة',
///   textStyle: TextStyle(fontSize: 24, color: Colors.green),
/// )
/// ```
///
/// See also:
/// - [SurahHeaderWidget], which uses this with an SVG banner
/// - [MushafFonts.basmalahFamily], the font used for rendering
class SurahNameWidget extends StatefulWidget {
  /// The Surah data to display.
  ///
  /// If provided, the widget renders directly.
  /// If null, [_surahNumber] must be set to load data asynchronously.
  final SurahModel? _surahData;

  /// The Surah number to load asynchronously.
  ///
  /// Used when created via [SurahNameWidget.fromSurahNumber].
  final int? _surahNumber;

  /// The font size for the Surah name.
  ///
  /// If not provided, uses the base Basmalah font size (21).
  final double? fontSize;

  /// Optional custom text style.
  ///
  /// The [fontFamily] property will be overridden with
  /// [MushafFonts.basmalahFamily] regardless of the provided value.
  final TextStyle? textStyle;

  /// A function to modify the resolved text style.
  ///
  /// Use this for easy customization:
  /// ```dart
  /// SurahNameWidget(
  ///   surahData: surah,
  ///   styleModifier: (style) => style.copyWith(color: Colors.green),
  /// )
  /// ```
  final StyleModifier? styleModifier;

  /// Callback triggered when the surah name widget is tapped.
  final void Function(int surahNumber)? onTap;

  /// Callback triggered when the surah name widget is long pressed.
  final void Function(int surahNumber)? onLongPress;

  /// Optional repository for testing.
  final IQuranRepository? repository;

  /// Creates a SurahNameWidget with surah data.
  const SurahNameWidget({
    super.key,
    required SurahModel surahData,
    this.fontSize,
    this.textStyle,
    this.styleModifier,
    this.onTap,
    this.onLongPress,
    this.repository,
  }) : _surahData = surahData,
       _surahNumber = null;

  /// Creates a SurahNameWidget that loads surah data asynchronously.
  ///
  /// The widget will show a [SizedBox.shrink] while loading.
  const SurahNameWidget.fromSurahNumber(
    int surahNumber, {
    super.key,
    this.fontSize,
    this.textStyle,
    this.styleModifier,
    this.onTap,
    this.onLongPress,
    this.repository,
  }) : _surahData = null,
       _surahNumber = surahNumber;

  @override
  State<SurahNameWidget> createState() => _SurahNameWidgetState();
}

class _SurahNameWidgetState extends State<SurahNameWidget> {
  Future<SurahModel?>? _future;

  @override
  void initState() {
    super.initState();
    if (widget._surahData == null && widget._surahNumber != null) {
      _loadFuture();
    }
  }

  @override
  void didUpdateWidget(SurahNameWidget oldWidget) {
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
    // If we have surah data, render directly
    if (widget._surahData != null) {
      return _buildContent(widget._surahData!);
    }

    // Otherwise, load asynchronously
    return FutureBuilder<SurahModel?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData ||
            snapshot.data == null) {
          return const SizedBox.shrink();
        }
        return _buildContent(snapshot.data!);
      },
    );
  }

  Widget _buildContent(SurahModel surahData) {
    final effectiveStyle = MushafTextStyleMerger.mergeBasmalahStyle(
      userStyle: widget.textStyle,
      modifier: widget.styleModifier,
      baseSize:
          widget.fontSize ??
          widget.textStyle?.fontSize ??
          MushafBaseFontSizes.basmalah,
      scaleFactor: 1.0,
    );

    if (widget.onTap != null || widget.onLongPress != null) {
      return GestureDetector(
        onTap: () => widget.onTap?.call(surahData.number),
        onLongPress: () => widget.onLongPress?.call(surahData.number),
        child: Text(surahData.glyph, style: effectiveStyle),
      );
    }

    return Text(surahData.glyph, style: effectiveStyle);
  }
}
