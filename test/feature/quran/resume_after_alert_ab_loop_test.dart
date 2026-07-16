import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_state.dart';
import 'package:tawaq/feature/quran/domain/models/reciter.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_provider.dart' show RecitationController;

const _reciter = Reciter(id: 1, name: 'Test', moshaf: [_moshaf]);
const _moshaf = Moshaf(
  id: 1,
  name: 'Hafs',
  server: 'https://example.com/',
  surahList: [1],
  surahTotal: 1,
  timingReadId: 1,
);

/// Mirrors the re-arm guard in [RecitationController.resumeAfterAlert].
bool shouldRearmAyahLoopAfterAlert(RecitationState snapshot) {
  return snapshot.ayahRepeatCount > 1 &&
      snapshot.currentAyah != null &&
      snapshot.moshaf != null &&
      snapshot.moshaf!.hasTiming;
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
  group('resumeAfterAlert eachAyah A-B loop', () {
    test('re-arms when ayahRepeatCount > 1 with timed moshaf and current ayah',
        () {
      const snapshot = RecitationState(
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        currentAyah: 3,
        ayahRepeatCount: 3,
        status: RecitationStatus.playing,
      );
      expect(shouldRearmAyahLoopAfterAlert(snapshot), isTrue);
    });

    test('skips re-arm when ayahRepeatCount is 1', () {
      const snapshot = RecitationState(
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        currentAyah: 3,
        status: RecitationStatus.playing,
      );
      expect(shouldRearmAyahLoopAfterAlert(snapshot), isFalse);
    });

    test('skips re-arm when current ayah is null', () {
      const snapshot = RecitationState(
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        ayahRepeatCount: 3,
        status: RecitationStatus.playing,
      );
      expect(shouldRearmAyahLoopAfterAlert(snapshot), isFalse);
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
  });
}
