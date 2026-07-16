import 'package:tawaq/core/audio/audio_service.dart' show TawaqAudioService;
import 'package:tawaq/core/audio/audio_track.dart';

/// High-level player state exposed to UI and controllers.
sealed class PlaybackState {
  const PlaybackState();
}

/// No active media.
final class PlaybackIdle extends PlaybackState {
  /// Creates [PlaybackIdle].
  const PlaybackIdle();
}

/// Media is opening or buffering.
final class PlaybackLoading extends PlaybackState {
  /// Creates [PlaybackLoading].
  const PlaybackLoading(this.track);

  /// Track being prepared.
  final AudioTrack track;
}

/// Media is buffering mid-playback.
final class PlaybackBuffering extends PlaybackState {
  /// Creates [PlaybackBuffering].
  const PlaybackBuffering(this.track);

  /// Track being buffered.
  final AudioTrack track;
}

/// Actively playing.
final class PlaybackPlaying extends PlaybackState {
  /// Creates [PlaybackPlaying].
  const PlaybackPlaying({
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
  const PlaybackPaused({
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
  const PlaybackCompleted({
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
  const PlaybackError({
    required this.track,
    required this.message,
  });

  /// Track that failed.
  final AudioTrack? track;

  /// Human-readable error.
  final String message;
}
