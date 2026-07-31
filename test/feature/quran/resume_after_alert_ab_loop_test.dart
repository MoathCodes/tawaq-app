import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_state.dart';
import 'package:tawaq/feature/quran/domain/models/reciter.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_timeline.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_state_machine.dart';

const _reciter = Reciter(id: 1, name: 'Test', moshaf: [_moshaf]);
const _moshaf = Moshaf(
  id: 1,
  name: 'Hafs',
  server: 'https://example.com/',
  surahList: [1],
  surahTotal: 1,
  timingReadId: 1,
);

RecitationTransition _run(RecitationState state, RecitationEvent event) {
  return transition(
    state,
    event,
    timeline: const RecitationTimeline(),
    defaultAyahRepeatCount: 1,
    defaultRangeRepeatCount: 1,
  );
}

/// Mirrors suspend guards on recitation stream handlers during alerts.
bool shouldDispatchAyahLoopExhausted({
  required RecitationState state,
  required int? previousRemaining,
  required int? remaining,
}) {
  if (state.suspendedSnapshot != null) return false;
  return remaining == 0 && previousRemaining != null && previousRemaining > 0;
}

bool shouldDispatchGaplessTrackAdvanced({
  required RecitationState state,
  required int? index,
  required int? previousIndex,
}) {
  if (state.suspendedSnapshot != null) return false;
  if (index == null || index < 1) return false;
  if (previousIndex != null && previousIndex >= 1) return false;
  if (state.surah == null || state.rangeFrom != null) return false;
  return true;
}

void main() {
  group('AlertResume always reloads (no fast-resume path)', () {
    test('playing timed eachAyah session reloads and re-arms A-B loop', () {
      const playing = RecitationState(
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        currentAyah: 3,
        ayahRepeatCount: 3,
        status: RecitationStatus.playing,
        active: true,
      );
      final suspended = _run(playing, const AlertSuspend()).state;
      final result = _run(suspended, const AlertResume());

      expect(result.effects.whereType<LoadSurah>(), hasLength(1));
      expect(result.effects.whereType<LoadAyahLoop>(), hasLength(1));
      expect(result.effects.whereType<LoadAyahLoop>().first.ayah, 3);
      expect(result.effects.whereType<PauseAudio>(), isEmpty);
    });

    test('paused session reloads then pauses (no URI shortcut)', () {
      const paused = RecitationState(
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        currentAyah: 2,
        ayahRepeatCount: 2,
        status: RecitationStatus.paused,
        position: Duration(seconds: 9),
        active: true,
      );
      final suspended = _run(paused, const AlertSuspend()).state;
      final result = _run(suspended, const AlertResume());

      expect(result.effects.whereType<LoadSurah>(), hasLength(1));
      expect(result.effects.whereType<LoadSurah>().first.seekTo, paused.position);
      expect(result.effects.whereType<LoadAyahLoop>(), hasLength(1));
      expect(result.effects.whereType<PauseAudio>(), hasLength(1));
    });

    test('loading session reloads via LoadSurah', () {
      const loading = RecitationState(
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        status: RecitationStatus.loading,
        active: true,
      );
      final suspended = _run(loading, const AlertSuspend()).state;
      final result = _run(suspended, const AlertResume());

      expect(result.effects.whereType<LoadSurah>(), hasLength(1));
    });
  });

  group('alert suspend stream guards', () {
    const playing = RecitationState(
      reciter: _reciter,
      moshaf: _moshaf,
      surah: 1,
      currentAyah: 3,
      ayahRepeatCount: 3,
      status: RecitationStatus.playing,
      active: true,
    );

    test('does not dispatch AyahLoopExhausted while suspended', () {
      final suspended = playing.copyWith(
        suspendedSnapshot: playing,
        status: RecitationStatus.paused,
      );
      expect(
        shouldDispatchAyahLoopExhausted(
          state: suspended,
          previousRemaining: 1,
          remaining: 0,
        ),
        isFalse,
      );
    });

    test('dispatches AyahLoopExhausted when not suspended', () {
      expect(
        shouldDispatchAyahLoopExhausted(
          state: playing,
          previousRemaining: 1,
          remaining: 0,
        ),
        isTrue,
      );
    });

    test('does not dispatch GaplessTrackAdvanced while suspended', () {
      final suspended = playing.copyWith(
        suspendedSnapshot: playing,
        status: RecitationStatus.paused,
      );
      expect(
        shouldDispatchGaplessTrackAdvanced(
          state: suspended,
          index: 1,
          previousIndex: null,
        ),
        isFalse,
      );
    });

    test('dispatches GaplessTrackAdvanced when not suspended', () {
      expect(
        shouldDispatchGaplessTrackAdvanced(
          state: playing,
          index: 1,
          previousIndex: null,
        ),
        isTrue,
      );
    });

    test('AlertSuspend clears pendingSeek so queued seeks cannot land', () {
      const seeking = RecitationState(
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        status: RecitationStatus.playing,
        active: true,
        pendingSeekTarget: Duration(seconds: 12),
        position: Duration(seconds: 12),
      );
      final result = _run(seeking, const AlertSuspend());
      expect(result.state.pendingSeekTarget, isNull);
      expect(result.state.suspendedSnapshot, isNotNull);
      // Snapshot keeps pre-suspend position for AlertResume reload.
      expect(
        result.state.suspendedSnapshot!.position,
        const Duration(seconds: 12),
      );
    });
  });
}
