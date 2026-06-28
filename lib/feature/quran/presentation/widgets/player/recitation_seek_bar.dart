import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_state.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_timeline.dart';

/// Forui-themed continuous seek bar for the recitation player.
///
/// Shows the current playback position and, when [timeline] has ayah timing,
/// displays an [FTooltip]-positioned ayah tooltip while dragging and snaps to
/// the nearest ayah boundary on release. When [bufferedRanges] is non-empty
/// (network streaming), the already-buffered regions are painted as a
/// lighter segment on top of the inactive track.
///
/// Sizes are derived from [LayoutBuilder] constraints so the thumb, track,
/// and tooltip anchor stay correct across the drawer's responsive layouts.
/// The ayah tooltip uses [FPortalOverflow.flip], which clamps it inside the
/// viewport bounds (the old hand-rolled tooltip used a fixed `-50` offset
/// that overflowed at the edges).
class RecitationSeekBar extends StatefulWidget {
  /// Creates a [RecitationSeekBar].
  const RecitationSeekBar({
    required this.playback,
    required this.timeline,
    required this.onSeek,
    this.bufferedRanges = const [],
    super.key,
  });

  /// Current recitation state (position, duration, etc.).
  final RecitationState playback;

  /// Optional ayah timing for snapping and tooltips.
  final RecitationTimeline? timeline;

  /// Called when the user finishes scrubbing.
  final ValueChanged<Duration> onSeek;

  /// Demuxer-cache ranges already buffered, for the buffered segment.
  /// Empty for local files or when nothing is cached.
  final List<CacheRange> bufferedRanges;

  @override
  State<RecitationSeekBar> createState() => _RecitationSeekBarState();
}

class _RecitationSeekBarState extends State<RecitationSeekBar> {
  bool _dragging = false;
  double _dragValue = 0;
  FTooltipController? _tooltipController;

  static const _thumbRadius = 8.0;
  static const _trackHeight = 4.0;

  double get _streamedProgress {
    final durationMs = widget.playback.duration.inMilliseconds;
    if (durationMs <= 0) return 0;
    return (widget.playback.position.inMilliseconds / durationMs)
        .clamp(0.0, 1.0);
  }

  double get _currentValue =>
      (_dragging ? _dragValue : _streamedProgress).clamp(0.0, 1.0);

  Duration get _duration => widget.playback.duration;

  Duration _positionFromValue(double value) {
    final durationMs = max(1, _duration.inMilliseconds);
    return Duration(milliseconds: (durationMs * value).round());
  }

  int? _ayahAtValue(double value) {
    final timeline = widget.timeline;
    if (timeline == null || !timeline.hasTiming) return null;
    return timeline.ayahAt(_positionFromValue(value));
  }

  Duration _snappedPosition() {
    final timeline = widget.timeline;
    final position = _positionFromValue(_currentValue);
    if (timeline == null || !timeline.hasTiming) return position;
    return timeline.snapToNearestAyah(position);
  }

  void _onDragStart(double value) {
    setState(() {
      _dragging = true;
      _dragValue = value.clamp(0, 1);
    });
    unawaited(_showTooltip());
  }

  void _onDragUpdate(double value) {
    setState(() => _dragValue = value.clamp(0.0, 1.0));
  }

  void _onDragEnd() {
    if (!_dragging) return;
    final target = _snappedPosition();
    setState(() => _dragging = false);
    unawaited(_hideTooltip());
    widget.onSeek(target);
  }

  Future<void> _showTooltip() async {
    await _tooltipController?.show();
  }

  Future<void> _hideTooltip() async {
    await _tooltipController?.hide();
  }
  /// Buffered fraction for each range, as (start, end) in 0..1 of the track.
  List<(double, double)> _bufferedFractions() {
    final durationMs = _duration.inMilliseconds;
    if (durationMs <= 0 || widget.bufferedRanges.isEmpty) {
      return const [];
    }
    return widget.bufferedRanges
        .map((r) => (
              (r.start.inMilliseconds / durationMs).clamp(0.0, 1.0),
              (r.end.inMilliseconds / durationMs).clamp(0.0, 1.0),
            ))
        .where((e) => e.$2 > e.$1)
        .toList();
  }

  @override
  void dispose() {
    _tooltipController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    final enabled = _duration.inMilliseconds > 0;
    final value = _currentValue;
    final ayah = _ayahAtValue(value);
    final snapped = _snappedPosition();

    final semanticValue = enabled
        ? ayah != null
            ? '${l10n.ayahLabel} $ayah, '
                  '${_formatDuration(snapped)} / ${_formatDuration(_duration)}'
            : '${_formatDuration(snapped)} / ${_formatDuration(_duration)}'
        : l10n.quranRecitationUnavailable;

    return Semantics(
      slider: true,
      value: semanticValue,
      label: 'Recitation seek bar',
      enabled: enabled,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final maxThumbCenter = width - _thumbRadius * 2;
          final thumbCenter = _thumbRadius + value * maxThumbCenter;
          final buffered = _bufferedFractions();

          return FTooltip(
            // Fully controller-driven: we show on drag start, hide on release.
            // Hover/long-press are disabled so the tooltip only appears while
            // scrubbing.
            hover: false,
            longPress: false,
            control: FTooltipControl.managed(
              onChange: (_) {},
            ),
            // tipAnchor/childAnchor/overflow default to bottom/top/flip,
            // which clamps the tooltip inside the viewport near the edges.
            tipBuilder: (context, controller) {
              _tooltipController = controller;
              return Text(
                ayah != null ? '${l10n.ayahLabel} $ayah' : '',
                style: typography.body.xs.copyWith(
                  color: colors.primaryForeground,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragStart: enabled
                  ? (details) => _onDragStart(
                        ((details.localPosition.dx - _thumbRadius) /
                                maxThumbCenter)
                            .clamp(0.0, 1.0),
                      )
                  : null,
              onHorizontalDragUpdate: enabled
                  ? (details) => _onDragUpdate(
                        ((details.localPosition.dx - _thumbRadius) /
                                maxThumbCenter)
                            .clamp(0.0, 1.0),
                      )
                  : null,
              onHorizontalDragEnd: enabled ? (_) => _onDragEnd() : null,
              onHorizontalDragCancel: enabled ? _onDragEnd : null,
              onTapDown: enabled
                  ? (details) => _onDragStart(
                        ((details.localPosition.dx - _thumbRadius) /
                                maxThumbCenter)
                            .clamp(0.0, 1.0),
                      )
                  : null,
              onTapUp: enabled ? (_) => _onDragEnd() : null,
              child: SizedBox(
                width: width,
                height: 32,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Center(
                      child: CustomPaint(
                        size: Size(width, _trackHeight),
                        painter: SeekBarTrackPainter(
                          value: value,
                          bufferedRanges: buffered,
                          activeColor: colors.primary,
                          inactiveColor: colors.mutedForeground,
                          bufferedColor: colors.primary.withValues(alpha: 0.3),
                          enabled: enabled,
                        ),
                      ),
                    ),
                    Positioned(
                      left: thumbCenter - _thumbRadius,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Container(
                          width: _thumbRadius * 2,
                          height: _thumbRadius * 2,
                          decoration: BoxDecoration(
                            color: colors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colors.primaryForeground,
                              width: 2,
                            ),
                          ),
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
    );
  }

  static String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

/// Paints the seek bar track: inactive base, buffered (network) segments,
/// and the active (played) portion.
///
/// Exposed as a public type so tests can inspect the buffered-segment
/// configuration; it is not part of the public widget API.
class SeekBarTrackPainter extends CustomPainter {
  /// Creates a [SeekBarTrackPainter]. Exposed for testing the buffered
  /// segment configuration; not part of the public widget API.
  @visibleForTesting
  SeekBarTrackPainter({
    required this.value,
    required this.bufferedRanges,
    required this.activeColor,
    required this.inactiveColor,
    required this.bufferedColor,
    required this.enabled,
  });

  /// Current playback progress (0..1).
  final double value;

  /// Buffered fractions to paint as the downloaded segment.
  final List<(double, double)> bufferedRanges;

  /// Color of the played portion.
  final Color activeColor;

  /// Color of the unplayed track.
  final Color inactiveColor;

  /// Color of the buffered (network) segment.
  final Color bufferedColor;

  /// Whether the track is enabled.
  final bool enabled;

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final activeWidth = size.width * value.clamp(0.0, 1.0);

    // Inactive (full) track.
    var trackPaint = Paint()
      ..strokeWidth = size.height
      ..strokeCap = StrokeCap.round
      ..color = enabled ? inactiveColor : inactiveColor.withValues(alpha: 0.4);
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      trackPaint,
    );

    // Buffered ranges (network) — lighter segment over the inactive track.
    if (enabled && bufferedRanges.isNotEmpty) {
      final bufferedPaint = Paint()
        ..strokeWidth = size.height
        ..strokeCap = StrokeCap.round
        ..color = bufferedColor;
      for (final (start, end) in bufferedRanges) {
        canvas.drawLine(
          Offset(start * size.width, centerY),
          Offset(end * size.width, centerY),
          bufferedPaint,
        );
      }
    }

    // Active (played) track.
    if (activeWidth > 0) {
      trackPaint = Paint()
        ..strokeWidth = size.height
        ..strokeCap = StrokeCap.round
        ..color = enabled ? activeColor : activeColor.withValues(alpha: 0.4);
      canvas.drawLine(
        Offset(0, centerY),
        Offset(activeWidth, centerY),
        trackPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SeekBarTrackPainter old) {
    return old.value != value ||
        old.activeColor != activeColor ||
        old.inactiveColor != inactiveColor ||
        old.bufferedColor != bufferedColor ||
        old.enabled != enabled ||
        old.bufferedRanges.length != bufferedRanges.length;
  }
}
