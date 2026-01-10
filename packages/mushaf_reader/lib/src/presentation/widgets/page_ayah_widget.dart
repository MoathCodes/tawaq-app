import 'package:flutter/material.dart';
import 'package:mushaf_reader/src/data/models/ayah_fragment.dart';
import 'package:mushaf_reader/src/data/models/selected_word.dart';
import 'package:mushaf_reader/src/presentation/gestures/tap_and_long_press_gesture_recognizer.dart';

/// A widget that displays Ayah text with per-Ayah tap and highlight support.
///
/// This is the core text rendering widget used by [MushafPage]. It displays
/// a portion of the page's glyph text and handles:
///
/// - Splitting text into individual Ayah spans
/// - Tap gesture detection for each Ayah
/// - Highlight styling for the selected Ayah
///
/// ## Performance Optimizations
///
/// This widget includes several performance optimizations:
///
/// - **TextSpan Caching**: Spans are cached and only rebuilt when content changes
/// - **Gesture Recognizer Reuse**: Tap recognizers are pooled and reused
/// - **RepaintBoundary**: Isolates repaints for better performance
///
/// ## Usage
///
/// This widget is typically used internally by [MushafPage], but can be
/// used directly for custom layouts:
///
/// ```dart
/// PageAyahWidget(
///   fullText: pageData.glyphText,
///   ayahs: surahBlock.ayahs,
///   style: MushafFonts.pageStyle('QCF4_001'),
///   enableHighlight: true,
///   activeStyle: highlightStyle,
///   selectedAyahId: controller.selectedAyahId,
///   onAyahSelection: (ayahId) {
///     print('Selected ayah: $ayahId');
///   },
/// )
/// ```
///
/// See also:
/// - [MushafPage], which uses this widget
/// - [AyahFragment], for text boundary information
/// - [MushafPageController], for selection state management
class PageAyahWidget extends StatefulWidget {
  /// The complete glyph text from which Ayah fragments are extracted.
  ///
  /// This is typically [QuranPageModel.glyphText].
  final String fullText;

  /// The Ayah fragments to display from [fullText].
  ///
  /// Each fragment specifies the start/end indices and Ayah ID.
  final List<AyahFragment> ayahs;

  /// The default text style for Ayah text.
  ///
  /// This style is applied to all non-selected Ayahs.
  final TextStyle style;

  /// Whether to enable tap highlighting for Ayahs.
  ///
  /// When `true`, Ayahs can be tapped and highlighted.
  /// When `false`, the text is non-interactive.
  final bool enableHighlight;

  /// The text style for the currently selected Ayah.
  ///
  /// Should include a background color or other visual distinction.
  final TextStyle? activeStyle;

  /// Callback invoked when an Ayah is tapped.
  ///
  /// Receives the global Ayah ID (1-6236).
  final Function(int ayahNumber) onAyahSelection;

  /// Callback invoked when an Ayah is long pressed.
  ///
  /// Receives the global Ayah ID (1-6236).
  final Function(int ayahNumber)? onAyahLongPress;

  /// Callback invoked when a word inside an Ayah is tapped.
  ///
  /// Provides the global Ayah ID, the word index (0-based), and the glyph text
  /// slice for that word.
  final void Function(int ayahId, int wordIndex, String wordGlyph)?
  onAyahWordTap;

  /// The currently selected Ayah ID, or `null` if none is selected.
  final int? selectedAyahId;

  /// The currently selected word, or `null` if none is selected.
  final SelectedWord? selectedWord;

  /// The text style for the currently selected word.
  ///
  /// Typically this changes the word color (e.g., blue) while the Ayah remains
  /// highlighted with a background color.
  final TextStyle? selectedWordStyle;

  /// Creates a PageAyahWidget.
  const PageAyahWidget({
    super.key,
    required this.fullText,
    required this.ayahs,
    required this.style,
    this.enableHighlight = true,
    required this.activeStyle,
    required this.onAyahSelection,
    this.onAyahLongPress,
    this.onAyahWordTap,
    this.selectedAyahId,
    this.selectedWord,
    this.selectedWordStyle,
  });

  @override
  State<PageAyahWidget> createState() => _PageAyahWidgetState();
}

class _PageAyahWidgetState extends State<PageAyahWidget> {
  /// Cache for span gesture recognizers.
  final Map<int, TapAndLongPressGestureRecognizer> _recognizers = {};

  /// Text ranges (within the rendered text) for each Ayah ID.
  ///
  /// Used to paint a continuous highlight behind the selected Ayah even when
  /// the text is split into many spans (e.g., per-word spans).
  final Map<int, List<TextRange>> _ayahRanges = {};

  /// Cached text spans for the current content.
  List<InlineSpan>? _cachedSpans;

  /// The fullText used to build [_cachedSpans].
  String? _cachedFullText;

  /// The selected Ayah ID used to build [_cachedSpans].
  int? _cachedSelectedAyah;

  /// The selected word used to build [_cachedSpans].
  SelectedWord? _cachedSelectedWord;

  @override
  Widget build(BuildContext context) {
    // Check if we need to rebuild spans
    if (_cachedSpans == null ||
        _cachedFullText != widget.fullText ||
        _cachedSelectedAyah != widget.selectedAyahId ||
        _cachedSelectedWord != widget.selectedWord) {
      _buildSpans();
    }

    final highlightColor = widget.activeStyle?.backgroundColor;
    final shouldPaintHighlight =
        widget.enableHighlight &&
        widget.selectedAyahId != null &&
        highlightColor != null &&
        (_ayahRanges[widget.selectedAyahId!]?.isNotEmpty ?? false);

    final richText = RichText(
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
      locale: const Locale('ar'),
      text: TextSpan(children: _cachedSpans!),
    );

    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (!shouldPaintHighlight) return richText;

          return CustomPaint(
            painter: _AyahHighlightPainter(
              spans: _cachedSpans!,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              locale: const Locale('ar'),
              highlightColor: highlightColor,
              ranges: _ayahRanges[widget.selectedAyahId!]!,
            ),
            child: richText,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    // Dispose all gesture recognizers to prevent memory leaks
    for (final recognizer in _recognizers.values) {
      recognizer.dispose();
    }
    _recognizers.clear();
    super.dispose();
  }

  /// Builds TextSpan children for each Ayah fragment.
  ///
  /// Uses TapGestureRecognizer for tap detection and
  /// LongPressGestureRecognizer for long press detection.
  void _buildSpans() {
    final spans = <InlineSpan>[];

    _ayahRanges.clear();
    var globalOffset = 0;

    for (final frag in widget.ayahs) {
      final textSlice = widget.fullText.substring(frag.start, frag.end);

      // We paint highlight backgrounds via a custom painter to avoid the
      // "many rectangles" artifact when the ayah is split into multiple spans.
      final activeStyleSansBackground =
        (widget.activeStyle ?? widget.style).copyWith(backgroundColor: null);
      final ayahStyle = widget.selectedAyahId == frag.ayahId
        ? activeStyleSansBackground
        : widget.style;

      final fragStartOffset = globalOffset;
      globalOffset += textSlice.length;
      final fragEndOffset = globalOffset;
      _ayahRanges
        .putIfAbsent(frag.ayahId, () => <TextRange>[])
        .add(TextRange(start: fragStartOffset, end: fragEndOffset));

      if (!widget.enableHighlight) {
        spans.add(TextSpan(text: textSlice, style: ayahStyle));
        continue;
      }

      // If we have word ranges and a word callback/selection, build per-word spans.
      final hasWordRanges = frag.wordRanges.isNotEmpty;
      final wantsWordSpans =
          widget.onAyahWordTap != null || widget.selectedWord != null;

      if (hasWordRanges && wantsWordSpans) {
        spans.addAll(_buildWordSpans(frag, textSlice, ayahStyle));
        continue;
      }

      // Fallback: whole-ayah span.
      final recognizer = _recognizerForKey(
        _keyForAyah(frag.ayahId),
        onTap: () => widget.onAyahSelection(frag.ayahId),
        onLongPress: widget.onAyahLongPress != null
            ? () => widget.onAyahLongPress!(frag.ayahId)
            : null,
      );

      spans.add(
        TextSpan(text: textSlice, style: ayahStyle, recognizer: recognizer),
      );
    }

    _cachedSpans = spans;
    _cachedFullText = widget.fullText;
    _cachedSelectedAyah = widget.selectedAyahId;
    _cachedSelectedWord = widget.selectedWord;
  }

  List<InlineSpan> _buildWordSpans(
    AyahFragment frag,
    String textSlice,
    TextStyle ayahStyle,
  ) {
    final spans = <InlineSpan>[];

    final selectedWord = widget.selectedWord;
    final selectedWordStyle = widget.selectedWordStyle?.copyWith(
      backgroundColor: null,
    );

    var cursor = 0;
    for (final range in frag.wordRanges) {
      final start = range.start.clamp(0, textSlice.length);
      final end = range.end.clamp(0, textSlice.length);
      if (end <= start) continue;

      if (cursor < start) {
        spans.add(
          TextSpan(text: textSlice.substring(cursor, start), style: ayahStyle),
        );
      }

      final isSelected =
          selectedWord != null &&
          selectedWord.ayahId == frag.ayahId &&
          selectedWord.wordIndex == range.index;

      final wordGlyph = textSlice.substring(start, end);
      final wordStyle = isSelected && selectedWordStyle != null
          ? selectedWordStyle
          : ayahStyle;

      final recognizer = _recognizerForKey(
        _keyForWord(frag.ayahId, range.index),
        onTap: () {
          widget.onAyahWordTap?.call(frag.ayahId, range.index, wordGlyph);
        },
        onLongPress: widget.onAyahLongPress != null
            ? () => widget.onAyahLongPress!(frag.ayahId)
            : null,
      );

      spans.add(
        TextSpan(text: wordGlyph, style: wordStyle, recognizer: recognizer),
      );

      cursor = end;
    }

    if (cursor < textSlice.length) {
      spans.add(TextSpan(text: textSlice.substring(cursor), style: ayahStyle));
    }

    return spans;
  }

  TapAndLongPressGestureRecognizer _recognizerForKey(
    int key, {
    required VoidCallback? onTap,
    required VoidCallback? onLongPress,
  }) {
    final recognizer = _recognizers.putIfAbsent(
      key,
      () => TapAndLongPressGestureRecognizer(debugOwner: this),
    );

    recognizer.configure(onTap: onTap, onLong: onLongPress);
    return recognizer;
  }

  int _keyForAyah(int ayahId) => (ayahId & 0x7fffffff);

  int _keyForWord(int ayahId, int wordIndex) {
    // Pack into a single int key: high bits ayahId, low bits wordIndex.
    return ((ayahId & 0x7ffff) << 12) | (wordIndex & 0xfff);
  }
}

class _AyahHighlightPainter extends CustomPainter {
  _AyahHighlightPainter({
    required this.spans,
    required this.textAlign,
    required this.textDirection,
    required this.locale,
    required this.highlightColor,
    required this.ranges,
  });

  final List<InlineSpan> spans;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final Locale locale;
  final Color highlightColor;
  final List<TextRange> ranges;

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(children: spans),
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
    )..layout(maxWidth: size.width);

    final paint = Paint()..color = highlightColor;
    const radius = Radius.circular(4);

    for (final range in ranges) {
      if (range.isCollapsed) continue;
      final boxes = textPainter.getBoxesForSelection(
        TextSelection(baseOffset: range.start, extentOffset: range.end),
      );

      for (final box in boxes) {
        final rect = Rect.fromLTRB(box.left, box.top, box.right, box.bottom);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AyahHighlightPainter oldDelegate) {
    return oldDelegate.spans != spans ||
        oldDelegate.highlightColor != highlightColor ||
        oldDelegate.textAlign != textAlign ||
        oldDelegate.textDirection != textDirection ||
        oldDelegate.locale != locale ||
        oldDelegate.ranges != ranges;
  }
}
