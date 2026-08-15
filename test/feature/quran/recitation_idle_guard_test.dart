import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/core/audio/audio_service.dart' show TawaqAudioService;
import 'package:tawaq/core/audio/playback_state.dart' show PlaybackCompleted;
import 'package:tawaq/feature/quran/domain/models/recitation_state.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_state_machine.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_timeline.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_provider.dart'
    show RecitationController;

/// Mirrors completion guards in [RecitationController._onNaturalCompletion].
/// [AudioCompleted] is dispatched only from [TawaqAudioService.completionStream],
/// not from [PlaybackCompleted] on [stateStream] (which would duplicate natural EOF).
bool shouldDispatchAudioCompleted(RecitationState state) {
  return state.active &&
      !state.userStopped &&
      !state.timelinePending &&
      !state.isLoading &&
      (state.isPlaying || state.isBuffering);
}

void main() {
  group('PlaybackIdle completion guard', () {
    test('after Stop (userStopped) does not dispatch completion', () {
      const afterStop = RecitationState(
        userStopped: true,
        repeatsRemaining: 3,
        active: true,
      );
      expect(shouldDispatchAudioCompleted(afterStop), isFalse);
    });

    test('during load (untimed) does not dispatch completion', () {
      const duringLoad = RecitationState(
        status: RecitationStatus.loading,
        repeatsRemaining: 3,
        active: true,
      );
      expect(shouldDispatchAudioCompleted(duringLoad), isFalse);
    });

    test('while timeline pending does not dispatch completion', () {
      const pending = RecitationState(
        status: RecitationStatus.playing,
        timelinePending: true,
        repeatsRemaining: 3,
        active: true,
      );
      expect(shouldDispatchAudioCompleted(pending), isFalse);
    });

    test('natural eof while playing dispatches completion', () {
      const playing = RecitationState(
        status: RecitationStatus.playing,
        repeatsRemaining: 3,
        active: true,
      );
      expect(shouldDispatchAudioCompleted(playing), isTrue);
    });

    test('Stop transition sets userStopped', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        active: true,
      );
      final result = transition(
        state,
        const Stop(),
        timeline: const RecitationTimeline(),
        defaultAyahRepeatCount: 1,
        defaultRangeRepeatCount: 1,
      );
      expect(result.state.userStopped, isTrue);
      expect(result.state.repeatsRemaining, 1);
    });
  });
}
