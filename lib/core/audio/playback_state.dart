import 'package:tawaq/core/audio/audio_service.dart' show TawaqAudioService;
import 'package:tawaq/core/audio/audio_track.dart';

/// A normalized seekable cache interval reported by the audio backend.
typedef PlaybackBufferRange = ({Duration start, Duration end});

/// Normalized transport lifecycle reported by the native audio backend.
enum AudioSessionLifecycle {
  idle,
  loading,
  buffering,
  playing,
  paused,
  completed,
  error,
}

/// Complete read-only runtime projection of the shared native audio session.
class AudioSessionSnapshot {
  /// Creates an immutable audio-session snapshot.
  const new({
    this.owner,
    this.track,
    this.lifecycle = AudioSessionLifecycle.idle,
    this.playIntent = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.bufferedRanges = const [],
    this.playlistIndex = 0,
    this.remainingAbLoops,
    this.error,
  });

  final String? owner;
  final AudioTrack? track;
  final AudioSessionLifecycle lifecycle;
  final bool playIntent;
  final Duration position;
  final Duration duration;
  final List<PlaybackBufferRange> bufferedRanges;
  final int playlistIndex;
  final int? remainingAbLoops;
  final String? error;

  AudioSessionSnapshot copyWith({
    String? owner,
    bool clearOwner = false,
    AudioTrack? track,
    bool clearTrack = false,
    AudioSessionLifecycle? lifecycle,
    bool? playIntent,
    Duration? position,
    Duration? duration,
    List<PlaybackBufferRange>? bufferedRanges,
    int? playlistIndex,
    int? remainingAbLoops,
    bool clearRemainingAbLoops = false,
    String? error,
    bool clearError = false,
  }) => AudioSessionSnapshot(
    owner: clearOwner ? null : owner ?? this.owner,
    track: clearTrack ? null : track ?? this.track,
    lifecycle: lifecycle ?? this.lifecycle,
    playIntent: playIntent ?? this.playIntent,
    position: position ?? this.position,
    duration: duration ?? this.duration,
    bufferedRanges: bufferedRanges ?? this.bufferedRanges,
    playlistIndex: playlistIndex ?? this.playlistIndex,
    remainingAbLoops: clearRemainingAbLoops
        ? null
        : remainingAbLoops ?? this.remainingAbLoops,
    error: clearError ? null : error ?? this.error,
  );
}

/// High-level player state exposed to UI and controllers.
sealed class PlaybackState {
  const new();
}

/// No active media.
final class PlaybackIdle extends PlaybackState {
  /// Creates [PlaybackIdle].
  const new();
}

/// Media is opening or buffering.
final class PlaybackLoading extends PlaybackState {
  /// Creates [PlaybackLoading].
  const new(this.track);

  /// Track being prepared.
  final AudioTrack track;
}

/// Media is buffering mid-playback.
final class PlaybackBuffering extends PlaybackState {
  /// Creates [PlaybackBuffering].
  const new(this.track);

  /// Track being buffered.
  final AudioTrack track;
}

/// Actively playing.
final class PlaybackPlaying extends PlaybackState {
  /// Creates [PlaybackPlaying].
  const new({
    required this.track,
    required this.position,
    required this.duration,
  });

  /// Active track.
  final AudioTrack track;

  /// Current position.
  final Duration position;

  /// Known duration, or zero when unknown.
  final Duration duration;
}

/// Paused with a loaded track.
final class PlaybackPaused extends PlaybackState {
  /// Creates [PlaybackPaused].
  const new({
    required this.track,
    required this.position,
    required this.duration,
  });

  /// Active track.
  final AudioTrack track;

  /// Current position.
  final Duration position;

  /// Known duration, or zero when unknown.
  final Duration duration;
}

/// Track reached its natural end while media remains loaded.
///
/// The OS media session stays populated until [TawaqAudioService.stop] or lease
/// release; use [TawaqAudioService.completionStream] for ended transitions.
final class PlaybackCompleted extends PlaybackState {
  /// Creates [PlaybackCompleted].
  const new({
    required this.track,
    required this.position,
    required this.duration,
  });

  /// Active track.
  final AudioTrack track;

  /// Current position (typically at or near [duration]).
  final Duration position;

  /// Known duration, or zero when unknown.
  final Duration duration;
}

/// Playback failed.
final class PlaybackError extends PlaybackState {
  /// Creates [PlaybackError].
  const new({
    required this.track,
    required this.message,
  });

  /// Track that failed.
  final AudioTrack? track;

  /// Human-readable error.
  final String message;
}
