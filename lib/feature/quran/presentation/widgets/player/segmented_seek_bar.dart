import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';
import 'dart:ui' show FontFeature, lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tawaq/core/utils/playback_duration.dart';
import 'package:tawaq/gen/fonts.gen.dart';

/// One ayah (or arbitrary) segment on the seek track.
class SeekBarSegment {
  /// Creates a [SeekBarSegment].
  const SeekBarSegment({
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

/// Layout of one ayah segment in the fisheye lens row.
@immutable
class LensSegmentLayout {
  /// Creates a [LensSegmentLayout].
  const LensSegmentLayout({
    required this.index,
    required this.rect,
    required this.startFrac,
    required this.endFrac,
    required this.isFocus,
    this.listDistance = 0,
    this.opacity = 1,
  });

  /// Ayah index for this segment.
  final int index;

  /// Pixel rect of the segment pill.
  final Rect rect;

  /// Timeline start fraction (0..1).
  final double startFrac;

  /// Timeline end fraction (0..1).
  final double endFrac;

  /// Whether this is the hovered/focus segment.
  final bool isFocus;

  /// List distance from focus (0 = focus ayah).
  final int listDistance;

  /// Fade for distant segments during lens reveal.
  final double opacity;
}

/// Gap between lens segments at full reveal.
const kLensGap = 2.0;

/// Tallest lens pill height at full reveal (drawer-compact).
const kLensMaxHeight = 20.0;

/// Max share of track width for the focus pill.
const kLensMaxFocusWidthFraction = 0.18;

/// Inactive spine height drawn behind lens pills.
const kLensSpineHeight = 5.0;

const _seekLogName = 'tawaq.recitation.seek';

/// Drawer-compact fisheye flex tiers (normalized to [trackWidth]).
const _kLensFlexFocus = 12.0;
const _kLensFlexD1 = 7.0;
const _kLensFlexD2 = 4.0;
const _kLensFlexD3 = 2.0;
const _kLensFlexMin = 0.1;

const _kLensHeightFocus = 20.0;
const _kLensHeightD1 = 14.0;
const _kLensHeightD2 = 10.0;
const _kLensHeightD3 = 7.0;
const _kLensHeightDistant = 5.0;

List<SeekBarSegment> _sortedSegments(List<SeekBarSegment> segments) {
  return List<SeekBarSegment>.from(segments)
    ..sort((a, b) => a.start.compareTo(b.start));
}

/// List index for an ayah [segmentIndex], or null if missing.
@visibleForTesting
int? listIndexForSegment(
  List<SeekBarSegment> segments,
  int segmentIndex,
) {
  final sorted = _sortedSegments(segments);
  for (var i = 0; i < sorted.length; i++) {
    if (sorted[i].index == segmentIndex) return i;
  }
  return null;
}

@visibleForTesting
double lensFlexForDistance(int distance, double baseWeight) {
  return switch (distance) {
    0 => _kLensFlexFocus,
    1 => _kLensFlexD1,
    2 => _kLensFlexD2,
    3 => _kLensFlexD3,
    _ => max(_kLensFlexMin, baseWeight * 0.1),
  };
}

@visibleForTesting
double lensHeightForDistance(int distance, double trackHeight) {
  return switch (distance) {
    0 => _kLensHeightFocus,
    1 => _kLensHeightD1,
    2 => _kLensHeightD2,
    3 => _kLensHeightD3,
    _ => _kLensHeightDistant,
  };
}

@visibleForTesting
double lensOpacityForDistance(int distance) {
  return switch (distance) {
    0 => 1.0,
    1 => 0.9,
    2 => 0.7,
    3 => 0.5,
    _ => 0.45,
  };
}

/// Mirrors lens rects so chronological start sits on the reading-direction end.
@visibleForTesting
List<LensSegmentLayout> mirrorLensLayouts(
  List<LensSegmentLayout> layouts,
  double trackWidth,
) {
  if (layouts.isEmpty || trackWidth <= 0) return layouts;
  return [
    for (final layout in layouts)
      LensSegmentLayout(
        index: layout.index,
        rect: Rect.fromLTRB(
          trackWidth - layout.rect.right,
          layout.rect.top,
          trackWidth - layout.rect.left,
          layout.rect.bottom,
        ),
        startFrac: layout.startFrac,
        endFrac: layout.endFrac,
        isFocus: layout.isFocus,
        listDistance: layout.listDistance,
        opacity: layout.opacity,
      ),
  ];
}

/// Whether [dx] has moved far enough past the current focus edge into
/// [candidateRect] to allow a focus switch (boundary dead-zone).
@visibleForTesting
bool pastFocusHysteresis({
  required double dx,
  required Rect currentRect,
  required Rect candidateRect,
  double hysteresisPx = 6,
}) {
  final candidateIsRight = candidateRect.center.dx >= currentRect.center.dx;
  if (candidateIsRight) {
    return dx >= currentRect.right + hysteresisPx;
  }
  return dx <= currentRect.left - hysteresisPx;
}

/// Caps how many list-index steps focus may jump given pointer [travelPx].
///
/// Travel gates **every** step (including the first). Otherwise each hover
/// event can still advance +1 after a tiny edge cross, and raising
/// [pxPerStep] has no effect on that cascade.
@visibleForTesting
int stepLimitedFocusListIndex({
  required int currentListIndex,
  required int candidateListIndex,
  required double travelPx,
  double pxPerStep = 32,
}) {
  final delta = candidateListIndex - currentListIndex;
  if (delta == 0) return currentListIndex;

  final maxSteps = (travelPx / pxPerStep).floor();
  if (maxSteps <= 0) return currentListIndex;

  final stepped = delta.clamp(-maxSteps, maxSteps);
  return currentListIndex + stepped;
}

/// Timeline-anchored fisheye lens redistributing segment widths/heights.
@visibleForTesting
List<LensSegmentLayout> layoutSeekLens({
  required List<SeekBarSegment> segments,
  required double trackWidth,
  required int focusListIndex,
  required int totalDurationMs,
  required double revealStrength,
  required double trackHeight,
  bool isRtl = false,
}) {
  if (segments.isEmpty ||
      trackWidth <= 0 ||
      totalDurationMs <= 0 ||
      revealStrength <= 0) {
    return const [];
  }

  final sorted = _sortedSegments(segments);
  if (focusListIndex < 0 || focusListIndex >= sorted.length) {
    return const [];
  }

  final strength = revealStrength.clamp(0.0, 1.0);
  final gapCount = max(0, sorted.length - 1);
  final idealGap = kLensGap * strength;
  // Shrink gaps when many segments would consume the whole track.
  final maxGapBudget = trackWidth * 0.2;
  final gap = gapCount == 0 ? 0.0 : min(idealGap, maxGapBudget / gapCount);
  final totalGaps = gap * gapCount;
  final availableWidth = max(0, trackWidth - totalGaps);

  final weights = <double>[];
  for (var i = 0; i < sorted.length; i++) {
    final seg = sorted[i];
    final baseWeight =
        (seg.end.inMilliseconds - seg.start.inMilliseconds) / totalDurationMs;
    final distance = (i - focusListIndex).abs();
    final lensWeight = lensFlexForDistance(distance, baseWeight);
    weights.add(lerpDouble(baseWeight, lensWeight, strength)!);
  }

  final weightSum = weights.fold<double>(0, (a, b) => a + b);
  if (weightSum <= 0) return const [];

  final layouts = <LensSegmentLayout>[];
  var x = 0.0;
  final laneHeight = lerpDouble(trackHeight, kLensMaxHeight, strength)!;
  final centerY = laneHeight / 2;

  for (var i = 0; i < sorted.length; i++) {
    final seg = sorted[i];
    var width = availableWidth * weights[i] / weightSum;
    final distance = (i - focusListIndex).abs();
    if (width > 0 && width < 1.0 && sorted.length <= 40) {
      width = 1.0;
    }
    final height = lerpDouble(
      trackHeight,
      lensHeightForDistance(distance, trackHeight),
      strength,
    )!;
    final opacity = lerpDouble(
      1.0,
      lensOpacityForDistance(distance),
      strength,
    )!;

    layouts.add(
      LensSegmentLayout(
        index: seg.index,
        rect: Rect.fromCenter(
          center: Offset(x + width / 2, centerY),
          width: width,
          height: height,
        ),
        startFrac: seg.start.inMilliseconds / totalDurationMs,
        endFrac: seg.end.inMilliseconds / totalDurationMs,
        isFocus: i == focusListIndex,
        listDistance: distance,
        opacity: opacity,
      ),
    );

    x += width + gap;
  }

  final capped = _capFocusWidth(
    layouts: layouts,
    trackWidth: trackWidth,
    gap: gap,
    centerY: centerY,
  );
  return isRtl ? mirrorLensLayouts(capped, trackWidth) : capped;
}

List<LensSegmentLayout> _capFocusWidth({
  required List<LensSegmentLayout> layouts,
  required double trackWidth,
  required double gap,
  required double centerY,
}) {
  if (layouts.isEmpty) return layouts;

  final focusI = layouts.indexWhere((l) => l.isFocus);
  if (focusI < 0) return layouts;

  final maxFocusWidth = trackWidth * kLensMaxFocusWidthFraction;
  final widths = layouts.map((l) => l.rect.width).toList();
  if (widths[focusI] <= maxFocusWidth) return layouts;

  final overflow = widths[focusI] - maxFocusWidth;
  widths[focusI] = maxFocusWidth;
  final otherSum = widths.fold<double>(0, (sum, w) => sum + w) - maxFocusWidth;
  if (otherSum > 0) {
    final scale = (otherSum + overflow) / otherSum;
    for (var i = 0; i < widths.length; i++) {
      if (i != focusI) widths[i] *= scale;
    }
  }

  final capped = <LensSegmentLayout>[];
  var x = 0.0;
  for (var i = 0; i < layouts.length; i++) {
    final old = layouts[i];
    final w = widths[i];
    capped.add(
      LensSegmentLayout(
        index: old.index,
        rect: Rect.fromCenter(
          center: Offset(x + w / 2, centerY),
          width: w,
          height: old.rect.height,
        ),
        startFrac: old.startFrac,
        endFrac: old.endFrac,
        isFocus: old.isFocus,
        listDistance: old.listDistance,
        opacity: old.opacity,
      ),
    );
    x += w + gap;
  }
  return capped;
}

/// Resolves the ayah index to seek to for [position] (containing segment, then
/// start of that ayah — not nearest start by distance).
@visibleForTesting
int? segmentIndexForPosition(
  List<SeekBarSegment> segments,
  Duration position,
) {
  if (segments.isEmpty) return null;

  final posMs = position.inMilliseconds;
  final sorted = _sortedSegments(segments);

  for (final s in sorted) {
    final startMs = s.start.inMilliseconds;
    final endMs = s.end.inMilliseconds;
    if (posMs >= startMs && posMs < endMs) {
      return s.index;
    }
  }

  if (posMs < sorted.first.start.inMilliseconds) {
    return sorted.first.index;
  }
  return sorted.last.index;
}

/// Duration snapped to the start of the ayah containing [position].
@visibleForTesting
Duration segmentStartForPosition(
  List<SeekBarSegment> segments,
  Duration position,
) {
  final index = segmentIndexForPosition(segments, position);
  if (index == null) return position;
  for (final s in segments) {
    if (s.index == index) return s.start;
  }
  return position;
}

/// Hit-test segment ayah index from lens pill layout at [dx].
@visibleForTesting
int? segmentIndexAtLensDx(double dx, List<LensSegmentLayout> layouts) {
  if (layouts.isEmpty) return null;

  for (final layout in layouts) {
    final hit = Rect.fromLTRB(
      layout.rect.left - 1,
      layout.rect.top,
      layout.rect.right + 1,
      layout.rect.bottom,
    );
    if (hit.contains(Offset(dx, layout.rect.center.dy))) {
      return layout.index;
    }
  }

  LensSegmentLayout? nearest;
  var bestDist = double.infinity;
  for (final layout in layouts) {
    if (layout.rect.width <= 0) continue;
    final dist = (dx - layout.rect.center.dx).abs();
    if (dist < bestDist) {
      bestDist = dist;
      nearest = layout;
    }
  }
  return nearest?.index;
}

/// Interpolate lens layouts when focus ayah changes during hover.
@visibleForTesting
List<LensSegmentLayout> interpolateLensLayouts(
  List<LensSegmentLayout> from,
  List<LensSegmentLayout> to,
  double t,
) {
  if (from.isEmpty) return to;
  if (to.isEmpty) return from;
  if (from.length != to.length) return t < 0.5 ? from : to;

  final eased = t.clamp(0.0, 1.0);
  return [
    for (var i = 0; i < from.length; i++)
      LensSegmentLayout(
        index: to[i].index,
        rect: Rect.lerp(from[i].rect, to[i].rect, eased)!,
        startFrac: lerpDouble(from[i].startFrac, to[i].startFrac, eased)!,
        endFrac: lerpDouble(from[i].endFrac, to[i].endFrac, eased)!,
        isFocus: to[i].isFocus,
        listDistance: to[i].listDistance,
        opacity: lerpDouble(from[i].opacity, to[i].opacity, eased)!,
      ),
  ];
}

/// Per-ayah repeat state for pinning the thumb and showing a counter.
class RepeatStatus {
  /// Creates [RepeatStatus].
  const RepeatStatus({
    required this.current,
    required this.total,
    required this.segmentIndex,
  });

  /// Current repetition (1-based).
  final int current;

  /// Total repetitions configured.
  final int total;

  /// [SeekBarSegment.index] of the ayah being repeated.
  final int segmentIndex;

  /// Whether this is the final repetition (thumb follows playback).
  bool get isFinalPass => current >= total;
}

/// Visual tokens for [SegmentedSeekBar] — no theme dependency inside the widget.
class SegmentedSeekBarStyle {
  /// Creates a [SegmentedSeekBarStyle].
  const SegmentedSeekBarStyle({
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
    required this.segmentGapColor,
    required this.ayahGlowColor,
    required this.thumbRadius,
    required this.trackHeight,
    required this.thumbTweenDuration,
    required this.snapScaleDuration,
    required this.pulseDuration,
    this.revealDuration,
    this.ayahGlowDuration = const Duration(milliseconds: 2400),
  });

  /// Color of the played portion.
  final Color activeColor;

  /// Color of unplayed track.
  final Color inactiveColor;

  /// Buffered network segment color.
  final Color bufferedColor;

  /// Thumb fill.
  final Color thumbColor;

  /// Thumb border.
  final Color thumbBorderColor;

  /// Repeat counter badge background.
  final Color repeatBadgeColor;

  /// Repeat counter badge text.
  final Color repeatBadgeTextColor;

  /// Pulse overlay on repeating segment.
  final Color repeatPulseColor;

  /// Scrub tooltip label style.
  final TextStyle tooltipTextStyle;

  /// Scrub tooltip bubble background.
  final Color tooltipBackgroundColor;

  /// Scrub tooltip bubble border.
  final Color tooltipBorderColor;

  /// Background visible in gaps between magnified ayah pills.
  final Color segmentGapColor;

  /// Soft glow on the currently playing ayah when idle.
  final Color ayahGlowColor;

  /// Thumb radius in logical pixels.
  final double thumbRadius;

  /// Track height.
  final double trackHeight;

  /// Thumb position tween duration.
  final Duration thumbTweenDuration;

  /// Snap magnet scale animation duration.
  final Duration snapScaleDuration;

  /// Repeat segment pulse cycle duration.
  final Duration pulseDuration;

  /// Magnified lens fade in/out; defaults to [thumbTweenDuration].
  final Duration? revealDuration;

  /// Current-ayah breathe cycle when idle.
  final Duration ayahGlowDuration;
}

class SegmentedSeekBar extends StatefulWidget {
  /// Creates a [SegmentedSeekBar].
  const SegmentedSeekBar({
    required this.position,
    required this.duration,
    required this.segments,
    required this.onSeek,
    required this.style,
    required this.segmentLabel,
    required this.repeatLabel,
    required this.unavailableLabel,
    this.segmentNumberLabel,
    this.segmentUthmaniExcerpt,
    this.enabled = true,
    this.bufferedRanges = const [],
    this.repeat,
    super.key,
  });

  /// Current playback position.
  final Duration position;

  /// Total timeline duration.
  final Duration duration;

  /// Whether interaction is allowed.
  final bool enabled;

  /// Ayah (or other) segments along the track.
  final List<SeekBarSegment> segments;

  /// Buffered regions for network playback.
  final List<(Duration start, Duration end)> bufferedRanges;

  /// Per-ayah repeat state, or null when not repeating.
  final RepeatStatus? repeat;

  /// Called when the user finishes scrubbing.
  final ValueChanged<Duration> onSeek;

  /// Visual style tokens.
  final SegmentedSeekBarStyle style;

  /// Label for a segment index (e.g. "Ayah 5").
  final String Function(int segmentIndex) segmentLabel;

  /// Pill number label; defaults to western digits when null.
  final String Function(int segmentIndex)? segmentNumberLabel;

  /// Optional Uthmani excerpt for the scrub tooltip body.
  final Future<String?> Function(int segmentIndex)? segmentUthmaniExcerpt;

  /// Label for repeat progress (e.g. "Repeat 2 of 3").
  final String Function(int current, int total) repeatLabel;

  /// Semantics value when disabled.
  final String unavailableLabel;

  @override
  State<SegmentedSeekBar> createState() => _SegmentedSeekBarState();
}

class _SegmentedSeekBarState extends State<SegmentedSeekBar>
    with TickerProviderStateMixin {
  bool _dragging = false;
  bool _dragMoved = false;
  double _dragValue = 0;
  double? _dragStartDx;

  /// Pointer dx when focus last changed (travel budget anchor).
  double? _focusAnchorDx;
  int? _hoverSegmentIndex;
  double? _hoverCenterX;
  int _focusedSegmentIndex = 0;
  int? _revealSnapIndex;
  double? _revealCenterX;
  double _lastTrackWidth = 320;
  List<LensSegmentLayout> _fromFocusLayouts = const [];
  List<LensSegmentLayout> _lastTargetLayouts = const [];
  int? _prevFocusListIndex;
  final Map<int, String?> _uthmaniExcerptCache = {};

  /// Cached text direction — updated every build.
  bool _isRtl = false;

  /// Minimum dx movement before switching hovered segment (hysteresis).
  static const _kHoverHysteresisPx = 6.0;

  /// Pointer travel (px) required per focus list-index step — including the
  /// first. Must be large enough that successive hover events after a lens
  /// expand cannot cascade +1/+1/+1 without real movement.
  static const _kFocusPxPerStep = 14.0;

  late AnimationController _pulseController;
  late AnimationController _snapController;
  late AnimationController _revealController;
  late AnimationController _focusTransitionController;
  late AnimationController _ayahGlowController;
  late Animation<double> _snapScale;

  @override
  void initState() {
    super.initState();
    final style = widget.style;
    _pulseController = AnimationController(
      vsync: this,
      duration: style.pulseDuration,
    );
    _snapController = AnimationController(
      vsync: this,
      duration: style.snapScaleDuration,
    );
    _revealController = AnimationController(
      vsync: this,
      duration: style.revealDuration ?? style.thumbTweenDuration,
    );
    _focusTransitionController = AnimationController(
      vsync: this,
      duration: style.revealDuration ?? const Duration(milliseconds: 200),
    );
    _ayahGlowController = AnimationController(
      vsync: this,
      duration: style.ayahGlowDuration,
    );
    _snapScale = Tween<double>(begin: 1, end: 1.25).animate(
      CurvedAnimation(parent: _snapController, curve: Curves.easeOut),
    );
    _revealController.addStatusListener(_onRevealStatus);
    _syncFocusedSegmentFromPosition();
    _updatePulse();
    _updateAyahGlow();
  }

  void _onRevealStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed &&
        !_isRevealing &&
        (_revealSnapIndex != null || _revealCenterX != null)) {
      setState(() {
        _revealSnapIndex = null;
        _revealCenterX = null;
      });
    }
  }

  double _thumbCenterForValue(double value, double width) {
    final thumbRadius = widget.style.thumbRadius;
    final effective = _isRtl ? 1.0 - value : value;
    return thumbRadius + effective * (width - thumbRadius * 2);
  }

  @override
  void didUpdateWidget(covariant SegmentedSeekBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repeat != widget.repeat ||
        oldWidget.style.pulseDuration != widget.style.pulseDuration) {
      _updatePulse();
    }
    if (oldWidget.position != widget.position ||
        oldWidget.segments != widget.segments ||
        oldWidget.repeat != widget.repeat) {
      _syncFocusedSegmentFromPosition();
      _updateAyahGlow();
    }
  }

  void _updatePulse() {
    final repeating = widget.repeat != null && !widget.repeat!.isFinalPass;
    if (repeating) {
      unawaited(_pulseController.repeat(reverse: true));
    } else {
      _pulseController
        ..stop()
        ..value = 0;
    }
  }

  void _updateAyahGlow() {
    final shouldGlow = _shouldShowAyahGlow;
    if (shouldGlow) {
      if (!_ayahGlowController.isAnimating) {
        unawaited(_ayahGlowController.repeat(reverse: true));
      }
    } else {
      _ayahGlowController
        ..stop()
        ..value = 0;
    }
  }

  bool get _isRevealing => _dragging || _hoverSegmentIndex != null;

  bool get _shouldShowAyahGlow {
    if (widget.segments.isEmpty || _isRevealing) return false;
    final repeat = widget.repeat;
    if (repeat != null && !repeat.isFinalPass) return false;
    return _segmentIndexAt(_displayPosition) != null;
  }

  String _segmentNumberLabel(int index) =>
      widget.segmentNumberLabel?.call(index) ?? '$index';

  Future<String?> _cachedUthmaniExcerpt(int index) async {
    if (_uthmaniExcerptCache.containsKey(index)) {
      return _uthmaniExcerptCache[index];
    }
    final loader = widget.segmentUthmaniExcerpt;
    if (loader == null) return null;
    final text = await loader(index);
    if (mounted) _uthmaniExcerptCache[index] = text;
    return text;
  }

  int? get _scrubTooltipSegmentIndex {
    if (_dragging) {
      return segmentIndexForPosition(
        widget.segments,
        _positionFromValue(_dragValue),
      );
    }
    return _hoverSegmentIndex;
  }

  void _setRevealing(bool revealing) {
    final duration =
        widget.style.revealDuration ?? widget.style.thumbTweenDuration;
    if (revealing) {
      if (_revealController.value < 1.0) {
        unawaited(
          _revealController.animateTo(
            1,
            duration: duration,
            curve: Curves.easeOutCubic,
          ),
        );
      }
    } else if (_revealController.value > 0) {
      unawaited(
        _revealController.animateTo(
          0,
          duration: duration,
          curve: Curves.easeOutCubic,
        ),
      );
    }
    _updateAyahGlow();
  }

  void _resetFocusTransition() {
    _fromFocusLayouts = const [];
    _lastTargetLayouts = const [];
    _prevFocusListIndex = null;
    _focusTransitionController.value = 0;
  }

  void _beginRevealCollapse() {
    if (_dragging) return;
    _revealSnapIndex = _hoverSegmentIndex ?? _revealSnapIndex;
    _revealCenterX = _hoverCenterX ?? _revealCenterX;
    _setRevealing(false);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _snapController.dispose();
    _revealController.dispose();
    _focusTransitionController.dispose();
    _ayahGlowController.dispose();
    super.dispose();
  }

  double get _currentValue =>
      (_dragging ? _dragValue : _progressFromPosition(_displayPosition)).clamp(
        0.0,
        1.0,
      );

  Duration get _displayPosition {
    final repeat = widget.repeat;
    if (repeat != null &&
        !repeat.isFinalPass &&
        !_dragging &&
        _hoverSegmentIndex == null) {
      final seg = _segmentByIndex(repeat.segmentIndex);
      if (seg != null) return seg.start;
    }
    return widget.position;
  }

  SeekBarSegment? _segmentByIndex(int index) {
    for (final s in widget.segments) {
      if (s.index == index) return s;
    }
    return null;
  }

  double _progressFromPosition(Duration position) {
    final durationMs = widget.duration.inMilliseconds;
    if (durationMs <= 0) return 0;
    return (position.inMilliseconds / durationMs).clamp(0.0, 1.0);
  }

  Duration _positionFromValue(double value) {
    final durationMs = max(1, widget.duration.inMilliseconds);
    return Duration(milliseconds: (durationMs * value).round());
  }

  int? _segmentIndexAt(Duration position) =>
      segmentIndexForPosition(widget.segments, position);

  Duration _snappedPosition([double? value]) {
    return segmentStartForPosition(
      widget.segments,
      _positionFromValue(value ?? _currentValue),
    );
  }

  String _scrubLabelForValue(double value) {
    final snapIndex = segmentIndexForPosition(
      widget.segments,
      _positionFromValue(value),
    );
    if (snapIndex != null) {
      return widget.segmentLabel(snapIndex);
    }
    return formatPlaybackDuration(_positionFromValue(value));
  }

  double _valueFromLocalDx(double dx, double width) {
    final thumbRadius = widget.style.thumbRadius;
    final maxThumbCenter = width - thumbRadius * 2;
    if (maxThumbCenter <= 0) return 0;
    final raw = ((dx - thumbRadius) / maxThumbCenter).clamp(0.0, 1.0);
    return _isRtl ? 1.0 - raw : raw;
  }

  int? _segmentIndexFromLocalDx(
    double dx,
    double width, {
    int? focusHint,
    double revealStrength = 0,
  }) {
    if (widget.segments.isEmpty || widget.duration.inMilliseconds <= 0) {
      return null;
    }
    final lensIndex = _segmentIndexFromLensDx(
      dx: dx,
      width: width,
      focusSegmentIndex: focusHint,
      revealStrength: revealStrength,
    );
    if (lensIndex != null) return lensIndex;

    final value = _valueFromLocalDx(dx, width);
    return segmentIndexForPosition(
      widget.segments,
      _positionFromValue(value),
    );
  }

  int? _hoverSegmentIndexFromDx(
    double dx,
    double width, {
    int? focusHint,
    double revealStrength = 0,
  }) {
    if (widget.segments.isEmpty || widget.duration.inMilliseconds <= 0) {
      return null;
    }

    final lensIndex = _segmentIndexFromLensDx(
      dx: dx,
      width: width,
      focusSegmentIndex: focusHint ?? _hoverSegmentIndex ?? _revealSnapIndex,
      revealStrength: revealStrength,
    );
    if (lensIndex != null) return lensIndex;

    return _segmentIndexAt(_positionFromValue(_valueFromLocalDx(dx, width)));
  }

  int? _segmentIndexFromLensDx({
    required double dx,
    required double width,
    required int? focusSegmentIndex,
    required double revealStrength,
  }) {
    if (revealStrength < 0.05 || focusSegmentIndex == null) return null;

    final layouts = _trackLensLayouts(
      width: width,
      trackHeight: widget.style.trackHeight,
      focusSegmentIndex: focusSegmentIndex,
      revealStrength: revealStrength,
    );
    final hit = segmentIndexAtLensDx(dx, layouts);
    if (hit != null && hit != focusSegmentIndex) {
      LensSegmentLayout? current;
      LensSegmentLayout? candidate;
      for (final layout in layouts) {
        if (layout.index == focusSegmentIndex) current = layout;
        if (layout.index == hit) candidate = layout;
      }
      if (current != null &&
          candidate != null &&
          !pastFocusHysteresis(
            dx: dx,
            currentRect: current.rect,
            candidateRect: candidate.rect,
          )) {
        return focusSegmentIndex;
      }
      // Accept the first hit — do not re-layout and re-sample under the new
      // focus (that cascades past the pointer when the fisheye expands).
    }
    return hit;
  }

  /// Applies boundary dead-zone + travel-budgeted list-index stepping.
  int? _focusWithHysteresis({
    required int? candidate,
    required int? currentFocus,
    required double dx,
    required double width,
    required double revealStrength,
  }) {
    if (candidate == null ||
        currentFocus == null ||
        candidate == currentFocus) {
      return candidate;
    }

    Rect? currentRect;
    Rect? candidateRect;

    if (revealStrength >= 0.05) {
      final layouts = _trackLensLayouts(
        width: width,
        trackHeight: widget.style.trackHeight,
        focusSegmentIndex: currentFocus,
        revealStrength: max(revealStrength, 0.05),
      );
      for (final layout in layouts) {
        if (layout.index == currentFocus) currentRect = layout.rect;
        if (layout.index == candidate) candidateRect = layout.rect;
      }
    }

    if (currentRect == null || candidateRect == null) {
      final durationMs = widget.duration.inMilliseconds;
      if (durationMs <= 0) return candidate;
      final currentSeg = _segmentByIndex(currentFocus);
      final candidateSeg = _segmentByIndex(candidate);
      if (currentSeg == null || candidateSeg == null) return candidate;
      currentRect = _timelineSegmentRect(currentSeg, width, durationMs);
      candidateRect = _timelineSegmentRect(candidateSeg, width, durationMs);
    }

    if (!pastFocusHysteresis(
      dx: dx,
      currentRect: currentRect,
      candidateRect: candidateRect,
    )) {
      return currentFocus;
    }

    final currentList = listIndexForSegment(widget.segments, currentFocus);
    final candidateList = listIndexForSegment(widget.segments, candidate);
    if (currentList == null || candidateList == null) return candidate;

    // No free first step: travel since last focus change must unlock steps.
    // (When anchor is null, treat as zero travel so we stay sticky until set.)
    final travelPx = _focusAnchorDx == null
        ? 0.0
        : (dx - _focusAnchorDx!).abs();
    final steppedList = stepLimitedFocusListIndex(
      currentListIndex: currentList,
      candidateListIndex: candidateList,
      travelPx: travelPx,
      pxPerStep: _kFocusPxPerStep,
    );
    if (steppedList == currentList) return currentFocus;

    final sorted = _sortedSegments(widget.segments);
    if (steppedList < 0 || steppedList >= sorted.length) return currentFocus;
    return sorted[steppedList].index;
  }

  Rect _timelineSegmentRect(
    SeekBarSegment seg,
    double width,
    int durationMs,
  ) {
    final startFrac = seg.start.inMilliseconds / durationMs;
    final endFrac = seg.end.inMilliseconds / durationMs;
    final x1 = _isRtl ? width * (1.0 - startFrac) : width * startFrac;
    final x2 = _isRtl ? width * (1.0 - endFrac) : width * endFrac;
    return Rect.fromLTRB(min(x1, x2), 0, max(x1, x2), widget.style.trackHeight);
  }

  List<LensSegmentLayout> _displayLensLayouts({
    required List<LensSegmentLayout> target,
    required int? focusSegmentIndex,
  }) {
    final focusListIndex = focusSegmentIndex == null
        ? null
        : listIndexForSegment(widget.segments, focusSegmentIndex);

    if (focusListIndex != null && focusListIndex != _prevFocusListIndex) {
      if (_prevFocusListIndex != null &&
          _revealController.value > 0.9 &&
          _lastTargetLayouts.isNotEmpty) {
        _fromFocusLayouts = _lastTargetLayouts;
        _focusTransitionController.value = 0;
        unawaited(_focusTransitionController.forward());
      } else {
        _fromFocusLayouts = target;
        _focusTransitionController.value = 1;
      }
      _prevFocusListIndex = focusListIndex;
    } else if (focusListIndex == null) {
      _resetFocusTransition();
    }

    _lastTargetLayouts = target;

    final focusT = Curves.easeOutCubic.transform(
      _focusTransitionController.value,
    );
    if (focusT < 1 &&
        _fromFocusLayouts.isNotEmpty &&
        target.isNotEmpty &&
        _fromFocusLayouts.length == target.length) {
      return interpolateLensLayouts(_fromFocusLayouts, target, focusT);
    }
    return target;
  }

  List<LensSegmentLayout> _trackLensLayouts({
    required double width,
    required double trackHeight,
    required int? focusSegmentIndex,
    required double revealStrength,
  }) {
    if (focusSegmentIndex == null || revealStrength <= 0) return const [];

    final focusListIndex = listIndexForSegment(
      widget.segments,
      focusSegmentIndex,
    );
    if (focusListIndex == null) return const [];

    return layoutSeekLens(
      segments: widget.segments,
      trackWidth: width,
      focusListIndex: focusListIndex,
      totalDurationMs: widget.duration.inMilliseconds,
      revealStrength: revealStrength,
      trackHeight: trackHeight,
      isRtl: _isRtl,
    );
  }

  void _syncFocusedSegmentFromPosition() {
    final index = _segmentIndexAt(widget.position);
    if (index != null) _focusedSegmentIndex = index;
  }

  void _seekAtLocalDx(double dx, double width) {
    final revealStrength = max(_revealController.value, 0.01);
    final index = _segmentIndexFromLocalDx(
      dx,
      width,
      focusHint: _hoverSegmentIndex ?? _revealSnapIndex,
      revealStrength: revealStrength,
    );
    if (index != null) {
      _seekToSegment(index);
      return;
    }
    _commitSeek(
      segmentStartForPosition(
        widget.segments,
        _positionFromValue(_valueFromLocalDx(dx, width)),
      ),
    );
  }

  void _commitSeek(Duration target) {
    developer.log(
      'scrub commit targetMs=${target.inMilliseconds}',
      name: _seekLogName,
    );
    widget.onSeek(target);
  }

  void _seekToSegment(int index) {
    final seg = _segmentByIndex(index);
    if (seg != null) _commitSeek(seg.start);
  }

  void _onDragStart(double value) {
    _dragMoved = false;
    final width = _lastTrackWidth;
    final clamped = value.clamp(0.0, 1.0);
    final thumbX = _thumbCenterForValue(clamped, width);
    // Seed focus from current playback/thumb segment — do not jump on press.
    final snap =
        _segmentIndexAt(_displayPosition) ??
        segmentIndexForPosition(
          widget.segments,
          _positionFromValue(clamped),
        );
    setState(() {
      _dragging = true;
      _dragValue = clamped;
      _dragStartDx = thumbX;
      _focusAnchorDx = thumbX;
      _revealSnapIndex = snap;
      _revealCenterX = thumbX;
    });
    _setRevealing(true);
  }

  void _onDragUpdate(double value) {
    _dragMoved = true;
    final width = _lastTrackWidth;
    final clamped = value.clamp(0.0, 1.0);
    final revealStrength = max(_revealController.value, 0.01);
    final thumbX = _thumbCenterForValue(clamped, width);
    final startDx = _dragStartDx;
    // Hold seeded focus until the pointer has actually scrubbed a bit,
    // so pressing far from the thumb does not instantly jump the lens.
    if (startDx != null && (thumbX - startDx).abs() < _kHoverHysteresisPx) {
      setState(() {
        _dragValue = clamped;
        _revealCenterX = thumbX;
      });
      return;
    }
    final rawSnap =
        _segmentIndexFromLocalDx(
          thumbX,
          width,
          focusHint: _revealSnapIndex,
          revealStrength: revealStrength,
        ) ??
        segmentIndexForPosition(
          widget.segments,
          _positionFromValue(clamped),
        );
    final previousSnap = _revealSnapIndex;
    final snap = _focusWithHysteresis(
      candidate: rawSnap,
      currentFocus: _revealSnapIndex,
      dx: thumbX,
      width: width,
      revealStrength: revealStrength,
    );
    setState(() {
      _dragValue = clamped;
      _revealSnapIndex = snap;
      _revealCenterX = thumbX;
      if (snap != previousSnap && snap != null) {
        _focusAnchorDx = thumbX;
      }
    });
  }

  Future<void> _onDragEnd() async {
    if (!_dragging) return;
    final index = segmentIndexForPosition(
      widget.segments,
      _positionFromValue(_dragValue),
    );
    final seg = index != null ? _segmentByIndex(index) : null;
    final target = seg?.start ?? _positionFromValue(_dragValue);
    setState(() => _dragging = false);
    _dragStartDx = null;
    _focusAnchorDx = null;
    _beginRevealCollapse();
    unawaited(
      _snapController.forward(from: 0).then((_) {
        if (mounted) unawaited(_snapController.reverse());
      }),
    );
    _commitSeek(target);
  }

  List<(double, double)> _bufferedFractions() {
    final durationMs = widget.duration.inMilliseconds;
    if (durationMs <= 0 || widget.bufferedRanges.isEmpty) {
      return const [];
    }
    return widget.bufferedRanges
        .map(
          (r) => (
            (r.$1.inMilliseconds / durationMs).clamp(0.0, 1.0),
            (r.$2.inMilliseconds / durationMs).clamp(0.0, 1.0),
          ),
        )
        .where((e) => e.$2 > e.$1)
        .toList();
  }

  List<(double start, double end)> _segmentFractions() {
    final durationMs = widget.duration.inMilliseconds;
    if (durationMs <= 0) return const [];
    return widget.segments
        .map(
          (s) => (
            (s.start.inMilliseconds / durationMs).clamp(0.0, 1.0),
            (s.end.inMilliseconds / durationMs).clamp(0.0, 1.0),
          ),
        )
        .where((e) => e.$2 > e.$1)
        .toList();
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (!widget.enabled || widget.segments.isEmpty) {
      return KeyEventResult.ignored;
    }
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final indices = widget.segments.map((s) => s.index).toList();
    var focusIdx = indices.indexOf(_focusedSegmentIndex);
    if (focusIdx < 0) focusIdx = 0;

    // In RTL, left arrow means "next" (higher index) and right means "previous".
    final leftIsPrev = !_isRtl;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        if (leftIsPrev) {
          focusIdx = max(0, focusIdx - 1);
        } else {
          focusIdx = min(indices.length - 1, focusIdx + 1);
        }
        setState(() => _focusedSegmentIndex = indices[focusIdx]);
        _seekToSegment(indices[focusIdx]);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        if (leftIsPrev) {
          focusIdx = min(indices.length - 1, focusIdx + 1);
        } else {
          focusIdx = max(0, focusIdx - 1);
        }
        setState(() => _focusedSegmentIndex = indices[focusIdx]);
        _seekToSegment(indices[focusIdx]);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        focusIdx = max(0, focusIdx - 1);
        setState(() => _focusedSegmentIndex = indices[focusIdx]);
        _seekToSegment(indices[focusIdx]);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        focusIdx = min(indices.length - 1, focusIdx + 1);
        setState(() => _focusedSegmentIndex = indices[focusIdx]);
        _seekToSegment(indices[focusIdx]);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.home:
        setState(() => _focusedSegmentIndex = indices.first);
        _seekToSegment(indices.first);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.end:
        setState(() => _focusedSegmentIndex = indices.last);
        _seekToSegment(indices.last);
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  @override
  Widget build(BuildContext context) {
    _isRtl = Directionality.of(context) == TextDirection.rtl;
    final style = widget.style;
    final enabled = widget.enabled && widget.duration.inMilliseconds > 0;
    final value = _currentValue;
    final activeSegmentIndex = _dragging
        ? segmentIndexForPosition(
            widget.segments,
            _positionFromValue(value),
          )
        : widget.repeat?.segmentIndex ?? _segmentIndexAt(_displayPosition);
    final repeat = widget.repeat;
    final showScrubTip = enabled && (_dragging || _hoverSegmentIndex != null);
    final liveRevealing = _isRevealing;
    final glowPhase = _shouldShowAyahGlow
        ? Curves.easeInOut.transform(_ayahGlowController.value)
        : 0.0;

    final semanticValue = enabled
        ? () {
            final parts = <String>[];
            if (activeSegmentIndex != null) {
              parts.add(widget.segmentLabel(activeSegmentIndex));
            }
            final timePosition = _dragging
                ? _snappedPosition()
                : _displayPosition;
            parts.add(
              '${formatPlaybackDuration(timePosition)} / ${formatPlaybackDuration(widget.duration)}',
            );
            if (repeat != null && !repeat.isFinalPass) {
              parts.add(widget.repeatLabel(repeat.current, repeat.total));
            }
            return parts.join(', ');
          }()
        : widget.unavailableLabel;

    return Semantics(
      slider: true,
      value: semanticValue,
      label: 'Recitation seek bar',
      enabled: enabled,
      child: Focus(
        onKeyEvent: _handleKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            _lastTrackWidth = width;
            final thumbRadius = style.thumbRadius;
            final thumbCenter = _thumbCenterForValue(value, width);
            final buffered = _bufferedFractions();
            final segmentFractions = _segmentFractions();
            final pulseSegment = repeat != null && !repeat.isFinalPass
                ? repeat.segmentIndex
                : null;
            final scrubLabel = _dragging
                ? _scrubLabelForValue(value)
                : _hoverSegmentIndex != null
                ? widget.segmentLabel(_hoverSegmentIndex!)
                : '';

            final revealCenterX = _dragging
                ? thumbCenter
                : (_hoverCenterX ?? thumbCenter);
            // During drag, focus is owned by drag handlers (seeded + hysteresis).
            // During hover, focus follows the pointer segment.
            final snapIndex = _dragging ? _revealSnapIndex : _hoverSegmentIndex;
            if (liveRevealing && snapIndex != null) {
              _revealSnapIndex = snapIndex;
              _revealCenterX = revealCenterX;
            }
            final effectiveSnapIndex = liveRevealing
                ? snapIndex
                : _revealSnapIndex;

            final trackAnimations = Listenable.merge([
              _pulseController,
              _revealController,
              _focusTransitionController,
              _ayahGlowController,
            ]);

            return MouseRegion(
              onHover: enabled
                  ? (event) {
                      final dx = event.localPosition.dx;
                      final revealStrength = _revealController.value;
                      final rawIndex = _hoverSegmentIndexFromDx(
                        dx,
                        width,
                        focusHint: _hoverSegmentIndex ?? _revealSnapIndex,
                        revealStrength: revealStrength,
                      );
                      final index = _focusWithHysteresis(
                        candidate: rawIndex,
                        currentFocus: _hoverSegmentIndex,
                        dx: dx,
                        width: width,
                        revealStrength: revealStrength,
                      );

                      if (index != _hoverSegmentIndex || _hoverCenterX != dx) {
                        final previousIndex = _hoverSegmentIndex;
                        if (index == null && previousIndex != null) {
                          _revealSnapIndex = previousIndex;
                          _revealCenterX = _hoverCenterX;
                        }
                        final focusChanged = index != previousIndex;
                        setState(() {
                          _hoverSegmentIndex = index;
                          _hoverCenterX = dx;
                          if (focusChanged) {
                            _focusAnchorDx = index == null ? null : dx;
                          } else if (index != null && _focusAnchorDx == null) {
                            _focusAnchorDx = dx;
                          }
                        });
                        if (index != null) {
                          _revealSnapIndex = index;
                          _revealCenterX = dx;
                          _setRevealing(true);
                        } else if (previousIndex != null ||
                            _revealController.value > 0) {
                          _beginRevealCollapse();
                        }
                      }
                    }
                  : null,
              onExit: (_) {
                final snap = _hoverSegmentIndex;
                final center = _hoverCenterX;
                if (snap != null ||
                    center != null ||
                    _revealController.value > 0) {
                  _revealSnapIndex = snap ?? _revealSnapIndex;
                  _revealCenterX = center ?? _revealCenterX;
                  setState(() {
                    _hoverSegmentIndex = null;
                    _hoverCenterX = null;
                    _focusAnchorDx = null;
                  });
                  if (!_dragging) _beginRevealCollapse();
                }
              },
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragStart: enabled
                    ? (details) => _onDragStart(
                        _valueFromLocalDx(details.localPosition.dx, width),
                      )
                    : null,
                onHorizontalDragUpdate: enabled
                    ? (details) => _onDragUpdate(
                        _valueFromLocalDx(details.localPosition.dx, width),
                      )
                    : null,
                onHorizontalDragEnd: enabled ? (_) => _onDragEnd() : null,
                onHorizontalDragCancel: enabled ? _onDragEnd : null,
                onTapUp: enabled
                    ? (details) {
                        if (_dragMoved) return;
                        _seekAtLocalDx(details.localPosition.dx, width);
                      }
                    : null,
                child: AnimatedBuilder(
                  animation: _revealController,
                  builder: (context, child) {
                    final revealStrength = _revealController.value;
                    final laneHeight = lerpDouble(
                      style.trackHeight,
                      kLensMaxHeight,
                      revealStrength,
                    )!;
                    return SizedBox(
                      width: width,
                      height: max(28, laneHeight),
                      child: child,
                    );
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: _isRtl
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    children: [
                      Center(
                        child: AnimatedBuilder(
                          animation: trackAnimations,
                          builder: (context, _) {
                            final revealStrength = _revealController.value;
                            final laneHeight = lerpDouble(
                              style.trackHeight,
                              kLensMaxHeight,
                              revealStrength,
                            )!;
                            final targetLayouts = _trackLensLayouts(
                              width: width,
                              trackHeight: style.trackHeight,
                              focusSegmentIndex: effectiveSnapIndex,
                              revealStrength: revealStrength,
                            );
                            final lensLayouts = _displayLensLayouts(
                              target: targetLayouts,
                              focusSegmentIndex: effectiveSnapIndex,
                            );

                            return CustomPaint(
                              size: Size(width, laneHeight),
                              painter: SegmentedTrackPainter(
                                progress: value,
                                segmentFractions: segmentFractions,
                                bufferedRanges: buffered,
                                activeColor: style.activeColor,
                                inactiveColor: style.inactiveColor,
                                bufferedColor: style.bufferedColor,
                                repeatPulseColor: style.repeatPulseColor,
                                labelColor: style.thumbBorderColor,
                                ayahGlowColor: style.ayahGlowColor,
                                enabled: enabled,
                                pulseSegmentIndex: pulseSegment,
                                segments: widget.segments,
                                totalDurationMs: widget.duration.inMilliseconds,
                                pulsePhase: _pulseController.value,
                                currentAyahIndex: _shouldShowAyahGlow
                                    ? activeSegmentIndex
                                    : null,
                                glowPhase: glowPhase,
                                revealStrength: revealStrength,
                                lensLayouts: lensLayouts,
                                segmentNumberLabel: _segmentNumberLabel,
                                isRtl: _isRtl,
                              ),
                            );
                          },
                        ),
                      ),
                      if (repeat != null &&
                          !repeat.isFinalPass &&
                          pulseSegment != null)
                        _RepeatBadge(
                          style: style,
                          label: widget.repeatLabel(
                            repeat.current,
                            repeat.total,
                          ),
                          segment: _segmentByIndex(pulseSegment),
                          duration: widget.duration,
                          width: width,
                          isRtl: _isRtl,
                        ),
                      TweenAnimationBuilder<double>(
                        tween: Tween(end: thumbCenter),
                        duration: _dragging
                            ? Duration.zero
                            : style.thumbTweenDuration,
                        curve: Curves.easeOutCubic,
                        builder: (context, animatedCenter, child) {
                          return AnimatedBuilder(
                            animation: _revealController,
                            builder: (context, _) {
                              // Fade thumb out when lens segments are revealed
                              // so it doesn't punch through the fisheye pills.
                              final revealStrength = _revealController.value;
                              final thumbOpacity =
                                  1.0 -
                                  Curves.easeOut.transform(revealStrength);
                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  if (showScrubTip && scrubLabel.isNotEmpty)
                                    _ScrubTooltip(
                                      style: style,
                                      segmentIndex: _scrubTooltipSegmentIndex,
                                      heading: scrubLabel,
                                      loadExcerpt:
                                          widget.segmentUthmaniExcerpt == null
                                          ? null
                                          : _cachedUthmaniExcerpt,
                                      anchorCenterX: _dragging
                                          ? animatedCenter
                                          : (_hoverCenterX ?? thumbCenter),
                                      trackWidth: width,
                                    ),
                                  if (thumbOpacity > 0)
                                    Positioned(
                                      left: animatedCenter - thumbRadius,
                                      top: 0,
                                      bottom: 0,
                                      child: Center(
                                        child: Opacity(
                                          opacity: thumbOpacity,
                                          child: ScaleTransition(
                                            scale: _snapScale,
                                            child: child,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                            child: child,
                          );
                        },
                        child: Container(
                          key: const Key('seek-thumb'),
                          width: thumbRadius * 2,
                          height: thumbRadius * 2,
                          decoration: BoxDecoration(
                            color: style.thumbColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: style.thumbBorderColor,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: style.thumbColor.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 6,
                                spreadRadius: 0.5,
                              ),
                            ],
                          ),
                        ),
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

/// In-tree scrub label that follows the thumb (no portal).
class _ScrubTooltip extends StatefulWidget {
  const _ScrubTooltip({
    required this.style,
    required this.segmentIndex,
    required this.heading,
    required this.anchorCenterX,
    required this.trackWidth,
    this.loadExcerpt,
  });

  final SegmentedSeekBarStyle style;
  final int? segmentIndex;
  final String heading;
  final Future<String?> Function(int segmentIndex)? loadExcerpt;
  final double anchorCenterX;
  final double trackWidth;

  static const _maxWidth = 240.0;
  static const _horizontalPadding = 8.0;
  static const _minWidth = 48.0;

  @override
  State<_ScrubTooltip> createState() => _ScrubTooltipState();
}

class _ScrubTooltipState extends State<_ScrubTooltip> {
  String? _excerpt;
  int? _loadedFor;

  @override
  void initState() {
    super.initState();
    unawaited(_loadExcerpt());
  }

  @override
  void didUpdateWidget(covariant _ScrubTooltip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.segmentIndex != oldWidget.segmentIndex ||
        widget.loadExcerpt != oldWidget.loadExcerpt) {
      unawaited(_loadExcerpt());
    }
  }

  Future<void> _loadExcerpt() async {
    final index = widget.segmentIndex;
    final loader = widget.loadExcerpt;
    if (!mounted) return;
    if (index == null || loader == null) {
      setState(() {
        _excerpt = null;
        _loadedFor = index;
      });
      return;
    }

    _loadedFor = index;
    final text = await loader(index);
    if (!mounted || _loadedFor != index) return;
    setState(() => _excerpt = text);
  }

  @override
  Widget build(BuildContext context) {
    final excerpt = _excerpt?.trim();
    final hasExcerpt = excerpt != null && excerpt.isNotEmpty;
    final headingPainter = TextPainter(
      text: TextSpan(
        text: widget.heading,
        style: widget.style.tooltipTextStyle,
      ),
      textDirection: Directionality.of(context),
      maxLines: 1,
    )..layout(maxWidth: _ScrubTooltip._maxWidth);
    final estimatedWidth = max(
      _ScrubTooltip._minWidth,
      headingPainter.width + _ScrubTooltip._horizontalPadding * 2,
    );
    final half = estimatedWidth / 2;
    final left = (widget.anchorCenterX - half).clamp(
      0.0,
      widget.trackWidth - estimatedWidth,
    );
    final tooltipHeight = hasExcerpt ? 52.0 : 26.0;

    final uthmaniStyle = widget.style.tooltipTextStyle.copyWith(
      fontFamily: FontFamily.uthmanicHafs,
      fontSize: 11,
      height: 1.4,
      fontWeight: FontWeight.normal,
    );

    return Positioned(
      key: const Key('scrub-tooltip-positioned'),
      left: left,
      top: -tooltipHeight - 6,
      child: AnimatedOpacity(
        opacity: 1,
        duration: widget.style.thumbTweenDuration,
        child: AnimatedScale(
          scale: 1,
          duration: widget.style.thumbTweenDuration,
          curve: Curves.easeOutCubic,
          child: IntrinsicWidth(
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: _ScrubTooltip._maxWidth,
                minWidth: _ScrubTooltip._minWidth,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: _ScrubTooltip._horizontalPadding,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: widget.style.tooltipBackgroundColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: widget.style.tooltipBorderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.heading,
                    key: const Key('scrub-tooltip'),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: widget.style.tooltipTextStyle,
                  ),
                  if (hasExcerpt) ...[
                    const SizedBox(height: 4),
                    Text(
                      excerpt,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: uthmaniStyle,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RepeatBadge extends StatelessWidget {
  const _RepeatBadge({
    required this.style,
    required this.label,
    required this.segment,
    required this.duration,
    required this.width,
    this.isRtl = false,
  });

  final SegmentedSeekBarStyle style;
  final String label;
  final SeekBarSegment? segment;
  final Duration duration;
  final double width;
  final bool isRtl;

  @override
  Widget build(BuildContext context) {
    final seg = segment;
    final durationMs = duration.inMilliseconds;
    if (seg == null || durationMs <= 0) return const SizedBox.shrink();

    final startFrac = seg.start.inMilliseconds / durationMs;
    final endFrac = seg.end.inMilliseconds / durationMs;
    final midFrac = (startFrac + endFrac) / 2;
    final centerX = isRtl ? width * (1.0 - midFrac) : width * midFrac;

    return Positioned(
      left: centerX - 24,
      top: -18,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: style.repeatBadgeColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: style.tooltipTextStyle.copyWith(
            color: style.repeatBadgeTextColor,
            fontSize: 10,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

/// Paints a continuous seek bar with optional ayah glow and fisheye lens.
@visibleForTesting
class SegmentedTrackPainter extends CustomPainter {
  /// Creates a [SegmentedTrackPainter].
  SegmentedTrackPainter({
    required this.progress,
    required this.segmentFractions,
    required this.bufferedRanges,
    required this.activeColor,
    required this.inactiveColor,
    required this.bufferedColor,
    required this.repeatPulseColor,
    required this.labelColor,
    required this.ayahGlowColor,
    required this.enabled,
    required this.segments,
    required this.totalDurationMs,
    required this.segmentNumberLabel,
    this.isRtl = false,
    this.pulseSegmentIndex,
    this.pulsePhase = 0,
    this.currentAyahIndex,
    this.glowPhase = 0,
    this.revealStrength = 0,
    this.lensLayouts = const [],
  });

  final double progress;
  final List<(double start, double end)> segmentFractions;
  final List<(double, double)> bufferedRanges;
  final Color activeColor;
  final Color inactiveColor;
  final Color bufferedColor;
  final Color repeatPulseColor;
  final Color labelColor;
  final Color ayahGlowColor;
  final bool enabled;
  final List<SeekBarSegment> segments;
  final int totalDurationMs;
  final int? pulseSegmentIndex;
  final double pulsePhase;
  final int? currentAyahIndex;
  final double glowPhase;
  final double revealStrength;
  final List<LensSegmentLayout> lensLayouts;
  final String Function(int segmentIndex) segmentNumberLabel;
  final bool isRtl;

  /// Converts a timeline fraction to a pixel x coordinate,
  /// accounting for RTL layout.
  double _fracToX(double frac, double trackWidth) {
    return isRtl ? trackWidth * (1.0 - frac) : trackWidth * frac;
  }

  /// True-timeline rect for one ayah on the continuous track.
  @visibleForTesting
  Rect? segmentRectOnTrack(int index, Size size) {
    if (totalDurationMs <= 0) return null;
    for (final s in segments) {
      if (s.index != index) continue;
      final x1 = _fracToX(
        s.start.inMilliseconds / totalDurationMs,
        size.width,
      );
      final x2 = _fracToX(
        s.end.inMilliseconds / totalDurationMs,
        size.width,
      );
      final left = min(x1, x2);
      final right = max(x1, x2);
      return Rect.fromLTRB(left, 0, right, size.height);
    }
    return null;
  }

  Rect? _rectForSegment(int index, Size size) {
    if (revealStrength > 0.001 && lensLayouts.isNotEmpty) {
      for (final layout in lensLayouts) {
        if (layout.index == index) return layout.rect;
      }
    }
    return segmentRectOnTrack(index, size);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final idleStroke = revealStrength <= 0.001
        ? size.height
        : size.height / (1 + (kLensMaxHeight / 4 - 1) * revealStrength);
    final stroke = idleStroke.clamp(2.0, size.height);
    final progressFrac = progress.clamp(0.0, 1.0);

    final inactivePaint = Paint()
      ..color = enabled ? inactiveColor : inactiveColor.withValues(alpha: 0.4);
    final activePaint = Paint()
      ..color = enabled ? activeColor : activeColor.withValues(alpha: 0.4);

    if (revealStrength <= 0.001) {
      _paintContinuousTrack(
        canvas,
        size,
        centerY: centerY,
        stroke: stroke,
        progressFrac: progressFrac,
        inactivePaint: inactivePaint,
        activePaint: activePaint,
      );
    } else {
      _paintLensSpine(
        canvas,
        size,
        centerY: centerY,
        inactivePaint: inactivePaint,
        progressFrac: progressFrac,
        activePaint: activePaint,
      );
      _paintLensSegments(
        canvas,
        progressFrac: progressFrac,
        inactivePaint: inactivePaint,
        activePaint: activePaint,
      );
    }

    if (currentAyahIndex != null &&
        glowPhase > 0 &&
        enabled &&
        revealStrength <= 0.001) {
      _paintAyahGlow(canvas, size, currentAyahIndex!, glowPhase);
    }

    if (pulseSegmentIndex != null && enabled && totalDurationMs > 0) {
      final rect = _rectForSegment(pulseSegmentIndex!, size);
      if (rect != null && rect.width > 0) {
        final pillRadius = Radius.circular(rect.height / 2);
        final pulsePaint = Paint()
          ..color = repeatPulseColor.withValues(
            alpha: 0.15 + pulsePhase * 0.25,
          );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, pillRadius),
          pulsePaint,
        );
      }
    }
  }

  void _paintContinuousTrack(
    Canvas canvas,
    Size size, {
    required double centerY,
    required double stroke,
    required double progressFrac,
    required Paint inactivePaint,
    required Paint activePaint,
  }) {
    final line = Paint()
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    line.color = inactivePaint.color;
    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), line);

    if (enabled && bufferedRanges.isNotEmpty) {
      line.color = bufferedColor;
      for (final (start, end) in bufferedRanges) {
        final x1 = _fracToX(start, size.width);
        final x2 = _fracToX(end, size.width);
        canvas.drawLine(
          Offset(min(x1, x2), centerY),
          Offset(max(x1, x2), centerY),
          line,
        );
      }
    }

    if (progressFrac > 0) {
      line.color = activePaint.color;
      final activeX = _fracToX(progressFrac, size.width);
      if (isRtl) {
        canvas.drawLine(
          Offset(activeX, centerY),
          Offset(size.width, centerY),
          line,
        );
      } else {
        canvas.drawLine(
          Offset(0, centerY),
          Offset(activeX, centerY),
          line,
        );
      }
    }
  }

  void _paintLensSpine(
    Canvas canvas,
    Size size, {
    required double centerY,
    required Paint inactivePaint,
    required double progressFrac,
    required Paint activePaint,
  }) {
    final spineRect = Rect.fromCenter(
      center: Offset(size.width / 2, centerY),
      width: size.width,
      height: kLensSpineHeight,
    );
    const radius = Radius.circular(kLensSpineHeight / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(spineRect, radius),
      inactivePaint,
    );

    if (enabled && bufferedRanges.isNotEmpty) {
      for (final (start, end) in bufferedRanges) {
        final x1 = _fracToX(start, size.width);
        final x2 = _fracToX(end, size.width);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTRB(
              min(x1, x2),
              spineRect.top,
              max(x1, x2),
              spineRect.bottom,
            ),
            radius,
          ),
          Paint()..color = bufferedColor,
        );
      }
    }

    if (progressFrac > 0) {
      final activeX = _fracToX(progressFrac, size.width);
      final activeRect = isRtl
          ? Rect.fromLTRB(activeX, spineRect.top, size.width, spineRect.bottom)
          : Rect.fromLTRB(0, spineRect.top, activeX, spineRect.bottom);
      canvas.drawRRect(
        RRect.fromRectAndRadius(activeRect, radius),
        activePaint,
      );
    }
  }

  void _paintLensSegments(
    Canvas canvas, {
    required double progressFrac,
    required Paint inactivePaint,
    required Paint activePaint,
  }) {
    for (final layout in lensLayouts) {
      final opacity = layout.opacity.clamp(0.0, 1.0);
      final fade = opacity < 1.0;
      final pillRadius = Radius.circular(layout.rect.height / 2);
      final pillRect = layout.rect;
      final pillRRect = RRect.fromRectAndRadius(pillRect, pillRadius);

      Color withFade(Color color) =>
          fade ? color.withValues(alpha: color.a * opacity) : color;

      // Soft depth: shadow under focus and near neighbors.
      if (layout.listDistance <= 1 && opacity > 0.5) {
        final shadowAlpha = layout.isFocus ? 0.22 : 0.12;
        canvas.drawRRect(
          pillRRect.shift(const Offset(0, 1)),
          Paint()
            ..color = withFade(Colors.black.withValues(alpha: shadowAlpha))
            ..maskFilter = MaskFilter.blur(
              BlurStyle.normal,
              layout.isFocus ? 3 : 2,
            ),
        );
      }

      canvas.drawRRect(
        pillRRect,
        Paint()..color = withFade(inactivePaint.color),
      );

      // Thin border on inactive / distant pills for definition.
      if (!layout.isFocus) {
        canvas.drawRRect(
          pillRRect,
          Paint()
            ..color = withFade(labelColor.withValues(alpha: 0.18))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.75,
        );
      }

      if (enabled && bufferedRanges.isNotEmpty) {
        for (final (bufStart, bufEnd) in bufferedRanges) {
          final overlapStart = max(bufStart, layout.startFrac);
          final overlapEnd = min(bufEnd, layout.endFrac);
          if (overlapEnd <= overlapStart) continue;
          final span = layout.endFrac - layout.startFrac;
          if (span <= 0) continue;
          final tStart = (overlapStart - layout.startFrac) / span;
          final tEnd = (overlapEnd - layout.startFrac) / span;
          late final double localStart;
          late final double localEnd;
          if (isRtl) {
            localStart = pillRect.right - tEnd * pillRect.width;
            localEnd = pillRect.right - tStart * pillRect.width;
          } else {
            localStart = pillRect.left + tStart * pillRect.width;
            localEnd = pillRect.left + tEnd * pillRect.width;
          }
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTRB(
                min(localStart, localEnd),
                pillRect.top,
                max(localStart, localEnd),
                pillRect.bottom,
              ),
              pillRadius,
            ),
            Paint()..color = withFade(bufferedColor),
          );
        }
      }

      if (progressFrac > layout.startFrac) {
        final activeEndFrac = min(progressFrac, layout.endFrac);
        final span = layout.endFrac - layout.startFrac;
        if (span > 0) {
          final activeFraction = (activeEndFrac - layout.startFrac) / span;
          final activeWidth = activeFraction * pillRect.width;
          if (activeWidth > 0) {
            // Chronological start is at the reading-direction end after
            // mirror: fill from right in RTL, left in LTR.
            final activeRect = isRtl
                ? Rect.fromLTRB(
                    pillRect.right - activeWidth,
                    pillRect.top,
                    pillRect.right,
                    pillRect.bottom,
                  )
                : Rect.fromLTWH(
                    pillRect.left,
                    pillRect.top,
                    activeWidth,
                    pillRect.height,
                  );
            final base = withFade(activePaint.color);
            final top = Color.lerp(
              base,
              Colors.white,
              0.18,
            )!.withValues(alpha: base.a);
            canvas.drawRRect(
              RRect.fromRectAndRadius(activeRect, pillRadius),
              Paint()
                ..shader = LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [top, base],
                ).createShader(activeRect),
            );
          }
        }
      }

      // Focus segment: stronger border + subtle inner glow.
      if (layout.isFocus && opacity > 0.75) {
        canvas.drawRRect(
          pillRRect,
          Paint()
            ..color = withFade(activePaint.color.withValues(alpha: 0.6))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            pillRect.deflate(1),
            Radius.circular(max(0, pillRect.height / 2 - 1)),
          ),
          Paint()
            ..color = withFade(activePaint.color.withValues(alpha: 0.12))
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
      }

      _paintSegmentLabel(
        canvas,
        layout: layout,
        pillRect: pillRect,
        opacity: opacity,
      );
    }
  }

  void _paintSegmentLabel(
    Canvas canvas, {
    required LensSegmentLayout layout,
    required Rect pillRect,
    required double opacity,
  }) {
    if (revealStrength < 0.5) return;
    if (layout.listDistance > 2) return;

    final minHeight = switch (layout.listDistance) {
      0 => 10.0,
      1 => 9.0,
      _ => 8.0,
    };
    if (pillRect.height < minHeight || pillRect.width < 10) return;

    final fontSize = switch (layout.listDistance) {
      0 => 11.0,
      1 => 9.0,
      _ => 8.0,
    };
    final textOpacity = layout.listDistance == 0 ? 1.0 : 0.7;
    final painter = TextPainter(
      text: TextSpan(
        text: segmentNumberLabel(layout.index),
        style: TextStyle(
          color: labelColor.withValues(alpha: textOpacity * opacity),
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    if (painter.width > pillRect.width - 4) return;

    painter.paint(
      canvas,
      Offset(
        pillRect.center.dx - painter.width / 2,
        pillRect.center.dy - painter.height / 2,
      ),
    );
  }

  void _paintAyahGlow(
    Canvas canvas,
    Size size,
    int ayahIndex,
    double phase,
  ) {
    final rect = segmentRectOnTrack(ayahIndex, size);
    if (rect == null || rect.width <= 0) return;

    final swell = 1 + 0.35 * phase;
    final glowHeight = size.height * swell;
    final glowRect = Rect.fromCenter(
      center: rect.center,
      width: rect.width,
      height: glowHeight,
    );
    final glowPaint = Paint()
      ..color = ayahGlowColor.withValues(alpha: 0.12 + phase * 0.18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        glowRect,
        Radius.circular(glowHeight / 2),
      ),
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant SegmentedTrackPainter old) {
    return old.progress != progress ||
        old.activeColor != activeColor ||
        old.inactiveColor != inactiveColor ||
        old.bufferedColor != bufferedColor ||
        old.labelColor != labelColor ||
        old.ayahGlowColor != ayahGlowColor ||
        old.enabled != enabled ||
        old.isRtl != isRtl ||
        old.pulsePhase != pulsePhase ||
        old.pulseSegmentIndex != pulseSegmentIndex ||
        old.currentAyahIndex != currentAyahIndex ||
        old.glowPhase != glowPhase ||
        old.revealStrength != revealStrength ||
        old.lensLayouts.length != lensLayouts.length ||
        old.segmentNumberLabel != segmentNumberLabel ||
        old.segmentFractions.length != segmentFractions.length ||
        old.bufferedRanges.length != bufferedRanges.length;
  }
}
