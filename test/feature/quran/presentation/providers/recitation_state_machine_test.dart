import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_models.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_models.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_models.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_state.dart';
import 'package:tawaq/feature/quran/domain/models/reciter.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_range.dart';
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

RecitationTimeline _timeline({List<AyahTiming>? ayat}) {
  return RecitationTimeline(
    timing: ayat == null ? null : SurahTiming(surah: 1, readId: 1, ayat: ayat),
  );
}

RecitationTransition _run(
  RecitationState state,
  RecitationEvent event, {
  RecitationTimeline? timeline,
  int ayahRepeatCount = 1,
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
  group('Play events', () {
    test('PlaySurah sets loading and emits LoadSurah', () {
      const state = RecitationState();
      final result = _run(
        state,
        const PlaySurah(reciter: _reciter, moshaf: _moshaf, surah: 1),
      );

      expect(result.state.reciter, _reciter);
      expect(result.state.moshaf, _moshaf);
      expect(result.state.surah, 1);
      expect(result.state.isLoading, isTrue);
      expect(result.state.active, isTrue);
      expect(result.effects, hasLength(2));
      expect(result.effects.whereType<CancelSleepTimer>(), hasLength(1));
      expect(result.effects.whereType<LoadSurah>(), hasLength(1));
    });

    test('PlayRange sets range and emits LoadRange + Persist', () {
      const state = RecitationState();
      final result = _run(
        state,
        const PlayRange(
          reciter: _reciter,
          moshaf: _moshaf,
          from: AyahReference(surah: 1, ayah: 2),
          to: AyahReference(surah: 1, ayah: 3),
        ),
      );

      expect(result.state.surah, 1);
      expect(result.state.isRange, isTrue);
      expect(result.state.currentAyah, 2);
      expect(result.effects.whereType<LoadRange>(), hasLength(1));
      expect(result.effects.whereType<PersistPlaybackState>(), hasLength(1));
    });

    test('PlaySurah with resumeFrom reloads at the preserved position', () {
      const resume = Duration(seconds: 30);
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        currentAyah: 2,
        position: resume,
        active: true,
      );
      final result = _run(
        state,
        const PlaySurah(
          reciter: _reciter,
          moshaf: _moshaf,
          surah: 1,
          resumeFrom: resume,
        ),
      );

      expect(result.state.isLoading, isTrue);
      expect(result.state.position, resume);
      final load = result.effects.whereType<LoadSurah>().single;
      expect(load.seekTo, resume);
    });

    test('PlayRange with resumeFrom reloads at the preserved position', () {
      const resume = Duration(seconds: 12);
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        rangeFrom: AyahReference(surah: 1, ayah: 2),
        rangeTo: AyahReference(surah: 1, ayah: 4),
        currentAyah: 3,
        position: resume,
        active: true,
      );
      final result = _run(
        state,
        const PlayRange(
          reciter: _reciter,
          moshaf: _moshaf,
          from: AyahReference(surah: 1, ayah: 2),
          to: AyahReference(surah: 1, ayah: 4),
          resumeFrom: resume,
        ),
      );

      expect(result.state.isLoading, isTrue);
      expect(result.state.position, resume);
      final load = result.effects.whereType<LoadRange>().single;
      expect(load.seekTo, resume);
    });
  });

  group('Toggle play/pause', () {
    test('playing -> pause', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        active: true,
      );
      final result = _run(state, const TogglePlayPause());
      expect(result.effects, const [PauseAudio()]);
    });

    test('paused -> resume', () {
      const state = RecitationState(
        status: RecitationStatus.paused,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        active: true,
      );
      final result = _run(state, const TogglePlayPause());
      expect(result.effects, const [ResumeAudio()]);
    });

    test('idle with metadata -> reload', () {
      const state = RecitationState(
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        active: true,
      );
      final result = _run(state, const TogglePlayPause());
      expect(result.effects.whereType<LoadSurah>(), hasLength(1));
    });
  });

  group('Seek and stop', () {
    test('Seek emits SeekAudio with clamped position', () {
      final timeline = _timeline(
        ayat: [
          const AyahTiming(ayah: 1, startMs: 0, endMs: 5000),
          const AyahTiming(ayah: 2, startMs: 5000, endMs: 10000),
        ],
      );
      const state = RecitationState(
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        active: true,
      );
      final result = _run(
        state,
        const Seek(Duration(milliseconds: 12000)),
        timeline: timeline,
      );
      expect(
        result.state.position,
        const Duration(milliseconds: 10000),
      );
      final seek = result.effects.whereType<SeekAudio>().firstOrNull;
      expect(seek, isNotNull);
      expect(seek!.position, const Duration(milliseconds: 10000));
    });

    test('Stop resets state, sets userStopped, and emits StopAudio', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        active: true,
      );
      final result = _run(state, const Stop());
      expect(result.state.isIdle, isTrue);
      expect(result.state.userStopped, isTrue);
      expect(result.state.position, Duration.zero);
      expect(result.effects, const [StopAudio()]);
    });
  });

  group('Audio lifecycle', () {
    test('AudioStarted sets playing', () {
      const state = RecitationState(status: RecitationStatus.loading);
      final result = _run(state, const AudioStarted());
      expect(result.state.isPlaying, isTrue);
    });

    test('AudioPaused sets paused', () {
      const state = RecitationState(status: RecitationStatus.playing);
      final result = _run(state, const AudioPaused());
      expect(result.state.isPaused, isTrue);
    });

    test('AudioError sets error', () {
      const state = RecitationState(status: RecitationStatus.loading);
      final result = _run(state, const AudioError('network'));
      expect(result.state.isError, isTrue);
      expect(result.state.error, 'network');
    });
  });

  group('Position tracking', () {
    final timeline = _timeline(
      ayat: [
        const AyahTiming(ayah: 1, startMs: 0, endMs: 5000),
        const AyahTiming(ayah: 2, startMs: 5000, endMs: 10000),
      ],
    );

    test('updates current ayah and highlights', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        active: true,
      );
      final result = _run(
        state,
        const AudioPosition(Duration(milliseconds: 6000)),
        timeline: timeline,
      );
      expect(result.state.currentAyah, 2);
      expect(result.effects.whereType<HighlightAyah>(), hasLength(1));
    });

    test('sleep endOfAyah pauses at ayah boundary', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        currentAyah: 1,
        sleep: RecitationSleep.endOfAyah,
        active: true,
      );
      final result = _run(
        state,
        const AudioPosition(Duration(milliseconds: 5000)),
        timeline: timeline,
      );
      expect(result.state.isPaused, isTrue);
      expect(result.effects.whereType<PauseAudio>(), hasLength(1));
    });
  });

  group('End-of-selection', () {
    final timeline = _timeline(
      ayat: [
        const AyahTiming(ayah: 1, startMs: 0, endMs: 5000),
        const AyahTiming(ayah: 2, startMs: 5000, endMs: 10000),
      ],
    );

    test('whole surah repeat restarts', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        duration: Duration(milliseconds: 10000),
        repeatsRemaining: 2,
        active: true,
      );
      final result = _run(
        state,
        const AudioPosition(Duration(milliseconds: 10000)),
        timeline: timeline,
      );
      expect(result.state.repeatsRemaining, 1);
      expect(result.state.isLoading, isTrue);
      expect(result.effects.whereType<LoadSurah>(), hasLength(1));
      expect(result.effects.whereType<SeekAudio>(), isEmpty);
    });

    test('whole surah stopAtEnd pauses', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        duration: Duration(milliseconds: 10000),
        active: true,
      );
      final result = _run(
        state,
        const AudioPosition(Duration(milliseconds: 10000)),
        timeline: timeline,
      );
      expect(result.state.isPaused, isTrue);
      expect(result.effects.whereType<PauseAudio>(), hasLength(1));
    });

    test('continueFromHere loads next surah via gapless continuation', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        rangeFrom: AyahReference(surah: 1, ayah: 5),
        rangeTo: AyahReference(surah: 1, ayah: 7),
        duration: Duration(milliseconds: 10000),
        active: true,
      );
      final result = _run(
        state,
        const AudioPosition(Duration(milliseconds: 10000)),
        timeline: timeline,
      );
      expect(result.state.surah, 2);
      expect(result.state.isLoading, isTrue);
      expect(result.effects.whereType<LoadGaplessContinuation>(), hasLength(1));
      final effect = result.effects.whereType<LoadGaplessContinuation>().first;
      expect(effect.fromSurah, 1);
      expect(effect.toSurah, 2);
    });

    test('continueFromHere with no next surah emits error not pause', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 3,
        rangeFrom: AyahReference(surah: 3, ayah: 5),
        rangeTo: AyahReference(surah: 3, ayah: 7),
        duration: Duration(milliseconds: 10000),
        active: true,
      );
      final result = _run(
        state,
        const AudioPosition(Duration(milliseconds: 10000)),
        timeline: timeline,
      );
      expect(result.state.isError, isTrue);
      expect(result.state.surah, 3);
      expect(result.effects.whereType<PauseAudio>(), isEmpty);
      expect(result.effects.whereType<LoadSurah>(), isEmpty);
    });

    test('eachAyah position within looped ayah keeps current ayah', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        duration: Duration(milliseconds: 10000),
        rangeFrom: AyahReference(surah: 1, ayah: 1),
        rangeTo: AyahReference(surah: 1, ayah: 2),
        currentAyah: 1,
        repeatsRemaining: 3,
        ayahRepeatsRemaining: 2,
        ayahRepeatCount: 3,
        active: true,
      );
      final result = _run(
        state,
        const AudioPosition(Duration(milliseconds: 2500)),
        timeline: timeline,
      );
      expect(result.state.currentAyah, 1);
      expect(result.state.ayahRepeatsRemaining, 2);
      expect(result.effects, isEmpty);
    });

    test('eachAyah AyahLoopExhausted only arms exit flag', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        duration: Duration(milliseconds: 10000),
        rangeFrom: AyahReference(surah: 1, ayah: 1),
        rangeTo: AyahReference(surah: 1, ayah: 2),
        currentAyah: 1,
        repeatsRemaining: 3,
        ayahRepeatCount: 3,
        active: true,
      );
      final result = _run(
        state,
        const AyahLoopExhausted(),
        timeline: timeline,
      );
      expect(result.state.currentAyah, 1);
      expect(result.state.ayahLoopExiting, isTrue);
      expect(result.effects, isEmpty);
    });

    test('eachAyah advances and resets budget when ayah end reached', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        duration: Duration(milliseconds: 10000),
        rangeFrom: AyahReference(surah: 1, ayah: 1),
        rangeTo: AyahReference(surah: 1, ayah: 2),
        currentAyah: 1,
        repeatsRemaining: 3,
        ayahRepeatCount: 3,
        ayahLoopExiting: true,
        active: true,
      );
      final result = _run(
        state,
        const AudioPosition(Duration(milliseconds: 5000)),
        timeline: timeline,
      );
      expect(result.state.currentAyah, 2);
      expect(result.state.ayahLoopExiting, isFalse);
      expect(result.state.ayahRepeatsRemaining, 3);
      expect(result.effects.whereType<LoadAyahLoop>(), hasLength(1));
      expect(result.effects.whereType<SeekAudio>(), hasLength(1));
      expect(result.effects.whereType<HighlightAyah>(), hasLength(1));
    });
  });

  group('Alert suspend/resume', () {
    test('AlertSuspend captures snapshot and pauses', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        active: true,
      );
      final result = _run(state, const AlertSuspend());
      expect(result.state.isPaused, isTrue);
      expect(result.state.suspendedSnapshot, isNotNull);
      expect(result.effects, const [PauseAudio(), ReleaseAudioLease()]);
    });

    test('AlertResume restores snapshot and reloads when playing', () {
      const playing = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        active: true,
      );
      final suspended = _run(playing, const AlertSuspend()).state;
      final result = _run(suspended, const AlertResume());
      expect(result.state.suspendedSnapshot, isNull);
      expect(result.effects.whereType<LoadSurah>(), hasLength(1));
    });
  });

  group('Sleep timer cleared on new play', () {
    test('PlaySurah emits CancelSleepTimer and clears sleep state', () {
      const state = RecitationState(
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        sleep: RecitationSleep.endOfAyah,
        active: true,
      );
      final result = _run(
        state,
        const PlaySurah(reciter: _reciter, moshaf: _moshaf, surah: 2),
      );
      expect(result.state.sleep, RecitationSleep.off);
      expect(result.effects.whereType<CancelSleepTimer>(), hasLength(1));
      expect(result.effects.whereType<LoadSurah>(), hasLength(1));
    });

    test('PlayRange emits CancelSleepTimer and clears sleep state', () {
      const state = RecitationState(
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        sleep: RecitationSleep.endOfRange,
        active: true,
      );
      final result = _run(
        state,
        const PlayRange(
          reciter: _reciter,
          moshaf: _moshaf,
          from: AyahReference(surah: 1, ayah: 2),
          to: AyahReference(surah: 1, ayah: 3),
        ),
      );
      expect(result.state.sleep, RecitationSleep.off);
      expect(result.effects.whereType<CancelSleepTimer>(), hasLength(1));
      expect(result.effects.whereType<LoadRange>(), hasLength(1));
    });
  });

  group('Skip routing', () {
    test('SkipNext within range seeks to next ayah', () {
      final timeline = _timeline(
        ayat: [
          const AyahTiming(ayah: 1, startMs: 0, endMs: 5000),
          const AyahTiming(ayah: 2, startMs: 5000, endMs: 10000),
          const AyahTiming(ayah: 3, startMs: 10000, endMs: 15000),
        ],
      );
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        rangeFrom: AyahReference(surah: 1, ayah: 1),
        rangeTo: AyahReference(surah: 1, ayah: 3),
        segmentStartAyah: 1,
        segmentEndAyah: 3,
        currentAyah: 1,
        active: true,
      );
      final result = _run(state, const SkipNext(), timeline: timeline);
      expect(result.state.currentAyah, 2);
      expect(result.effects.whereType<SeekAudio>(), hasLength(1));
      expect(
        result.effects.whereType<SeekAudio>().first.position,
        const Duration(milliseconds: 5000),
      );
    });

    test('SkipNext past segment end loads next surah', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        active: true,
      );
      final result = _run(state, const SkipNext());
      expect(result.state.surah, 2);
      expect(result.state.isLoading, isTrue);
      expect(result.effects.whereType<LoadSurah>(), hasLength(1));
    });

    test('SkipNext with no next surah does nothing', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 3,
        active: true,
      );
      final result = _run(state, const SkipNext());
      expect(result.state.surah, 3);
      expect(result.effects, isEmpty);
    });

    test('SkipPrevious within range seeks to previous ayah', () {
      final timeline = _timeline(
        ayat: [
          const AyahTiming(ayah: 1, startMs: 0, endMs: 5000),
          const AyahTiming(ayah: 2, startMs: 5000, endMs: 10000),
          const AyahTiming(ayah: 3, startMs: 10000, endMs: 15000),
        ],
      );
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        rangeFrom: AyahReference(surah: 1, ayah: 1),
        rangeTo: AyahReference(surah: 1, ayah: 3),
        segmentStartAyah: 1,
        segmentEndAyah: 3,
        currentAyah: 3,
        active: true,
      );
      final result = _run(state, const SkipPrevious(), timeline: timeline);
      expect(result.state.currentAyah, 2);
      expect(result.effects.whereType<SeekAudio>(), hasLength(1));
    });

    test('SkipPrevious before segment start loads previous surah', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 2,
        active: true,
      );
      final result = _run(state, const SkipPrevious());
      expect(result.state.surah, 1);
      expect(result.state.isLoading, isTrue);
      expect(result.effects.whereType<LoadSurah>(), hasLength(1));
    });
  });

  group('Preset-to-intent mapping', () {
    test('thisSurah produces PlayWholeSurahIntent', () {
      final result = playbackIntentForPreset(
        preset: RangeScopePreset.thisSurah,
        reciter: _reciter,
        moshaf: _moshaf,
        from: const AyahReference(surah: 1, ayah: 1),
        to: const AyahReference(surah: 1, ayah: 7),
      );
      expect(result, isA<PlayWholeSurahIntent>());
    });

    test('continueFromHere from ayah 1 produces PlayWholeSurahIntent', () {
      final result = playbackIntentForPreset(
        preset: RangeScopePreset.continueFromHere,
        reciter: _reciter,
        moshaf: _moshaf,
        from: const AyahReference(surah: 1, ayah: 1),
      );
      expect(result, isA<PlayWholeSurahIntent>());
    });

    test('continueFromHere from ayah > 1 produces PlayAyahRangeIntent', () {
      final result = playbackIntentForPreset(
        preset: RangeScopePreset.continueFromHere,
        reciter: _reciter,
        moshaf: _moshaf,
        from: const AyahReference(surah: 1, ayah: 5),
      ) as PlayAyahRangeIntent;
      expect(result.from, const AyahReference(surah: 1, ayah: 5));
      expect(result.to, isNull);
    });

    test('thisAyah bounded preset produces PlayAyahRangeIntent', () {
      final result = playbackIntentForPreset(
        preset: RangeScopePreset.thisAyah,
        reciter: _reciter,
        moshaf: _moshaf,
        from: const AyahReference(surah: 1, ayah: 3),
        to: const AyahReference(surah: 1, ayah: 3),
      );
      expect(result, isA<PlayAyahRangeIntent>());
    });

    test('custom preset produces PlayAyahRangeIntent', () {
      final result = playbackIntentForPreset(
        preset: RangeScopePreset.custom,
        reciter: _reciter,
        moshaf: _moshaf,
        from: const AyahReference(surah: 1, ayah: 2),
        to: const AyahReference(surah: 1, ayah: 6),
      );
      expect(result, isA<PlayAyahRangeIntent>());
    });
  });

  group('Coverage of remaining transitions', () {
    test('SetSleep updates sleep state with no effects', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        active: true,
      );
      final result = _run(state, const SetSleep(RecitationSleep.endOfSurah));
      expect(result.state.sleep, RecitationSleep.endOfSurah);
      expect(result.effects, isEmpty);
    });

    test('SetRepeatCounts updates range and ayah budgets', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        active: true,
      );
      final result = _run(
        state,
        const SetRepeatCounts(rangeRepeatCount: 3, ayahRepeatCount: 2),
      );
      expect(result.state.repeatsRemaining, 3);
      expect(result.state.ayahRepeatsRemaining, 2);
      expect(result.state.ayahRepeatCount, 2);
      expect(result.effects, isEmpty);
    });

    test('SetRepeatCounts clamps below 1 to 1', () {
      const state = RecitationState(
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        active: true,
      );
      final result = _run(
        state,
        const SetRepeatCounts(rangeRepeatCount: 0, ayahRepeatCount: 0),
      );
      expect(result.state.repeatsRemaining, 1);
      expect(result.state.ayahRepeatsRemaining, 1);
    });

    test('RecitationSettingsLoaded restores session metadata', () {
      const state = RecitationState(
        status: RecitationStatus.error,
        error: 'previous',
      );
      final result = _run(
        state,
        const RecitationSettingsLoaded(
          reciter: _reciter,
          moshaf: _moshaf,
          surah: 2,
          rangeFrom: AyahReference(surah: 2, ayah: 1),
          rangeTo: AyahReference(surah: 2, ayah: 5),
        ),
      );
      expect(result.state.reciter, _reciter);
      expect(result.state.moshaf, _moshaf);
      expect(result.state.surah, 2);
      expect(result.state.rangeFrom, const AyahReference(surah: 2, ayah: 1));
      expect(result.state.rangeTo, const AyahReference(surah: 2, ayah: 5));
      expect(result.state.active, isTrue);
      expect(result.state.error, isNull);
      expect(result.effects, isEmpty);
    });

    test('AudioLoading sets loading status', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        active: true,
      );
      final result = _run(state, const AudioLoading());
      expect(result.state.isLoading, isTrue);
      expect(result.effects, isEmpty);
    });

    test('AudioBuffering sets buffering status', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        active: true,
      );
      final result = _run(state, const AudioBuffering());
      expect(result.state.status, RecitationStatus.buffering);
      expect(result.effects, isEmpty);
    });

    test('AudioDuration updates duration when larger', () {
      const state = RecitationState(
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        active: true,
      );
      final result = _run(
        state,
        const AudioDuration(Duration(seconds: 42)),
      );
      expect(result.state.duration, const Duration(seconds: 42));
    });

    test('AudioDuration keeps existing larger duration', () {
      const state = RecitationState(
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        duration: Duration(seconds: 60),
        active: true,
      );
      final result = _run(
        state,
        const AudioDuration(Duration(seconds: 30)),
      );
      expect(result.state.duration, const Duration(seconds: 60));
    });

    test('AudioCompleted delegates to selection end (whole surah pauses)', () {
      final timeline = _timeline(
        ayat: [
          const AyahTiming(ayah: 1, startMs: 0, endMs: 5000),
        ],
      );
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        duration: Duration(milliseconds: 5000),
        active: true,
      );
      final result = _run(
        state,
        const AudioCompleted(),
        timeline: timeline,
      );
      expect(result.state.isPaused, isTrue);
      expect(result.effects.whereType<PauseAudio>(), hasLength(1));
    });

    test('AudioCompleted with repeats remaining emits LoadSurah reload', () {
      final timeline = _timeline(
        ayat: [
          const AyahTiming(ayah: 1, startMs: 0, endMs: 5000),
        ],
      );
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        duration: Duration(milliseconds: 5000),
        repeatsRemaining: 2,
        active: true,
      );
      final result = _run(
        state,
        const AudioCompleted(),
        timeline: timeline,
      );
      expect(result.state.repeatsRemaining, 1);
      expect(result.state.isLoading, isTrue);
      expect(result.effects.whereType<LoadSurah>(), hasLength(1));
      expect(result.effects.whereType<SeekAudio>(), isEmpty);
    });

    test('TogglePlayPause at end seeks to start and resumes', () {
      final timeline = _timeline(
        ayat: [
          const AyahTiming(ayah: 1, startMs: 0, endMs: 5000),
        ],
      );
      const state = RecitationState(
        status: RecitationStatus.paused,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        position: Duration(milliseconds: 5000),
        duration: Duration(milliseconds: 5000),
        active: true,
      );
      final result = _run(state, const TogglePlayPause(), timeline: timeline);
      expect(result.state.position, timeline.rangeStart);
      expect(result.effects.whereType<SeekAudio>(), hasLength(1));
      expect(result.effects.whereType<ResumeAudio>(), hasLength(1));
    });

    test('AlertSuspend when idle is a no-op', () {
      const state = RecitationState(
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        active: true,
      );
      final result = _run(state, const AlertSuspend());
      expect(result.state.suspendedSnapshot, isNull);
      expect(result.effects, isEmpty);
    });

    test('AlertResume without snapshot is a no-op', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        active: true,
      );
      final result = _run(state, const AlertResume());
      expect(result.state.suspendedSnapshot, isNull);
      expect(result.effects, isEmpty);
    });
  });
}
