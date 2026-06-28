import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_state.dart';

/// Wraps per-ayah timing data for the currently loaded surah and selection.
///
/// All methods are pure and synchronous; callers own the async timing load.
class RecitationTimeline {
  /// Creates a timeline with optional timing and optional range markers.
  const RecitationTimeline({
    this.timing,
    this.rangeStartAyah,
    this.rangeEndAyah,
  });

  /// Per-ayah timing for the loaded surah, or null when unavailable.
  final SurahTiming? timing;

  /// First ayah of the current selection, if any.
  final int? rangeStartAyah;

  /// Last ayah of the current selection, if any.
  final int? rangeEndAyah;

  /// Whether ayah-by-ayah timing is available.
  bool get hasTiming => timing != null;

  /// Total duration of the surah audio, or zero when unknown.
  Duration get totalDuration {
    final ms = timing?.totalMs ?? 0;
    return ms > 0 ? Duration(milliseconds: ms) : Duration.zero;
  }

  /// Returns the ayah number at [position], or null when no timing exists.
  int? ayahAt(Duration position) {
    final timing = this.timing;
    if (timing == null) return null;
    return timing.ayahAt(position.inMilliseconds);
  }

  /// Returns the start time of [ayah], or null if unknown.
  Duration? startOfAyah(int ayah) {
    final segment = timing?.forAyah(ayah);
    if (segment == null) return null;
    return Duration(milliseconds: segment.startMs);
  }

  /// Returns the end time of [ayah], or null if unknown.
  Duration? endOfAyah(int ayah) {
    final segment = timing?.forAyah(ayah);
    if (segment == null) return null;
    return Duration(milliseconds: segment.endMs);
  }

  /// Returns the start of the range, or zero if no range is set.
  Duration get rangeStart {
    final ayah = rangeStartAyah;
    if (ayah == null) return Duration.zero;
    return startOfAyah(ayah) ?? Duration.zero;
  }

  /// Returns the end of the range, or [totalDuration] if no range end is set.
  Duration get rangeEnd {
    final ayah = rangeEndAyah;
    if (ayah == null) return totalDuration;
    return endOfAyah(ayah) ?? totalDuration;
  }

  /// Clamps [position] inside the current range.
  Duration clampToRange(Duration position) {
    final startMs = rangeStart.inMilliseconds;
    final endMs = rangeEnd.inMilliseconds;
    final clamped = position.inMilliseconds.clamp(startMs, endMs);
    return Duration(milliseconds: clamped);
  }

  /// Snaps [position] to the start of the nearest ayah when timing exists.
  ///
  /// Returns the original position when no timing is available.
  Duration snapToNearestAyah(Duration position) {
    final timing = this.timing;
    if (timing == null) return position;

    final ayat = timing.ayat;
    if (ayat.isEmpty) return position;

    final posMs = position.inMilliseconds;
    var bestIndex = 0;
    var bestDistance = (posMs - ayat.first.startMs).abs();

    for (var i = 1; i < ayat.length; i++) {
      final distance = (posMs - ayat[i].startMs).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = i;
      }
    }

    return Duration(milliseconds: ayat[bestIndex].startMs);
  }

  /// Returns the first ayah at or after [position], or null without timing.
  int? nextAyahAtOrAfter(Duration position) {
    final timing = this.timing;
    if (timing == null) return null;

    final posMs = position.inMilliseconds;
    for (final a in timing.ayat) {
      if (a.startMs >= posMs) return a.ayah;
    }
    return timing.ayat.lastOrNull?.ayah;
  }
}

/// Builds a [RecitationTimeline] from [state] and loaded [timing].
RecitationTimeline timelineFor(RecitationState state, SurahTiming? timing) {
  final segment = state.currentSegment;
  return RecitationTimeline(
    timing: timing,
    rangeStartAyah: segment?.startAyah,
    rangeEndAyah: segment?.endAyah,
  );
}
