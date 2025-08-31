import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mushaf_reader/src/data/models/ayah_fragment.dart';

/// Displays part of the page text with per-ayah mouse-over / tap highlight.
/// Optimized for performance with cached TextSpans and gesture recognizer reuse.
class PageAyahWidget extends StatefulWidget {
  final String fullText;
  final List<AyahFragment> ayahs;
  final TextStyle style;
  final bool enableHighlight;
  final TextStyle? activeStyle;
  final Function(int ayahNumber) onAyahSelection;

  const PageAyahWidget({
    super.key,
    required this.fullText,
    required this.ayahs,
    required this.style,
    this.enableHighlight = true,
    required this.activeStyle,
    required this.onAyahSelection,
  });

  @override
  State<PageAyahWidget> createState() => _PageAyahWidgetState();
}

class _PageAyahWidgetState extends State<PageAyahWidget> {
  int _selectedAyah = -1;

  // Cache for gesture recognizers to avoid recreation
  final Map<int, TapGestureRecognizer> _recognizers = {};

  // Cache for text spans
  List<InlineSpan>? _cachedSpans;
  String? _cachedFullText;
  int? _cachedSelectedAyah;

  @override
  Widget build(BuildContext context) {
    // Check if we need to rebuild spans
    if (_cachedSpans == null ||
        _cachedFullText != widget.fullText ||
        _cachedSelectedAyah != _selectedAyah) {
      _buildSpans();
    }

    return RichText(
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
      text: TextSpan(children: _cachedSpans!),
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

  @override
  void initState() {
    super.initState();
    _selectedAyah = -1;
  }

  void _buildSpans() {
    final spans = <InlineSpan>[];

    for (final frag in widget.ayahs) {
      final textSlice = widget.fullText.substring(frag.start, frag.end);

      // Reuse or create gesture recognizer
      final recognizer = _recognizers.putIfAbsent(frag.ayahId, () {
        return TapGestureRecognizer()
          ..onTap = () => _handleAyahTap(frag.ayahId);
      });

      spans.add(
        TextSpan(
          text: textSlice,
          style: _selectedAyah == frag.ayahId
              ? widget.activeStyle ?? widget.style
              : widget.style,
          recognizer: widget.enableHighlight ? recognizer : null,
        ),
      );
    }

    _cachedSpans = spans;
    _cachedFullText = widget.fullText;
    _cachedSelectedAyah = _selectedAyah;
  }

  void _handleAyahTap(int ayahId) {
    if (widget.enableHighlight) {
      setState(() {
        _selectedAyah = _selectedAyah == ayahId ? -1 : ayahId;
      });
    }
    widget.onAyahSelection(ayahId);
  }
}
