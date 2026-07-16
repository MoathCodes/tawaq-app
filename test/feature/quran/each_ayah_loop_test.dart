import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_models.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_state.dart';
import 'package:tawaq/feature/quran/domain/models/reciter.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_timeline.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_state_machine.dart';

const _reciter = Reciter(id: 1, name: 'Test', moshaf: [_moshaf]);
const _moshaf = Moshaf(
  id: 1,
  name: 'Hafs',
  server: 'https://example.com/',
  surahList: [1, 2, 3],
  surahTotal: 3,
);

RecitationTimeline _timeline() {
  return const RecitationTimeline(
    timing: SurahTiming(
      surah: 1,
      readId: 1,
      ayat: [
        AyahTiming(ayah: 1, startMs: 0, endMs: 5000),
        AyahTiming(ayah: 2, startMs: 5000, endMs: 10000),
        AyahTiming(ayah: 3, startMs: 10000, endMs: 15000),
      ],
    ),
  );
}

RecitationTransition _run(
  RecitationState state,
  RecitationEvent event, {
  RecitationTimeline? timeline,
  int ayahRepeatCount = 3,
  int rangeRepeatCount = 1,
}) {
  return transition(
    state,
    event,
    timeline: timeline ?? _timeline(),
    defaultAyahRepeatCount: ayahRepeatCount,
    defaultRangeRepeatCount: rangeRepeatCount,
  );
}

void main() {
  group('eachAyah native A-B loop', () {
    test('PlayRange sets ayahRepeatCount and emits LoadRange', () {
      const state = RecitationState();
      final result = _run(
        state,
        const PlayRange(
          reciter: _reciter,
          moshaf: _moshaf,
          from: AyahReference(surah: 1, ayah: 1),
          to: AyahReference(surah: 1, ayah: 3),
        ),
      );

      expect(result.state.ayahRepeatCount, 3);
      expect(result.state.currentAyah, 1);
      expect(result.state.repeatsRemaining, 1);
      expect(result.state.ayahRepeatsRemaining, 3);
      expect(result.effects.whereType<LoadRange>(), hasLength(1));
    });

    test('PlaySurah with ayahRepeatCount sets currentAyah to 1', () {
      const state = RecitationState();
      final result = _run(
        state,
        const PlaySurah(reciter: _reciter, moshaf: _moshaf, surah: 1),
      );

      expect(result.state.ayahRepeatCount, 3);
      expect(result.state.currentAyah, 1);
      expect(result.effects.whereType<LoadSurah>(), hasLength(1));
    });

    test('AyahLoopExhausted sets ayahLoopExiting without advancing', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        active: true,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        currentAyah: 1,
        rangeFrom: AyahReference(surah: 1, ayah: 1),
        rangeTo: AyahReference(surah: 1, ayah: 3),
        segmentEndAyah: 3,
        ayahRepeatCount: 3,
        ayahRepeatsRemaining: 3,
      );
      final result = _run(state, const AyahLoopExhausted());

      expect(result.state.currentAyah, 1);
      expect(result.state.ayahLoopExiting, isTrue);
      expect(result.effects, isEmpty);
    });

    test('advance after final rep reaches ayah end', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        active: true,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        currentAyah: 1,
        rangeFrom: AyahReference(surah: 1, ayah: 1),
        rangeTo: AyahReference(surah: 1, ayah: 3),
        segmentEndAyah: 3,
        ayahRepeatCount: 3,
        ayahRepeatsRemaining: 3,
        ayahLoopExiting: true,
      );
      final result = _run(
        state,
        const AudioPosition(Duration(milliseconds: 5000)),
      );

      expect(result.state.currentAyah, 2);
      expect(result.state.ayahLoopExiting, isFalse);
      expect(result.state.ayahRepeatsRemaining, 3);
      expect(result.effects.whereType<LoadAyahLoop>(), hasLength(1));
      expect(result.effects.whereType<SeekAudio>(), isEmpty);
      expect(result.effects.whereType<HighlightAyah>(), hasLength(1));
    });

    test('final ayah end triggers selection end', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        active: true,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        currentAyah: 3,
        rangeFrom: AyahReference(surah: 1, ayah: 1),
        rangeTo: AyahReference(surah: 1, ayah: 3),
        segmentEndAyah: 3,
        ayahRepeatCount: 3,
        repeatsRemaining: 2,
        ayahLoopExiting: true,
      );
      final result = _run(
        state,
        const AudioPosition(Duration(milliseconds: 15000)),
      );

      expect(result.state.repeatsRemaining, 1);
      expect(result.state.ayahLoopExiting, isFalse);
      expect(result.effects.whereType<LoadRange>(), hasLength(1));
    });

    test('LoadAyahLoop effect carries reciter, moshaf, surah and ayah', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        active: true,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        currentAyah: 1,
        ayahRepeatCount: 3,
        ayahRepeatsRemaining: 3,
        ayahLoopExiting: true,
      );
      final result = _run(
        state,
        const AudioPosition(Duration(milliseconds: 5000)),
      );

      final effects = result.effects.whereType<LoadAyahLoop>();
      expect(effects, hasLength(1));
      final effect = effects.first;
      expect(effect.reciter, _reciter);
      expect(effect.moshaf, _moshaf);
      expect(effect.surah, 1);
      expect(effect.ayah, 2);
    });

    test('position tick does not regress highlight while looping', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        active: true,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        currentAyah: 2,
        ayahRepeatCount: 3,
      );
      final result = _run(
        state,
        const AudioPosition(Duration(milliseconds: 2500)),
      );

      expect(result.state.currentAyah, 2);
      expect(result.effects.whereType<HighlightAyah>(), isEmpty);
    });

    test('loop wrap decrements ayahRepeatsRemaining', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        active: true,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        currentAyah: 1,
        position: Duration(milliseconds: 4800),
        ayahRepeatCount: 3,
        ayahRepeatsRemaining: 3,
      );
      final result = _run(
        state,
        const AudioPosition(Duration(milliseconds: 200)),
      );

      expect(result.state.ayahRepeatsRemaining, 2);
      expect(result.state.currentAyah, 1);
    });
  });
}
