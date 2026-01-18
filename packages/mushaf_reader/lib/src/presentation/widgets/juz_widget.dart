import 'package:flutter/material.dart';
import 'package:mushaf_reader/src/core/fonts.dart';
import 'package:mushaf_reader/src/data/models/juz.dart';
import 'package:mushaf_reader/src/data/models/mushaf_style.dart'
    show StyleModifier;
import 'package:mushaf_reader/src/data/repository/hive_quran_repo.dart';
import 'package:mushaf_reader/src/data/repository/i_quran_repo.dart';

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
/// - [Juz], the data model for Juz information
class JuzWidget extends StatefulWidget {
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
  final Juz? juzData;

  /// Optional repository for testing.
  final IQuranRepository? repository;

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
    this.repository,
  });

  @override
  State<JuzWidget> createState() => _JuzWidgetState();
}

class _JuzWidgetState extends State<JuzWidget> {
  Future<Juz?>? _future;

  @override
  void initState() {
    super.initState();
    if (widget.juzData == null) {
      _loadFuture();
    }
  }

  @override
  void didUpdateWidget(JuzWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.number != oldWidget.number) {
      _loadFuture();
    }
  }

  void _loadFuture() {
    _future = (widget.repository ?? HiveQuranRepository()).getJuz(
      widget.number,
    );
  }

  @override
  Widget build(BuildContext context) {
    // If data provided, use it directly
    if (widget.juzData != null) {
      return _buildContent(widget.juzData!);
    }

    // Try to get from repository cache
    // Note: getJuzSync is on the Interface, so we can use widget.repository if present
    final repo = widget.repository ?? HiveQuranRepository();
    final cachedJuz = repo.getJuzSync(widget.number);
    if (cachedJuz != null) {
      return _buildContent(cachedJuz);
    }

    // Fallback: load asynchronously
    return FutureBuilder<Juz?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return _buildContent(snapshot.data!);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildContent(Juz juz) {
    // fontSize priority: fontSize param → textStyle.fontSize → 40.0
    final effectiveFontSize =
        widget.fontSize ?? widget.textStyle?.fontSize ?? 40.0;
    final effectiveStyle = MushafTextStyleMerger.mergeBasmalahStyle(
      userStyle: widget.textStyle,
      modifier: widget.styleModifier,
      baseSize: effectiveFontSize,
      scaleFactor: 1.0,
    );

    return widget.onTap != null || widget.onLongPress != null
        ? GestureDetector(
            onTap: () => widget.onTap?.call(widget.number),
            onLongPress: () => widget.onLongPress?.call(widget.number),
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
