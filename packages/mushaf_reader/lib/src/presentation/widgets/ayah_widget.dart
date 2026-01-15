import 'package:flutter/material.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:mushaf_reader/src/data/repository/hive_quran_repo.dart';
import 'package:mushaf_reader/src/data/repository/i_quran_repo.dart';

/// A widget that displays a single Ayah (verse) with the correct QCF4 font.
///
/// This widget fetches Ayah data asynchronously and renders it using
/// the appropriate page-specific font for accurate glyph display.
///
/// ## Usage
///
/// There are two ways to create an AyahWidget:
///
/// ### By Global Ayah ID
///
/// Use when you have the unique Ayah identifier (1-6236):
///
/// ```dart
/// AyahWidget.fromId(
///   ayahId: 1, // Al-Fatiha verse 1
///   fontSize: 24,
/// )
/// ```
///
/// ### By Surah and Ayah Number
///
/// Use when you have the Surah number and verse number:
///
/// ```dart
/// AyahWidget.fromSurahAyah(
///   surah: 2, // Al-Baqarah
///   ayah: 255, // Ayat Al-Kursi
///   fontSize: 24,
/// )
/// ```
///
/// ## Loading and Error States
///
/// Custom loading and error widgets can be provided:
///
/// ```dart
/// AyahWidget.fromId(
///   ayahId: 1,
///   loadingWidget: Text('Loading...'),
///   errorWidget: Text('Could not load ayah'),
/// )
/// ```
///
/// ## Font Handling
///
/// The widget automatically uses the correct QCF4 font based on the
/// Ayah's page number. Any [TextStyle.fontFamily] in [style] will be
/// overridden with the appropriate page font.
///
/// See also:
/// - [MushafController], for fetching Ayah data
/// - [MushafPage], for displaying complete pages
/// - [MushafFonts], for font utilities
class AyahWidget extends StatefulWidget {
  /// The Surah number (used with [_ayah] for lookup).
  final int? _surah;

  /// The Ayah number within the Surah (used with [_surah] for lookup).
  final int? _ayah;

  /// The global Ayah ID for direct lookup.
  final int? _ayahId;

  /// The font size for the Ayah text.
  ///
  /// If not provided, uses the base Ayah font size (28).
  final double? fontSize;

  /// Custom text style for the Ayah.
  ///
  /// The [TextStyle.fontFamily] will be overridden with the appropriate
  /// page-specific QCF4 font. Other properties like [fontSize] and [color]
  /// are preserved.
  final TextStyle? style;

  /// A function to modify the resolved text style.
  ///
  /// Use this for easy customization:
  /// ```dart
  /// AyahWidget.fromId(
  ///   ayahId: 1,
  ///   styleModifier: (style) => style.copyWith(color: Colors.brown),
  /// )
  /// ```
  final StyleModifier? styleModifier;

  /// Widget to display while loading the Ayah data.
  ///
  /// Defaults to a centered [CircularProgressIndicator].
  final Widget? loadingWidget;

  /// Widget to display if an error occurs.
  ///
  /// Defaults to a [Text] widget showing the error message.
  final Widget? errorWidget;

  /// Whether to remove newline characters from the glyph text.
  ///
  /// Set to `true` (default) for inline display.
  /// Set to `false` to preserve original line breaks.
  final bool removeNewLines;

  /// Optional repository for testing.
  final IQuranRepository? repository;

  /// Creates an AyahWidget that fetches by unique Ayah ID (1-6236).
  ///
  /// This is the preferred constructor when you have the global Ayah
  /// identifier, as it requires only one database lookup.
  ///
  /// ## Example
  ///
  /// ```dart
  /// AyahWidget.fromId(
  ///   ayahId: 7, // Al-Fatiha verse 7
  ///   fontSize: 28,
  /// )
  /// ```
  const AyahWidget.fromId({
    super.key,
    required int ayahId,
    this.fontSize,
    this.style,
    this.styleModifier,
    this.loadingWidget,
    this.errorWidget,
    this.removeNewLines = true,
    this.repository,
  }) : _ayahId = ayahId,
       _surah = null,
       _ayah = null;

  /// Creates an AyahWidget that fetches by Surah and Ayah number.
  ///
  /// Use this when you know the Surah number (1-114) and the verse
  /// number within that Surah.
  ///
  /// ## Example
  ///
  /// ```dart
  /// AyahWidget.fromSurahAyah(
  ///   surah: 112, // Al-Ikhlas
  ///   ayah: 1,    // First verse
  ///   fontSize: 28,
  /// )
  /// ```
  const AyahWidget.fromSurahAyah({
    super.key,
    required int surah,
    required int ayah,
    this.fontSize,
    this.style,
    this.styleModifier,
    this.loadingWidget,
    this.errorWidget,
    this.removeNewLines = true,
    this.repository,
  }) : _surah = surah,
       _ayah = ayah,
       _ayahId = null;

  @override
  State<AyahWidget> createState() => _AyahWidgetState();
}

class _AyahWidgetState extends State<AyahWidget> {
  Future<AyahModel>? _future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AyahModel>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.loadingWidget ??
              const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return widget.errorWidget ??
              Center(child: Text('Error: ${snapshot.error}'));
        }

        final ayah = snapshot.data!;
        final effectiveFontSize =
            widget.fontSize ??
            widget.style?.fontSize ??
            MushafBaseFontSizes.ayah;

        final effectiveStyle = MushafTextStyleMerger.mergeAyahStyle(
          userStyle: widget.style,
          modifier: widget.styleModifier,
          pageNumber: ayah.page,
          baseSize: effectiveFontSize,
          scaleFactor: 1.0,
        );

        return Text(
          ayah.codeV4,
          textAlign: TextAlign.right,
          style: effectiveStyle,
        );
      },
    );
  }

  @override
  void didUpdateWidget(AyahWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget._ayahId != oldWidget._ayahId ||
        widget._surah != oldWidget._surah ||
        widget._ayah != oldWidget._ayah) {
      _loadAyah();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAyah();
  }

  /// Initiates the async fetch of Ayah data.
  void _loadAyah() {
    final repo = widget.repository ?? HiveQuranRepository();
    _future = widget._ayahId != null
        ? repo.getAyah(widget._ayahId!, widget.removeNewLines)
        : repo.getAyahBySurah(
            widget._surah!,
            widget._ayah!,
            widget.removeNewLines,
          );
  }
}
