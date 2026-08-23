import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_state.dart';
import 'package:tawaq/feature/quran/domain/models/reciter.dart';
import 'package:tawaq/feature/quran/domain/recitation/recitation_session.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_timeline.dart';

const _timedMoshaf = Moshaf(
  id: 1,
  name: 'Hafs',
  server: 'https://example.com/',
  surahList: [1, 2],
  surahTotal: 2,
  timingReadId: 1,
);
const _reciter = Reciter(id: 1, name: 'Test', moshaf: [_timedMoshaf]);
const _playing = RecitationState(
  reciter: _reciter,
  moshaf: _timedMoshaf,
  surah: 1,
  status: RecitationStatus.playing,
  active: true,
);

const _timeline = RecitationTimeline(
  timing: SurahTiming(
    surah: 1,
    readId: 1,
    ayat: [
      AyahTiming(ayah: 1, startMs: 0, endMs: 1000),
      AyahTiming(ayah: 2, startMs: 1000, endMs: 2000),
    ],
  ),
);

void main() {
  group('RecitationSession', () {
    test('is the only writer projected to its adapter', () {
      final projected = <RecitationState>[];
      final session = RecitationSession(
        initialState: _playing,
        surahAyahCount: (_) => 7,
        onStateChanged: projected.add,
      );

      session
        ..installTimeline(_timeline, generation: 0)
        ..prepareSeek(const Duration(milliseconds: 1200));

      expect(session.state.position, const Duration(milliseconds: 1200));
      expect(
        session.state.pendingSeekTarget,
        const Duration(milliseconds: 1200),
      );
      expect(projected.last, session.state);
    });

    test('rejects a stale failed seek without erasing the newer target', () {
      final session = RecitationSession(
        initialState: _playing,
        surahAyahCount: (_) => 7,
      )..installTimeline(_timeline, generation: 0);

      session
        ..prepareSeek(const Duration(milliseconds: 400))
        ..prepareSeek(const Duration(milliseconds: 1400));

      final reverted = session.revertPendingSeek(
        const Duration(milliseconds: 250),
        onlyIfPendingEquals: const Duration(milliseconds: 400),
      );

      expect(reverted, isFalse);
      expect(
        session.state.pendingSeekTarget,
        const Duration(milliseconds: 1400),
      );
      expect(session.state.position, const Duration(milliseconds: 1400));
    });

    test('accepts native landing and derives the observed ayah', () {
      final session =
          RecitationSession(
              initialState: _playing,
              surahAyahCount: (_) => 7,
            )
            ..installTimeline(_timeline, generation: 0)
            ..prepareSeek(const Duration(milliseconds: 1200));

      session.observeNative(
        null,
        const RecitationNativeSnapshot(
          lifecycle: RecitationNativeLifecycle.playing,
          position: Duration(milliseconds: 1210),
          duration: Duration(milliseconds: 2000),
          playIntent: true,
        ),
      );

      expect(session.state.pendingSeekTarget, isNull);
      expect(session.state.currentAyah, 2);
      expect(session.lastAcceptedPosition, const Duration(milliseconds: 1210));
    });

    test('translates first gapless track observation exactly once', () {
      final projected = <RecitationState>[];
      final session = RecitationSession(
        initialState: _playing,
        surahAyahCount: (_) => 7,
        onStateChanged: projected.add,
      );

      session.observeNative(
        null,
        const RecitationNativeSnapshot(
          lifecycle: RecitationNativeLifecycle.playing,
          position: Duration.zero,
          duration: Duration(seconds: 2),
          playIntent: true,
          playlistIndex: 1,
        ),
      );
      final projectionCount = projected.length;
      session.observeNative(
        const RecitationNativeSnapshot(
          lifecycle: RecitationNativeLifecycle.playing,
          position: Duration.zero,
          duration: Duration(seconds: 2),
          playIntent: true,
          playlistIndex: 1,
        ),
        const RecitationNativeSnapshot(
          lifecycle: RecitationNativeLifecycle.playing,
          position: Duration.zero,
          duration: Duration(seconds: 2),
          playIntent: true,
          playlistIndex: 1,
        ),
      );

      expect(session.state.currentAyah, 1);
      expect(projected, hasLength(projectionCount));
    });

    test('ignores authoritative completion while timing is pending', () {
      final session = RecitationSession(
        initialState: _playing.copyWith(timelinePending: true),
        surahAyahCount: (_) => 7,
      );

      final decision = session.observeNative(
        null,
        const RecitationNativeSnapshot(
          lifecycle: RecitationNativeLifecycle.completed,
          position: Duration(seconds: 2),
          duration: Duration(seconds: 2),
          playIntent: false,
        ),
      );

      expect(decision.effects, isEmpty);
      expect(session.state.isEnded, isFalse);
    });
  });
}
