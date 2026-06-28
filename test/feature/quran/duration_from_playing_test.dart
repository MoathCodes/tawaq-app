import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/core/audio/audio_track.dart';
import 'package:tawaq/core/audio/playback_state.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_state.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_timeline.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_state_machine.dart';

/// Mirrors [RecitationController._onServiceState] for playing/paused snapshots.
List<RecitationEvent> eventsFromServiceState(PlaybackState playback) {
  return switch (playback) {
    PlaybackPlaying(:final duration) => [
      const AudioStarted(),
      if (duration > Duration.zero) AudioDuration(duration),
    ],
    PlaybackPaused(:final duration) => [
      const AudioPaused(),
      if (duration > Duration.zero) AudioDuration(duration),
    ],
    _ => <RecitationEvent>[],
  };
}

RecitationTransition _run(
  RecitationState state,
  RecitationEvent event,
) {
  return transition(
    state,
    event,
    timeline: const RecitationTimeline(),
    defaultAyahRepeatCount: 1,
    defaultRangeRepeatCount: 1,
  );
}

final AudioTrack _track = AudioTrack.network(
  id: 'untimed',
  title: 'Untimed',
  url: 'https://example.com/surah.mp3',
);

void main() {
  group('untimed duration from PlaybackPlaying snapshot', () {
    test(
      'PlaybackPlaying with duration drives state.duration for untimed reciter',
      () {
        const initial = RecitationState();
        final playing = PlaybackPlaying(
          track: _track,
          position: Duration.zero,
          duration: const Duration(minutes: 4, seconds: 22),
        );

        var state = initial;
        for (final event in eventsFromServiceState(playing)) {
          state = _run(state, event).state;
        }

        expect(state.duration, const Duration(minutes: 4, seconds: 22));
        expect(state.status, RecitationStatus.playing);
      },
    );

    test('PlaybackPaused with duration also seeds duration', () {
      const initial = RecitationState(
        status: RecitationStatus.playing,
        duration: const Duration(minutes: 1),
      );
      final paused = PlaybackPaused(
        track: _track,
        position: const Duration(seconds: 30),
        duration: const Duration(minutes: 5),
      );

      var state = initial;
      for (final event in eventsFromServiceState(paused)) {
        state = _run(state, event).state;
      }

      expect(state.duration, const Duration(minutes: 5));
      expect(state.status, RecitationStatus.paused);
    });
  });
}
