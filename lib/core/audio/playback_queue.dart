import 'package:tawaq/core/audio/audio_track.dart';
import 'package:tawaq/core/audio/playback_state.dart';

/// Ordered playlist with navigation helpers.
class PlaybackQueue {
  /// Creates a [PlaybackQueue].
  const PlaybackQueue({
    required this.tracks,
    this.currentIndex = 0,
    this.repeatMode = PlaybackRepeatMode.off,
  });

  /// All tracks in play order.
  final List<AudioTrack> tracks;

  /// Index of the current track.
  final int currentIndex;

  /// Repeat behaviour.
  final PlaybackRepeatMode repeatMode;

  /// Whether the queue has any tracks.
  bool get isEmpty => tracks.isEmpty;

  /// Active track, if any.
  AudioTrack? get currentTrack {
    if (tracks.isEmpty || currentIndex < 0 || currentIndex >= tracks.length) {
      return null;
    }
    return tracks[currentIndex];
  }

  /// Whether another track exists after the current one (respecting repeat).
  bool get hasNext {
    if (tracks.isEmpty) return false;
    return switch (repeatMode) {
      PlaybackRepeatMode.one => true,
      PlaybackRepeatMode.all => tracks.length > 1 || currentIndex < tracks.length - 1,
      PlaybackRepeatMode.off => currentIndex < tracks.length - 1,
    };
  }

  /// Whether another track exists before the current one (respecting repeat).
  bool get hasPrevious {
    if (tracks.isEmpty) return false;
    return switch (repeatMode) {
      PlaybackRepeatMode.one => true,
      PlaybackRepeatMode.all => tracks.length > 1 || currentIndex > 0,
      PlaybackRepeatMode.off => currentIndex > 0,
    };
  }

  /// Returns a copy with [index] as the current track.
  PlaybackQueue withIndex(int index) {
    if (tracks.isEmpty) return this;
    final clamped = index.clamp(0, tracks.length - 1);
    return PlaybackQueue(
      tracks: tracks,
      currentIndex: clamped,
      repeatMode: repeatMode,
    );
  }

  /// Advances to the next track according to [repeatMode].
  PlaybackQueue? next() {
    if (tracks.isEmpty) return null;
    return switch (repeatMode) {
      PlaybackRepeatMode.one => this,
      PlaybackRepeatMode.all when currentIndex >= tracks.length - 1 =>
        withIndex(0),
      PlaybackRepeatMode.all => withIndex(currentIndex + 1),
      PlaybackRepeatMode.off when currentIndex >= tracks.length - 1 => null,
      PlaybackRepeatMode.off => withIndex(currentIndex + 1),
    };
  }

  /// Moves to the previous track according to [repeatMode].
  PlaybackQueue? previous() {
    if (tracks.isEmpty) return null;
    return switch (repeatMode) {
      PlaybackRepeatMode.one => this,
      PlaybackRepeatMode.all when currentIndex <= 0 =>
        withIndex(tracks.length - 1),
      PlaybackRepeatMode.all => withIndex(currentIndex - 1),
      PlaybackRepeatMode.off when currentIndex <= 0 => null,
      PlaybackRepeatMode.off => withIndex(currentIndex - 1),
    };
  }
}
