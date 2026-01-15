import 'package:flutter/material.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:mushaf_reader/src/data/repository/hive_quran_repo.dart';
import 'package:mushaf_reader/src/data/repository/i_quran_repo.dart';

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
class BasmalahWidget extends StatefulWidget {
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

  /// Optional repository for testing.
  final IQuranRepository? repository;

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
    this.repository,
  });

  @override
  State<BasmalahWidget> createState() => _BasmalahWidgetState();
}

class _BasmalahWidgetState extends State<BasmalahWidget> {
  Future<String?>? _future;

  @override
  void initState() {
    super.initState();
    if (widget.glyph == null) {
      _loadFuture();
    }
  }

  void _loadFuture() {
    _future = (widget.repository ?? HiveQuranRepository()).getBasmalah().then(
      (value) => value,
    ); // getBasmalah returns String, we want String? for FutureBuilder logic consistency
  }

  @override
  Widget build(BuildContext context) {
    // If glyph provided, use it directly
    if (widget.glyph != null && widget.glyph!.isNotEmpty) {
      return _buildText(widget.glyph!);
    }

    // Try to get from repository cache
    final repo = widget.repository ?? HiveQuranRepository();
    final cachedGlyph = repo.getBasmalahSync();
    if (cachedGlyph != null && cachedGlyph.isNotEmpty) {
      return _buildText(cachedGlyph);
    }

    // Fallback: load asynchronously
    return FutureBuilder<String?>(
      future: _future,
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
      userStyle: widget.textStyle,
      modifier: widget.styleModifier,
      baseSize:
          widget.fontSize ??
          widget.textStyle?.fontSize ??
          MushafBaseFontSizes.basmalah,
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
