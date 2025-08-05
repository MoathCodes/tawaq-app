import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mushaf_reader/src/data/models/ayah_fragment.dart';

/// Displays part of the page text with per-ayah mouse-over / tap highlight.
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
  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];

    for (final frag in widget.ayahs) {
      final textSlice = widget.fullText.substring(frag.start, frag.end);
      spans.add(
        TextSpan(
          text: textSlice,
          style: _selectedAyah == frag.ayahId
              ? widget.activeStyle ?? widget.style
              : widget.style,
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              if (widget.enableHighlight) {
                setState(() {
                  _selectedAyah == frag.ayahId
                      ? _selectedAyah = -1
                      : _selectedAyah = frag.ayahId;
                });
              }
              widget.onAyahSelection(frag.ayahId);
            },
        ),
      );
    }

    return RichText(
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
      text: TextSpan(children: spans),
    );
  }

  @override
  void dispose() {
    _selectedAyah = -1;
    super.dispose();
  }

  @override
  void initState() {
    _selectedAyah = -1;
    super.initState();
  }
}
