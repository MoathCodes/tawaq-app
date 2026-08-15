import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_models.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_state.dart';
import 'package:tawaq/feature/quran/domain/models/reciter.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_state_machine.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_timeline.dart';

const _reciter = Reciter(id: 1, name: 'Test', moshaf: [_moshaf]);
const _moshaf = Moshaf(
  id: 1,
  name: 'Hafs',
  server: 'https://example.com/',
  surahList: [1, 2, 3],
  surahTotal: 3,
);

RecitationTimeline _timeline({int surah = 1}) {
  return RecitationTimeline(
    timing: SurahTiming(
      surah: surah,
      readId: 1,
      ayat: [
        const AyahTiming(ayah: 1, startMs: 0, endMs: 5000),
        const AyahTiming(ayah: 2, startMs: 5000, endMs: 10000),
        const AyahTiming(ayah: 3, startMs: 10000, endMs: 15000),
      ],
    ),
  );
}

RecitationTransition _run(
  RecitationState state,
  RecitationEvent event, {
  RecitationTimeline? timeline,
}) {
  return transition(
    state,
    event,
    timeline: timeline ?? _timeline(),
    defaultAyahRepeatCount: 1,
    defaultRangeRepeatCount: 1,
  );
}

void main() {
  group('continueFromHere gapless continuation', () {
    test('end of open-ended selection emits LoadGaplessContinuation', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        active: true,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        rangeFrom: AyahReference(surah: 1, ayah: 2),
        segmentStartAyah: 2,
        segmentEndAyah: 3,
        currentAyah: 3,
        duration: Duration(milliseconds: 15000),
      );
      final result = _run(
        state,
        const AudioCompleted(),
        timeline: _timeline(),
      );

      expect(result.state.surah, 2);
      expect(result.state.status, RecitationStatus.loading);
      expect(result.effects.whereType<LoadGaplessContinuation>(), hasLength(1));
      final effect = result.effects.whereType<LoadGaplessContinuation>().first;
      expect(effect.fromSurah, 1);
      expect(effect.toSurah, 2);
      expect(effect.reciter, _reciter);
      expect(effect.moshaf, _moshaf);
    });

    test('whole-surah preset ends instead of continuing', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        active: true,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        currentAyah: 3,
        duration: Duration(milliseconds: 15000),
      );
      final result = _run(
        state,
        const AudioCompleted(),
        timeline: _timeline(),
      );

      expect(result.state.status, RecitationStatus.ended);
      expect(result.state.position, const Duration(milliseconds: 15000));
      expect(result.effects.whereType<PauseAtEof>(), hasLength(1));
      expect(result.effects.whereType<SetNativeLoop>(), hasLength(1));
      expect(result.effects.whereType<StopAudio>(), isEmpty);
      expect(result.effects.whereType<ClearPlaybackPosition>(), isEmpty);
      expect(result.effects.whereType<LoadGaplessContinuation>(), isEmpty);
    });

    test('bounded range ends instead of continuing', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        active: true,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        rangeFrom: AyahReference(surah: 1, ayah: 1),
        rangeTo: AyahReference(surah: 1, ayah: 3),
        segmentStartAyah: 1,
        segmentEndAyah: 3,
        currentAyah: 3,
        duration: Duration(milliseconds: 15000),
      );
      final result = _run(
        state,
        const AudioCompleted(),
        timeline: _timeline(),
      );

      expect(result.state.status, RecitationStatus.ended);
      expect(result.state.position, const Duration(milliseconds: 15000));
      expect(result.effects.whereType<PauseAtEof>(), hasLength(1));
      expect(result.effects.whereType<SetNativeLoop>(), hasLength(1));
      expect(result.effects.whereType<StopAudio>(), isEmpty);
      expect(result.effects.whereType<ClearPlaybackPosition>(), isEmpty);
      expect(result.effects.whereType<LoadGaplessContinuation>(), isEmpty);
    });

    test('missing next surah on open-ended ends cleanly', () {
      const moshaf = Moshaf(
        id: 1,
        name: 'Hafs',
        server: 'https://example.com/',
        surahList: [1],
        surahTotal: 1,
      );
      const state = RecitationState(
        status: RecitationStatus.playing,
        active: true,
        reciter: _reciter,
        moshaf: moshaf,
        surah: 1,
        rangeFrom: AyahReference(surah: 1, ayah: 2),
        segmentStartAyah: 2,
        segmentEndAyah: 3,
        currentAyah: 3,
        duration: Duration(milliseconds: 15000),
      );
      final result = _run(
        state,
        const AudioCompleted(),
        timeline: _timeline(),
      );

      expect(result.state.status, RecitationStatus.ended);
      expect(result.state.error, isNull);
      expect(result.state.position, const Duration(milliseconds: 15000));
      expect(result.effects.whereType<PauseAtEof>(), hasLength(1));
      expect(result.effects.whereType<SetNativeLoop>(), hasLength(1));
      expect(result.effects.whereType<LoadGaplessContinuation>(), isEmpty);
    });

    test('GaplessTrackAdvanced advances state to target surah ayah 1', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        active: true,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 2,
        currentAyah: 1,
        position: Duration(milliseconds: 1234),
        duration: Duration(milliseconds: 15000),
      );
      final result = _run(
        state,
        const GaplessTrackAdvanced(surah: 2, ayah: 1),
        timeline: _timeline(surah: 2),
      );

      expect(result.state.surah, 2);
      expect(result.state.currentAyah, 1);
      expect(result.state.position, Duration.zero);
      expect(result.state.status, RecitationStatus.playing);
    });
  });
}
