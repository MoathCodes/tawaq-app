import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tawaq/core/utils/playback_duration.dart';
import 'package:tawaq/gen/fonts.gen.dart';

/// One ayah (or arbitrary) segment on the seek timeline.
class SeekBarSegment {
  /// Creates a [SeekBarSegment].
  const new({
    required this.index,
    required this.start,
    required this.end,
  });

  /// Segment identifier (ayah number for recitation).
  final int index;

  /// Start offset in the parent timeline.
  final Duration start;

  /// End offset in the parent timeline.
  final Duration end;
}

const _seekLogName = 'tawaq.recitation.seek';
const _previewSegmentCount = 5;
const _minimumSegmentHighlightWidth = 4.0;

List<SeekBarSegment> _sortedSegments(List<SeekBarSegment> segments) {
  return List<SeekBarSegment>.from(segments)
    ..sort((a, b) => a.start.compareTo(b.start));
}

/// Resolves the segment containing [position], clamping outside the timeline.
@visibleForTesting
int? segmentIndexForPosition(
  List<SeekBarSegment> segments,
  Duration position,
) {
  if (segments.isEmpty) return null;

  final sorted = _sortedSegments(segments);
  final positionMs = position.inMilliseconds;
  for (final segment in sorted) {
    if (positionMs >= segment.start.inMilliseconds &&
        positionMs < segment.end.inMilliseconds) {
      return segment.index;
    }
  }

  if (positionMs < sorted.first.start.inMilliseconds) {
    return sorted.first.index;
  }
  return sorted.last.index;
}

/// Returns the start of the segment containing [position].
@visibleForTesting
Duration segmentStartForPosition(
  List<SeekBarSegment> segments,
  Duration position,
) {
  final index = segmentIndexForPosition(segments, position);
  if (index == null) return position;
  for (final segment in segments) {
    if (segment.index == index) return segment.start;
  }
  return position;
}

/// Returns a stable, contiguous preview window around [focusSegmentIndex].
///
/// The window shifts at either end so a five-ayah row remains full whenever
/// enough segments exist. Its geometry is presentation-only and never affects
/// timeline hit-testing.
@visibleForTesting
List<SeekBarSegment> previewSegmentsForFocus(
  List<SeekBarSegment> segments,
  int focusSegmentIndex, {
  int maxVisible = _previewSegmentCount,
}) {
  if (segments.isEmpty || maxVisible <= 0) return const [];
  final sorted = _sortedSegments(segments);
  return _previewSegmentsForFocusSorted(
    sorted,
    focusSegmentIndex,
    maxVisible: maxVisible,
  );
}

List<SeekBarSegment> _previewSegmentsForFocusSorted(
  List<SeekBarSegment> sorted,
  int focusSegmentIndex, {
  int maxVisible = _previewSegmentCount,
}) {
  if (sorted.isEmpty || maxVisible <= 0) return const [];
  final focus = sorted.indexWhere((s) => s.index == focusSegmentIndex);
  if (focus < 0) return const [];

  final count = min(maxVisible, sorted.length);
  final lastStart = sorted.length - count;
  final start = (focus - count ~/ 2).clamp(0, lastStart);
  return sorted.sublist(start, start + count);
}

/// Per-ayah repeat state shown beside the active ayah.
class RepeatStatus {
  /// Creates [RepeatStatus].
  const new({
    required this.remaining,
    required this.total,
    required this.segmentIndex,
  });

  /// Plays remaining, including the pass currently playing.
  final int remaining;

  /// Total plays configured for each ayah.
  final int total;

  /// [SeekBarSegment.index] of the ayah currently being repeated.
  final int segmentIndex;

  /// Current pass, clamped to the configured repeat range.
  int get current => (total - remaining + 1).clamp(1, max(1, total));
}

/// Visual tokens for [SegmentedSeekBar].
class SegmentedSeekBarStyle {
  /// Creates a [SegmentedSeekBarStyle].
  const new({
    required this.activeColor,
    required this.inactiveColor,
    required this.bufferedColor,
    required this.thumbColor,
    required this.thumbBorderColor,
    required this.repeatBadgeColor,
    required this.repeatBadgeTextColor,
    required this.repeatPulseColor,
    required this.tooltipTextStyle,
    required this.tooltipBackgroundColor,
    required this.tooltipBorderColor,
    required this.ayahGlowColor,
    required this.thumbRadius,
    required this.trackHeight,
    required this.previewRadius,
    required this.thumbTweenDuration,
    required this.snapScaleDuration,
    required this.pulseDuration,
    this.revealDuration,
    this.ayahGlowDuration = const Duration(milliseconds: 2400),
  });

  /// Color of the played portion.
  final Color activeColor;

  /// Color of the unplayed portion.
  final Color inactiveColor;

  /// Color of seekable buffered ranges.
  final Color bufferedColor;

  /// Fill color of the playback thumb.
  final Color thumbColor;

  /// Border color of the playback thumb.
  final Color thumbBorderColor;

  /// Background color of repeat details.
  final Color repeatBadgeColor;

  /// Foreground color of the idle repeat badge.
  final Color repeatBadgeTextColor;

  /// Color used to pulse the repeating ayah interval.
  final Color repeatPulseColor;

  /// Base text style for preview content.
  final TextStyle tooltipTextStyle;

  /// Background color of the ayah preview.
  final Color tooltipBackgroundColor;

  /// Border color of the ayah preview and its chips.
  final Color tooltipBorderColor;

  /// Color of the idle current-ayah glow.
  final Color ayahGlowColor;

  /// Radius of the playback thumb.
  final double thumbRadius;

  /// Height of the visible continuous track.
  final double trackHeight;

  /// Border radius of the floating ayah preview.
  final BorderRadius previewRadius;

  /// Duration of ordinary thumb movement.
  final Duration thumbTweenDuration;

  /// Duration of the seek-commit thumb pulse.
  final Duration snapScaleDuration;

  /// Duration of the repeating-ayah pulse.
  final Duration pulseDuration;

  /// Duration of the preview entrance animation.
  final Duration? revealDuration;

  /// Duration of the idle current-ayah glow.
  final Duration ayahGlowDuration;
}

/// A continuous seek bar with timing-aware ayah previews.
class SegmentedSeekBar extends StatefulWidget {
  /// Creates a [SegmentedSeekBar].
  const new({
    required this.position,
    required this.duration,
    required this.segments,
    required this.onSeek,
    required this.style,
    required this.segmentLabel,
    required this.repeatLabel,
    required this.remainingLabel,
    required this.semanticsLabel,
    required this.unavailableLabel,
    this.segmentNumberLabel,
    this.segmentUthmaniExcerpt,
    this.segmentContentKey,
    this.enabled = true,
    this.bufferedRanges = const [],
    this.repeat,
    super.key,
  });

  /// Current audio position supplied by the player.
  final Duration position;

  /// Total seekable audio duration.
  final Duration duration;

  /// Whether pointer and keyboard interaction is enabled.
  final bool enabled;

  /// Timing-aware ayah intervals, or an empty list without timing data.
  final List<SeekBarSegment> segments;

  /// Seekable buffered intervals reported by the player.
  final List<(Duration start, Duration end)> bufferedRanges;

  /// Live per-ayah repeat state.
  final RepeatStatus? repeat;

  /// Called once when a tap or drag seek is committed.
  final ValueChanged<Duration> onSeek;

  /// Theme-derived visual tokens.
  final SegmentedSeekBarStyle style;

  /// Localized heading for an ayah segment.
  final String Function(int segmentIndex) segmentLabel;

  /// Localized compact ayah number.
  final String Function(int segmentIndex)? segmentNumberLabel;

  /// Loads the optional Uthmani preview for an ayah.
  final Future<String?> Function(int segmentIndex)? segmentUthmaniExcerpt;

  /// Stable identity for the text source, such as `(surah, moshaf)`.
  final Object? segmentContentKey;

  /// Localized current-pass/total label.
  final String Function(int current, int total) repeatLabel;

  /// Localized remaining-play count.
  final String Function(int remaining) remainingLabel;

  /// Localized accessible name for the slider.
  final String semanticsLabel;

  /// Localized value announced when seeking is unavailable.
  final String unavailableLabel;

  @override
  State<SegmentedSeekBar> createState() => _SegmentedSeekBarState();
}

class _SegmentedSeekBarState extends State<SegmentedSeekBar>
    with TickerProviderStateMixin {
  bool _dragging = false;
  bool _mouseInside = false;
  double _dragValue = 0;
  double? _hoverValue;
  int _focusedSegmentIndex = 0;
  bool _isRtl = false;
  final Map<int, Future<String?>> _uthmaniExcerptCache = {};
  late List<SeekBarSegment> _segments;
  late Map<int, SeekBarSegment> _segmentsByIndex;
  late List<(double, double)> _bufferedRanges;

  late final AnimationController _pulseController;
  late final AnimationController _snapController;
  late final Animation<double> _snapScale;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: widget.style.pulseDuration,
    );
    _snapController = AnimationController(
      vsync: this,
      duration: widget.style.snapScaleDuration,
    );
    _cacheSegments();
    _cacheBufferedRanges();
    _snapScale = Tween<double>(begin: 1, end: 1.22).animate(
      CurvedAnimation(parent: _snapController, curve: Curves.easeOut),
    );
    _syncFocusedSegmentFromPosition();
    _updateAnimations();
  }

  @override
  void didUpdateWidget(covariant SegmentedSeekBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.segmentContentKey != widget.segmentContentKey) {
      _uthmaniExcerptCache.clear();
    }
    if (!identical(oldWidget.segments, widget.segments)) {
      _cacheSegments();
    }
    if (!identical(oldWidget.bufferedRanges, widget.bufferedRanges) ||
        oldWidget.duration != widget.duration) {
      _cacheBufferedRanges();
    }
    if (oldWidget.style.pulseDuration != widget.style.pulseDuration) {
      _pulseController.duration = widget.style.pulseDuration;
    }
    if (oldWidget.position != widget.position ||
        oldWidget.segments != widget.segments) {
      _syncFocusedSegmentFromPosition();
    }
    _updateAnimations();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _snapController.dispose();
    super.dispose();
  }

  bool get _isPreviewing => _dragging || _hoverValue != null;

  double get _playbackValue => _valueForPosition(widget.position);

  double get _displayValue => _dragging ? _dragValue : _playbackValue;

  double? get _previewValue => _dragging ? _dragValue : _hoverValue;

  int? get _previewSegmentIndex {
    final value = _previewValue;
    if (value == null) return null;
    return segmentIndexForPosition(
      _segments,
      _positionForValue(value),
    );
  }

  int? get _playbackSegmentIndex => _segmentIndexForPosition(widget.position);

  void _updateAnimations() {
    if (widget.repeat != null && widget.repeat!.total > 1) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController
        ..stop()
        ..value = 0;
    }
  }

  void _cacheSegments() {
    _segments = _sortedSegments(widget.segments);
    _segmentsByIndex = {
      for (final segment in _segments) segment.index: segment,
    };
  }

  int? _segmentIndexForPosition(Duration position) {
    if (_segments.isEmpty) return null;
    final positionMs = position.inMilliseconds;
    var low = 0;
    var high = _segments.length - 1;
    while (low <= high) {
      final middle = (low + high) >> 1;
      final segment = _segments[middle];
      if (positionMs < segment.start.inMilliseconds) {
        high = middle - 1;
      } else if (positionMs >= segment.end.inMilliseconds) {
        low = middle + 1;
      } else {
        return segment.index;
      }
    }
    return positionMs < _segments.first.start.inMilliseconds
        ? _segments.first.index
        : _segments.last.index;
  }

  void _cacheBufferedRanges() {
    final durationMs = widget.duration.inMilliseconds;
    if (durationMs <= 0) {
      _bufferedRanges = const [];
      return;
    }
    _bufferedRanges = widget.bufferedRanges
        .map(
          (range) => (
            (range.$1.inMilliseconds / durationMs).clamp(0.0, 1.0),
            (range.$2.inMilliseconds / durationMs).clamp(0.0, 1.0),
          ),
        )
        .where((range) => range.$2 > range.$1)
        .toList(growable: false);
  }

  void _syncFocusedSegmentFromPosition() {
    final index = _playbackSegmentIndex;
    if (index != null) _focusedSegmentIndex = index;
  }

  double _valueForPosition(Duration position) {
    final durationMs = widget.duration.inMilliseconds;
    if (durationMs <= 0) return 0;
    return (position.inMilliseconds / durationMs).clamp(0.0, 1.0);
  }

  Duration _positionForValue(double value) {
    final durationMs = max(1, widget.duration.inMilliseconds);
    return Duration(milliseconds: (durationMs * value).round());
  }

  double _valueForLocalDx(double dx, double widgetWidth) {
    final radius = widget.style.thumbRadius;
    final trackWidth = max(1, widgetWidth - radius * 2).toDouble();
    final physical = ((dx - radius) / trackWidth).clamp(0.0, 1.0);
    return _isRtl ? 1.0 - physical : physical;
  }

  double _trackXForValue(double value, double trackWidth) {
    final physical = _isRtl ? 1.0 - value : value;
    return physical.clamp(0.0, 1.0) * trackWidth;
  }

  double _widgetXForValue(double value, double widgetWidth) {
    final radius = widget.style.thumbRadius;
    final trackWidth = max(0, widgetWidth - radius * 2).toDouble();
    return radius + _trackXForValue(value, trackWidth);
  }

  Duration _targetForValue(double value) {
    final raw = _positionForValue(value);
    final index = _segmentIndexForPosition(raw);
    return index == null ? raw : _segmentsByIndex[index]!.start;
  }

  SeekBarSegment? _segmentByIndex(int index) => _segmentsByIndex[index];

  String _numberLabel(int index) =>
      widget.segmentNumberLabel?.call(index) ?? '$index';

  Future<String?>? _excerptFor(int? index) {
    final loader = widget.segmentUthmaniExcerpt;
    if (index == null || loader == null) return null;
    return _uthmaniExcerptCache.putIfAbsent(
      index,
      () async {
        try {
          return await loader(index);
        } on Object {
          return null;
        }
      },
    );
  }

  void _setHoverValue(double? value) {
    if (_dragging || value == _hoverValue) return;
    setState(() => _hoverValue = value);
    _updateAnimations();
  }

  void _enterOrHover(double value) {
    _mouseInside = true;
    _setHoverValue(value);
  }

  void _exitHover() {
    _mouseInside = false;
    _setHoverValue(null);
  }

  void _startDrag(double value) {
    setState(() {
      _dragging = true;
      _dragValue = value.clamp(0.0, 1.0);
    });
    _updateAnimations();
  }

  void _updateDrag(double value) {
    if (!_dragging) return;
    setState(() => _dragValue = value.clamp(0.0, 1.0));
  }

  void _endDrag() {
    if (!_dragging) return;
    final target = _targetForValue(_dragValue);
    setState(() {
      _dragging = false;
      _hoverValue = _mouseInside ? _dragValue : null;
    });
    _updateAnimations();
    unawaited(
      _snapController.forward(from: 0).then((_) {
        if (mounted) _snapController.reverse();
      }),
    );
    _commitSeek(target);
  }

  void _commitSeek(Duration target) {
    developer.log(
      'scrub commit targetMs=${target.inMilliseconds}',
      name: _seekLogName,
    );
    widget.onSeek(target);
  }

  void _seekToSegment(int index) {
    final segment = _segmentByIndex(index);
    if (segment != null) _commitSeek(segment.start);
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (!widget.enabled || widget.segments.isEmpty || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final segments = _segments;
    var focus = segments.indexWhere((s) => s.index == _focusedSegmentIndex);
    if (focus < 0) focus = 0;
    final leftMovesBackward = !_isRtl;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        focus = leftMovesBackward
            ? max(0, focus - 1)
            : min(segments.length - 1, focus + 1);
      case LogicalKeyboardKey.arrowRight:
        focus = leftMovesBackward
            ? min(segments.length - 1, focus + 1)
            : max(0, focus - 1);
      case LogicalKeyboardKey.arrowDown:
        focus = max(0, focus - 1);
      case LogicalKeyboardKey.arrowUp:
        focus = min(segments.length - 1, focus + 1);
      case LogicalKeyboardKey.home:
        focus = 0;
      case LogicalKeyboardKey.end:
        focus = segments.length - 1;
      default:
        return KeyEventResult.ignored;
    }

    setState(() => _focusedSegmentIndex = segments[focus].index);
    _seekToSegment(segments[focus].index);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    _isRtl = Directionality.of(context) == TextDirection.rtl;
    final enabled = widget.enabled && widget.duration.inMilliseconds > 0;
    final previewValue = _previewValue;
    final previewIndex = _previewSegmentIndex;
    final playbackIndex = _playbackSegmentIndex;
    final repeat = widget.repeat;

    final semanticSegment = _dragging ? previewIndex : playbackIndex;
    final semanticPosition = _dragging
        ? _targetForValue(_dragValue)
        : widget.position;
    final semanticTime =
        '${formatPlaybackDuration(semanticPosition)} / ${formatPlaybackDuration(widget.duration)}';
    final semanticParts = <String>[
      if (semanticSegment != null) widget.segmentLabel(semanticSegment),
      semanticTime,
      if (repeat != null && repeat.total > 1)
        widget.repeatLabel(repeat.current, repeat.total),
      if (repeat != null && repeat.total > 1)
        widget.remainingLabel(repeat.remaining),
    ];

    return Semantics(
      slider: true,
      label: widget.semanticsLabel,
      value: enabled ? semanticParts.join(', ') : widget.unavailableLabel,
      enabled: enabled,
      child: Focus(
        onKeyEvent: _handleKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final radius = widget.style.thumbRadius;
            final trackWidth = max(0, width - radius * 2).toDouble();
            final displayValue = _displayValue.clamp(0.0, 1.0);
            final thumbCenter = _widgetXForValue(displayValue, width);
            final previewTrackX = previewValue == null
                ? null
                : _trackXForValue(previewValue, trackWidth);
            final previewAnchor = previewValue == null
                ? null
                : radius + previewTrackX!;
            final previewPosition = previewValue == null
                ? null
                : _positionForValue(previewValue);
            final neighbors = previewIndex == null
                ? const <SeekBarSegment>[]
                : _previewSegmentsForFocusSorted(_segments, previewIndex);
            final repeatDetails =
                repeat != null &&
                    repeat.total > 1 &&
                    repeat.segmentIndex == previewIndex
                ? (
                    progress: widget.repeatLabel(repeat.current, repeat.total),
                    remaining: widget.remainingLabel(repeat.remaining),
                  )
                : null;
            final idleRepeatLabel = repeat == null || repeat.total <= 1
                ? null
                : '${widget.remainingLabel(repeat.remaining)} · '
                      '${widget.repeatLabel(repeat.current, repeat.total)}';

            return MouseRegion(
              cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
              onEnter: enabled
                  ? (event) => _enterOrHover(
                      _valueForLocalDx(event.localPosition.dx, width),
                    )
                  : null,
              onHover: enabled
                  ? (event) => _enterOrHover(
                      _valueForLocalDx(event.localPosition.dx, width),
                    )
                  : null,
              onExit: (_) => _exitHover(),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapDown: enabled
                    ? (_) => Focus.of(context).requestFocus()
                    : null,
                onTapUp: enabled
                    ? (details) => _commitSeek(
                        _targetForValue(
                          _valueForLocalDx(details.localPosition.dx, width),
                        ),
                      )
                    : null,
                onHorizontalDragStart: enabled
                    ? (details) {
                        Focus.of(context).requestFocus();
                        _startDrag(
                          _valueForLocalDx(details.localPosition.dx, width),
                        );
                      }
                    : null,
                onHorizontalDragUpdate: enabled
                    ? (details) => _updateDrag(
                        _valueForLocalDx(details.localPosition.dx, width),
                      )
                    : null,
                onHorizontalDragEnd: enabled ? (_) => _endDrag() : null,
                onHorizontalDragCancel: enabled ? _endDrag : null,
                child: SizedBox(
                  height: 36,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: radius,
                        right: radius,
                        top: 8,
                        bottom: 8,
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, _) {
                            return CustomPaint(
                              key: const Key('continuous-seek-track'),
                              painter: SegmentedTrackPainter(
                                progress: displayValue,
                                bufferedRanges: _bufferedRanges,
                                activeColor: widget.style.activeColor,
                                inactiveColor: widget.style.inactiveColor,
                                bufferedColor: widget.style.bufferedColor,
                                repeatPulseColor: widget.style.repeatPulseColor,
                                ayahGlowColor: widget.style.ayahGlowColor,
                                enabled: enabled,
                                segments: _segments,
                                totalDurationMs: widget.duration.inMilliseconds,
                                trackHeight: widget.style.trackHeight,
                                pulseSegmentIndex:
                                    repeat != null && repeat.total > 1
                                    ? repeat.segmentIndex
                                    : null,
                                pulsePhase: _pulseController.value,
                                currentAyahIndex: !_isPreviewing
                                    ? playbackIndex
                                    : null,
                                previewSegmentIndex: previewIndex,
                                previewX: previewTrackX,
                                isRtl: _isRtl,
                              ),
                            );
                          },
                        ),
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween(end: thumbCenter),
                        duration: _dragging
                            ? Duration.zero
                            : widget.style.thumbTweenDuration,
                        curve: Curves.easeOutCubic,
                        builder: (context, center, child) => Positioned(
                          left: center - radius,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: ScaleTransition(
                              scale: _snapScale,
                              child: child,
                            ),
                          ),
                        ),
                        child: Container(
                          key: const Key('seek-thumb'),
                          width: radius * 2,
                          height: radius * 2,
                          decoration: BoxDecoration(
                            color: widget.style.thumbColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: widget.style.thumbBorderColor,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: widget.style.thumbColor.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 6,
                                spreadRadius: 0.5,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (previewAnchor != null && previewPosition != null)
                        _AyahPreviewCard(
                          style: widget.style,
                          anchorCenterX: previewAnchor,
                          availableWidth: width,
                          heading: previewIndex == null
                              ? formatPlaybackDuration(previewPosition)
                              : widget.segmentLabel(previewIndex),
                          timestamp: formatPlaybackDuration(previewPosition),
                          focusSegmentIndex: previewIndex,
                          segments: neighbors,
                          segmentNumberLabel: _numberLabel,
                          excerpt: _excerptFor(previewIndex),
                          repeatProgress: repeatDetails?.progress,
                          repeatRemaining: repeatDetails?.remaining,
                        ),
                      if (!_isPreviewing &&
                          repeat != null &&
                          idleRepeatLabel != null)
                        _RepeatBadge(
                          style: widget.style,
                          label: idleRepeatLabel,
                          segment: _segmentByIndex(repeat.segmentIndex),
                          duration: widget.duration,
                          width: width,
                          trackInset: radius,
                          isRtl: _isRtl,
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AyahPreviewCard extends StatelessWidget {
  const new({
    required this.style,
    required this.anchorCenterX,
    required this.availableWidth,
    required this.heading,
    required this.timestamp,
    required this.focusSegmentIndex,
    required this.segments,
    required this.segmentNumberLabel,
    this.excerpt,
    this.repeatProgress,
    this.repeatRemaining,
  });

  final SegmentedSeekBarStyle style;
  final double anchorCenterX;
  final double availableWidth;
  final String heading;
  final String timestamp;
  final int? focusSegmentIndex;
  final List<SeekBarSegment> segments;
  final String Function(int segmentIndex) segmentNumberLabel;
  final Future<String?>? excerpt;
  final String? repeatProgress;
  final String? repeatRemaining;

  @override
  Widget build(BuildContext context) {
    final cardWidth = min(300, availableWidth).toDouble();
    final left = (anchorCenterX - cardWidth / 2).clamp(
      0.0,
      max(0, availableWidth - cardWidth).toDouble(),
    );
    final previewDuration = style.revealDuration ?? style.thumbTweenDuration;
    final mutedText = style.tooltipTextStyle.copyWith(
      color: style.tooltipTextStyle.color?.withValues(alpha: 0.66),
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Positioned(
      key: const Key('ayah-preview-positioned'),
      left: left,
      width: cardWidth,
      bottom: 31,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          key: const Key('ayah-preview-card'),
          tween: Tween(begin: 0.97, end: 1),
          duration: previewDuration,
          curve: Curves.easeOutCubic,
          builder: (context, scale, child) => Transform.scale(
            scale: scale,
            alignment: Alignment.bottomCenter,
            child: child,
          ),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: style.tooltipBackgroundColor,
              borderRadius: style.previewRadius,
              border: Border.all(color: style.tooltipBorderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        heading,
                        key: const Key('ayah-preview-heading'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: style.tooltipTextStyle.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (timestamp != heading) ...[
                      const SizedBox(width: 8),
                      Text(timestamp, style: mutedText),
                    ],
                  ],
                ),
                if (segments.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    textDirection: Directionality.of(context),
                    children: [
                      for (var i = 0; i < segments.length; i++) ...[
                        if (i > 0) const SizedBox(width: 4),
                        Expanded(
                          child: _PreviewAyahChip(
                            segmentIndex: segments[i].index,
                            label: segmentNumberLabel(segments[i].index),
                            selected: segments[i].index == focusSegmentIndex,
                            style: style,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                if (excerpt != null) ...[
                  const SizedBox(height: 8),
                  FutureBuilder<String?>(
                    future: excerpt,
                    builder: (context, snapshot) {
                      final text = snapshot.data?.trim();
                      if (text == null || text.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        text,
                        key: const Key('ayah-preview-excerpt'),
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: style.tooltipTextStyle.copyWith(
                          fontFamily: FontFamily.uthmanicHafs,
                          fontSize: 12,
                          height: 1.5,
                          fontWeight: FontWeight.normal,
                        ),
                      );
                    },
                  ),
                ],
                if (repeatProgress != null && repeatRemaining != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    key: const Key('ayah-preview-repeat'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: style.repeatBadgeColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: style.repeatBadgeColor.withValues(alpha: 0.36),
                      ),
                    ),
                    child: Text(
                      '$repeatRemaining · $repeatProgress',
                      style: style.tooltipTextStyle.copyWith(
                        color: style.repeatBadgeColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewAyahChip extends StatelessWidget {
  const new({
    required this.segmentIndex,
    required this.label,
    required this.selected,
    required this.style,
  });

  final int segmentIndex;
  final String label;
  final bool selected;
  final SegmentedSeekBarStyle style;

  @override
  Widget build(BuildContext context) {
    final selectedBackground = Color.lerp(
      style.tooltipBackgroundColor,
      style.activeColor,
      0.18,
    )!;
    return AnimatedContainer(
      key: selected
          ? const Key('preview-ayah-focused')
          : ValueKey('preview-ayah-$segmentIndex'),
      duration: style.thumbTweenDuration,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? selectedBackground : Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: selected
              ? style.activeColor.withValues(alpha: 0.58)
              : style.tooltipBorderColor,
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.fade,
        style: style.tooltipTextStyle.copyWith(
          color: selected
              ? style.activeColor
              : style.tooltipTextStyle.color?.withValues(alpha: 0.7),
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _RepeatBadge extends StatelessWidget {
  const new({
    required this.style,
    required this.label,
    required this.segment,
    required this.duration,
    required this.width,
    required this.trackInset,
    required this.isRtl,
  });

  final SegmentedSeekBarStyle style;
  final String label;
  final SeekBarSegment? segment;
  final Duration duration;
  final double width;
  final double trackInset;
  final bool isRtl;

  @override
  Widget build(BuildContext context) {
    final item = segment;
    final durationMs = duration.inMilliseconds;
    if (item == null || durationMs <= 0) return const SizedBox.shrink();

    final midpoint =
        (item.start.inMilliseconds + item.end.inMilliseconds) / 2 / durationMs;
    final trackWidth = max(0, width - trackInset * 2).toDouble();
    final center =
        trackInset +
        (isRtl ? trackWidth * (1 - midpoint) : trackWidth * midpoint);
    const badgeWidth = 132.0;
    final left = (center - badgeWidth / 2).clamp(
      0.0,
      max(0, width - badgeWidth).toDouble(),
    );

    return Positioned(
      key: const Key('repeat-badge-positioned'),
      left: left,
      width: min(badgeWidth, width),
      bottom: 28,
      child: IgnorePointer(
        child: Container(
          key: const Key('repeat-badge'),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: style.repeatBadgeColor,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style.tooltipTextStyle.copyWith(
              color: style.repeatBadgeTextColor,
              fontSize: 10,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the stable continuous timeline and non-geometric ayah indicators.
@visibleForTesting
class SegmentedTrackPainter extends CustomPainter {
  /// Creates a [SegmentedTrackPainter].
  const new({
    required this.progress,
    required this.bufferedRanges,
    required this.activeColor,
    required this.inactiveColor,
    required this.bufferedColor,
    required this.repeatPulseColor,
    required this.ayahGlowColor,
    required this.enabled,
    required this.segments,
    required this.totalDurationMs,
    required this.trackHeight,
    this.pulseSegmentIndex,
    this.pulsePhase = 0,
    this.currentAyahIndex,
    this.glowPhase = 0,
    this.previewSegmentIndex,
    this.previewX,
    this.isRtl = false,
  });

  /// Normalized playback progress.
  final double progress;

  /// Normalized buffered ranges.
  final List<(double, double)> bufferedRanges;

  /// Played-track color.
  final Color activeColor;

  /// Unplayed-track color.
  final Color inactiveColor;

  /// Buffered-range color.
  final Color bufferedColor;

  /// Repeating-ayah pulse color.
  final Color repeatPulseColor;

  /// Idle current-ayah glow color.
  final Color ayahGlowColor;

  /// Whether to paint enabled state.
  final bool enabled;

  /// Timing-aware ayah intervals.
  final List<SeekBarSegment> segments;

  /// Total timeline duration in milliseconds.
  final int totalDurationMs;

  /// Visible track height.
  final double trackHeight;

  /// Ayah receiving the repeat pulse.
  final int? pulseSegmentIndex;

  /// Normalized repeat pulse animation value.
  final double pulsePhase;

  /// Ayah receiving the idle playback glow.
  final int? currentAyahIndex;

  /// Normalized idle glow animation value.
  final double glowPhase;

  /// Ayah highlighted by the pointer preview.
  final int? previewSegmentIndex;

  /// Pointer preview position in painter-local pixels.
  final double? previewX;

  /// Whether chronological progress runs right-to-left.
  final bool isRtl;

  double _fractionToX(double fraction, double width) =>
      isRtl ? width * (1 - fraction) : width * fraction;

  /// True-timeline rect for one ayah, expanded only for visibility.
  @visibleForTesting
  Rect? segmentRectOnTrack(
    int index,
    Size size, {
    double minimumWidth = 0,
  }) {
    if (totalDurationMs <= 0) return null;
    for (final segment in segments) {
      if (segment.index != index) continue;
      final start = _fractionToX(
        segment.start.inMilliseconds / totalDurationMs,
        size.width,
      );
      final end = _fractionToX(
        segment.end.inMilliseconds / totalDurationMs,
        size.width,
      );
      var left = min(start, end);
      var right = max(start, end);
      if (right - left < minimumWidth) {
        final center = (left + right) / 2;
        left = (center - minimumWidth / 2).clamp(0.0, size.width);
        right = (center + minimumWidth / 2).clamp(0.0, size.width);
        if (right - left < minimumWidth && size.width >= minimumWidth) {
          if (left == 0) right = minimumWidth;
          if (right == size.width) left = size.width - minimumWidth;
        }
      }
      return Rect.fromLTRB(left, 0, right, size.height);
    }
    return null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final stroke = trackHeight.clamp(2.0, size.height);
    final line = Paint()
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final disabledAlpha = enabled ? 1.0 : 0.4;

    line.color = inactiveColor.withValues(
      alpha: inactiveColor.a * disabledAlpha,
    );
    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), line);

    if (enabled) {
      line.color = bufferedColor;
      for (final (start, end) in bufferedRanges) {
        final x1 = _fractionToX(start, size.width);
        final x2 = _fractionToX(end, size.width);
        canvas.drawLine(
          Offset(min(x1, x2), centerY),
          Offset(max(x1, x2), centerY),
          line,
        );
      }
    }

    final progressX = _fractionToX(progress.clamp(0.0, 1.0), size.width);
    line.color = activeColor.withValues(
      alpha: activeColor.a * disabledAlpha,
    );
    canvas.drawLine(
      isRtl ? Offset(size.width, centerY) : Offset(0, centerY),
      Offset(progressX, centerY),
      line,
    );

    if (!enabled) return;

    if (currentAyahIndex != null) {
      final rect = segmentRectOnTrack(
        currentAyahIndex!,
        size,
        minimumWidth: _minimumSegmentHighlightWidth,
      );
      if (rect != null) {
        final height = stroke * (1.5 + glowPhase * 0.6);
        final glow = Rect.fromCenter(
          center: Offset(rect.center.dx, centerY),
          width: rect.width,
          height: height,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(glow, Radius.circular(height / 2)),
          Paint()
            ..color = ayahGlowColor.withValues(
              alpha: 0.14 + glowPhase * 0.16,
            ),
        );
      }
    }

    if (pulseSegmentIndex != null) {
      final rect = segmentRectOnTrack(
        pulseSegmentIndex!,
        size,
        minimumWidth: _minimumSegmentHighlightWidth,
      );
      if (rect != null) {
        final height = stroke * 2.2;
        final pulse = Rect.fromCenter(
          center: Offset(rect.center.dx, centerY),
          width: rect.width,
          height: height,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(pulse, Radius.circular(height / 2)),
          Paint()
            ..color = repeatPulseColor.withValues(
              alpha: 0.14 + pulsePhase * 0.22,
            ),
        );
      }
    }

    if (previewSegmentIndex != null) {
      final rect = segmentRectOnTrack(
        previewSegmentIndex!,
        size,
        minimumWidth: _minimumSegmentHighlightWidth,
      );
      if (rect != null) {
        final height = max(8, stroke * 2.5).toDouble();
        final highlight = Rect.fromCenter(
          center: Offset(rect.center.dx, centerY),
          width: rect.width,
          height: height,
        );
        canvas
          ..drawRRect(
            RRect.fromRectAndRadius(highlight, Radius.circular(height / 2)),
            Paint()..color = activeColor.withValues(alpha: 0.24),
          )
          ..drawRRect(
            RRect.fromRectAndRadius(highlight, Radius.circular(height / 2)),
            Paint()
              ..color = activeColor.withValues(alpha: 0.58)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1,
          );
      }
    }

    if (previewX != null) {
      final x = previewX!.clamp(0.0, size.width);
      canvas
        ..drawLine(
          Offset(x, centerY - 7),
          Offset(x, centerY + 7),
          Paint()
            ..color = activeColor
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round,
        )
        ..drawCircle(
          Offset(x, centerY),
          2.5,
          Paint()..color = activeColor,
        );
    }
  }

  @override
  bool shouldRepaint(covariant SegmentedTrackPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.bufferedRanges != bufferedRanges ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor ||
        oldDelegate.bufferedColor != bufferedColor ||
        oldDelegate.repeatPulseColor != repeatPulseColor ||
        oldDelegate.ayahGlowColor != ayahGlowColor ||
        oldDelegate.enabled != enabled ||
        oldDelegate.segments != segments ||
        oldDelegate.totalDurationMs != totalDurationMs ||
        oldDelegate.trackHeight != trackHeight ||
        oldDelegate.pulseSegmentIndex != pulseSegmentIndex ||
        oldDelegate.pulsePhase != pulsePhase ||
        oldDelegate.currentAyahIndex != currentAyahIndex ||
        oldDelegate.glowPhase != glowPhase ||
        oldDelegate.previewSegmentIndex != previewSegmentIndex ||
        oldDelegate.previewX != previewX ||
        oldDelegate.isRtl != isRtl;
  }
}
