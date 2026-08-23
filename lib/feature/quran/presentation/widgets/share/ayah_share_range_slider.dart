import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/quran/domain/services/ayah_share_logic.dart';
import 'package:tawaq/feature/quran/presentation/widgets/surah_name_text.dart';

/// Reference strings for ayahs on a share-dialog page.
class AyahSharePageReferences {
  /// Creates page ayah reference data for the share range slider.
  const new({
    required this.full,
    required this.compact,
    required this.labeledMarkIndices,
  });

  /// Full references for tooltips and accessibility.
  final Map<int, String> full;

  /// Short references for slider marks and the range description.
  final Map<int, String> compact;

  /// Ayah indices on the page that should render a mark label.
  final Set<int> labeledMarkIndices;
}

/// Discrete range slider for selecting contiguous ayahs on a single page.
///
/// Kept as a [StatefulWidget] so [FSlider]'s managed controller is not reset
/// on every parent rebuild.
class AyahShareRangeSlider extends StatefulWidget {
  /// Creates a page ayah range slider.
  const new({
    required this.pageNumber,
    required this.pageAyahIds,
    required this.references,
    required this.initialIndex,
    required this.onRangeChanged,
    super.key,
  });

  final int pageNumber;
  final List<int> pageAyahIds;
  final AyahSharePageReferences references;
  final int initialIndex;
  final void Function(int start, int end) onRangeChanged;

  static const double _markLabelMaxWidth = 72;

  @override
  State<AyahShareRangeSlider> createState() => _AyahShareRangeSliderState();
}

class _AyahShareRangeSliderState extends State<AyahShareRangeSlider> {
  late int _rangeStart;
  late int _rangeEnd;
  late int _sliderGeneration;

  @override
  void initState() {
    super.initState();
    _sliderGeneration = 0;
    _resetRange(widget.initialIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onRangeChanged(_rangeStart, _rangeEnd);
    });
  }

  @override
  void didUpdateWidget(covariant AyahShareRangeSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex ||
        oldWidget.pageAyahIds.length != widget.pageAyahIds.length) {
      _sliderGeneration++;
      _resetRange(widget.initialIndex);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onRangeChanged(_rangeStart, _rangeEnd);
      });
    }
  }

  void _resetRange(int anchorIndex) {
    final maxIndex = widget.pageAyahIds.length - 1;
    final index = anchorIndex.clamp(0, maxIndex);
    _rangeStart = index;
    _rangeEnd = index;
  }

  void _handleSliderChange(FSliderValue value) {
    final count = widget.pageAyahIds.length;
    final start = AyahShareLogic.sliderValueToAyahIndex(value.min, count);
    final end = AyahShareLogic.sliderValueToAyahIndex(value.max, count);
    if (_rangeStart == start && _rangeEnd == end) return;
    setState(() {
      _rangeStart = start;
      _rangeEnd = end;
    });
    widget.onRangeChanged(start, end);
  }

  String _referenceFor(
    int index, {
    required Map<int, String> references,
    required String fallback,
  }) {
    return references[widget.pageAyahIds[index]] ?? fallback;
  }

  Widget? _buildMarkLabel(BuildContext context, int index) {
    if (!widget.references.labeledMarkIndices.contains(index)) return null;

    final theme = context.theme;
    final ayahId = widget.pageAyahIds[index];
    final compact = _referenceFor(
      index,
      references: widget.references.compact,
      fallback: '$ayahId',
    );
    final full = _referenceFor(
      index,
      references: widget.references.full,
      fallback: compact,
    );

    return Tooltip(
      message: full,
      child: SizedBox(
        width: AyahShareRangeSlider._markLabelMaxWidth,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: AyahReferenceText(
            compact,
            style: theme.typography.body.xs,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pageAyahIds.length <= 1) {
      final ref = _referenceFor(
        0,
        references: widget.references.compact,
        fallback: '${widget.pageAyahIds.first}',
      );
      return AyahReferenceText(
        ref,
        style: context.theme.typography.body.sm.copyWith(
          color: context.theme.colors.mutedForeground,
        ),
      );
    }

    final count = widget.pageAyahIds.length;
    final startRef = _referenceFor(
      _rangeStart,
      references: widget.references.compact,
      fallback: '${widget.pageAyahIds[_rangeStart]}',
    );
    final endRef = _referenceFor(
      _rangeEnd,
      references: widget.references.compact,
      fallback: '${widget.pageAyahIds[_rangeEnd]}',
    );
    final l10n = context.l10n;
    final verseCount = _rangeEnd - _rangeStart + 1;
    final verseCountLabel = l10n.shareVerseCount(verseCount);
    final rangeDescription = startRef == endRef
        ? l10n.shareRangeSingleDescription(startRef, verseCountLabel)
        : l10n.shareRangeDescription(startRef, endRef, verseCountLabel);

    return ClipRect(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: FSlider(
          key: ValueKey(
            'ayah-share-range-${widget.pageNumber}-$_sliderGeneration',
          ),
          control: .managedDiscreteRange(
            initial: FSliderValue(
              min: AyahShareLogic.ayahIndexToSliderValue(_rangeStart, count),
              max: AyahShareLogic.ayahIndexToSliderValue(_rangeEnd, count),
            ),
            onChange: _handleSliderChange,
          ),
          label: Text(l10n.shareRangeOnPage(widget.pageNumber)),
          description: Text(rangeDescription),
          marks: [
            for (var i = 0; i < count; i++)
              FSliderMark.mark(
                value: AyahShareLogic.ayahIndexToSliderValue(i, count),
                label: _buildMarkLabel(context, i),
              ),
          ],
          tooltipBuilder: (_, value) {
            final index = AyahShareLogic.sliderValueToAyahIndex(value, count);
            return Text(
              _referenceFor(
                index,
                references: widget.references.full,
                fallback: '${widget.pageAyahIds[index]}',
              ),
            );
          },
          semanticValueFormatterCallback: (value) {
            final index = AyahShareLogic.sliderValueToAyahIndex(value, count);
            return _referenceFor(
              index,
              references: widget.references.full,
              fallback: '${widget.pageAyahIds[index]}',
            );
          },
        ),
      ),
    );
  }
}
