import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mushaf_reader/src/data/models/ayah_fragment.dart';

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

  /// The currently selected Ayah ID, or `null` if none is selected.
  final int? selectedAyahId;

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
    this.selectedAyahId,
  });

  @override
  State<PageAyahWidget> createState() => _PageAyahWidgetState();
}

class _PageAyahWidgetState extends State<PageAyahWidget> {
  /// Cache for tap gesture recognizers.
  final Map<int, TapGestureRecognizer> _tapRecognizers = {};

  /// Cache for long press gesture recognizers.
  final Map<int, LongPressGestureRecognizer> _longPressRecognizers = {};

  /// Tracks whether a long press was triggered (to differentiate from tap).
  final Map<int, bool> _longPressTriggered = {};

  /// Cached text spans for the current content.
  List<InlineSpan>? _cachedSpans;

  /// The fullText used to build [_cachedSpans].
  String? _cachedFullText;

  /// The selected Ayah ID used to build [_cachedSpans].
  int? _cachedSelectedAyah;

  /// The style used to build [_cachedSpans].
  TextStyle? _cachedStyle;

  /// The active style used to build [_cachedSpans].
  TextStyle? _cachedActiveStyle;

  @override
  Widget build(BuildContext context) {
    // Check if we need to rebuild spans
    if (_cachedSpans == null ||
        _cachedFullText != widget.fullText ||
        _cachedSelectedAyah != widget.selectedAyahId ||
        _cachedStyle != widget.style ||
        _cachedActiveStyle != widget.activeStyle) {
      _buildSpans();
    }

    return RepaintBoundary(
      child: RichText(
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
        locale: const Locale('ar'),
        text: TextSpan(children: _cachedSpans!),
      ),
    );
  }

  @override
  void dispose() {
    // Dispose all gesture recognizers to prevent memory leaks
    for (final recognizer in _tapRecognizers.values) {
      recognizer.dispose();
    }
    _tapRecognizers.clear();
    for (final recognizer in _longPressRecognizers.values) {
      recognizer.dispose();
    }
    _longPressRecognizers.clear();
    _longPressTriggered.clear();
    super.dispose();
  }

  /// Builds TextSpan children for each Ayah fragment.
  ///
  /// Uses TapGestureRecognizer for tap detection and
  /// LongPressGestureRecognizer for long press detection.
  void _buildSpans() {
    final spans = <InlineSpan>[];

    for (final frag in widget.ayahs) {
      final textSlice = widget.fullText.substring(frag.start, frag.end);

      GestureRecognizer? recognizer;

      if (widget.enableHighlight) {
        if (widget.onAyahLongPress != null) {
          // When both tap and long press are needed, use LongPressGestureRecognizer
          // and treat onLongPressUp (short press release) as a tap
          final ayahId = frag.ayahId;
          final longPressRecognizer = _longPressRecognizers.putIfAbsent(
            ayahId,
            () => LongPressGestureRecognizer(),
          );

          longPressRecognizer
            ..onLongPressDown = (_) {
              _longPressTriggered[ayahId] = false;
            }
            ..onLongPress = () {
              _longPressTriggered[ayahId] = true;
              widget.onAyahLongPress!(ayahId);
            }
            ..onLongPressUp = () {
              // If long press wasn't triggered, treat this as a tap
              if (_longPressTriggered[ayahId] != true) {
                widget.onAyahSelection(ayahId);
              }
            }
            ..onLongPressCancel = () {
              _longPressTriggered[ayahId] = false;
            };

          recognizer = longPressRecognizer;
        } else {
          // Only tap needed - use TapGestureRecognizer
          final tapRecognizer = _tapRecognizers.putIfAbsent(
            frag.ayahId,
            () => TapGestureRecognizer(),
          );
          tapRecognizer.onTap = () => widget.onAyahSelection(frag.ayahId);
          recognizer = tapRecognizer;
        }
      }

      spans.add(
        TextSpan(
          text: textSlice,
          style: widget.selectedAyahId == frag.ayahId
              ? widget.activeStyle ?? widget.style
              : widget.style,
          recognizer: recognizer,
        ),
      );
    }

    _cachedSpans = spans;
    _cachedFullText = widget.fullText;
    _cachedSelectedAyah = widget.selectedAyahId;
    _cachedStyle = widget.style;
    _cachedActiveStyle = widget.activeStyle;
  }
}
