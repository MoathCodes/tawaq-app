import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_state.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_state_machine.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_timeline.dart';

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

void main() {
  group('duration reporting', () {
    test(
      'timed reciter: duration reported from timeline totalDuration',
      () {
        const state = RecitationState();
        final result = _run(
          state,
          const AudioDuration(Duration(minutes: 3)),
        );

        expect(result.state.duration, const Duration(minutes: 3));
        expect(result.state.duration, greaterThan(Duration.zero));
      },
    );

    test(
      'untimed reciter: duration reported from mpv stream',
      () {
        const state = RecitationState();
        final result = _run(
          state,
          const AudioDuration(
            Duration(minutes: 2, seconds: 30),
          ),
        );

        expect(
          result.state.duration,
          const Duration(minutes: 2, seconds: 30),
        );
        expect(result.state.duration, greaterThan(Duration.zero));
      },
    );

    test(
      'duration keeps larger value when mpv reports smaller after timeline',
      () {
        const state = RecitationState(
          duration: Duration(minutes: 3),
        );
        final result = _run(
          state,
          const AudioDuration(Duration(minutes: 2)),
        );

        expect(result.state.duration, const Duration(minutes: 3));
      },
    );

    test(
      'duration keeps larger value when mpv reports zero after timeline',
      () {
        const state = RecitationState(
          duration: Duration(minutes: 3),
        );
        final result = _run(state, const AudioDuration(Duration.zero));

        expect(result.state.duration, const Duration(minutes: 3));
      },
    );
  });
}
