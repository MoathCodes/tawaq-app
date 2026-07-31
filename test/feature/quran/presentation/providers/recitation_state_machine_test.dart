import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
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

late MushafReaderController _intentMushaf;

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
  bool trackLoaded = false,
  bool? nativePlayWhenReady,
}) {
  return transition(
    state,
    event,
    timeline: timeline ?? _timeline(),
    defaultAyahRepeatCount: ayahRepeatCount,
    defaultRangeRepeatCount: rangeRepeatCount,
    trackLoaded: trackLoaded,
    nativePlayWhenReady: nativePlayWhenReady,
  );
}

void main() {
  setUpAll(() async {
    _intentMushaf = MushafReaderController.withRepository(
      repository: _IntentMushafRepo(),
    );
    await _intentMushaf.ensureReady();
  });

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
      expect(result.effects.whereType<CancelSleepTimer>(), hasLength(1));
      expect(
        result.effects.whereType<ResetNativePlaybackModes>(),
        hasLength(1),
      );
      expect(result.effects.whereType<ClearNativeAbLoop>(), hasLength(1));
      expect(result.effects.whereType<SetNativeLoop>(), hasLength(1));
      expect(result.effects.whereType<LoadSurah>(), hasLength(1));
      expect(result.effects.whereType<PersistPlaybackState>(), hasLength(1));
      final persist = result.effects.whereType<PersistPlaybackState>().single;
      expect(persist.surah, 1);
      expect(persist.rangeFromSurah, isNull);
      expect(persist.rangeToSurah, isNull);
    });

    test('PlaySurah with persistRange keeps full-surah endpoints', () {
      const state = RecitationState();
      final result = _run(
        state,
        const PlaySurah(
          reciter: _reciter,
          moshaf: _moshaf,
          surah: 1,
          persistRangeFrom: AyahReference(surah: 1, ayah: 1),
          persistRangeTo: AyahReference(surah: 1, ayah: 7),
        ),
      );

      final persist = result.effects.whereType<PersistPlaybackState>().single;
      expect(persist.surah, 1);
      expect(persist.rangeFromSurah, 1);
      expect(persist.rangeFromAyah, 1);
      expect(persist.rangeToSurah, 1);
      expect(persist.rangeToAyah, 7);
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

    test('PlayRange openEnded keeps rangeTo null despite segment end', () {
      const state = RecitationState();
      final result = _run(
        state,
        const PlayRange(
          reciter: _reciter,
          moshaf: _moshaf,
          from: AyahReference(surah: 1, ayah: 1),
          to: AyahReference(surah: 1, ayah: 7),
          globalFrom: AyahReference(surah: 1, ayah: 1),
          openEnded: true,
        ),
      );

      expect(result.state.rangeFrom, const AyahReference(surah: 1, ayah: 1));
      expect(result.state.rangeTo, isNull);
      expect(result.state.segmentEndAyah, 7);
      expect(result.state.isRange, isTrue);
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

    test('PlaySurah with range repeat emits SetNativeLoop.file', () {
      const state = RecitationState();
      final result = _run(
        state,
        const PlaySurah(reciter: _reciter, moshaf: _moshaf, surah: 1),
        rangeRepeatCount: 3,
      );
      final loop = result.effects.whereType<SetNativeLoop>().single;
      expect(loop.mode, NativeLoopMode.file);
    });

    test('PlayRange emits SetNativeLoop.off for bounded range', () {
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
      final loop = result.effects.whereType<SetNativeLoop>().single;
      expect(loop.mode, NativeLoopMode.off);
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

    test('track loaded + native playing -> pause only (no reload)', () {
      const state = RecitationState(
        status: RecitationStatus.loading,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        position: Duration(seconds: 45),
        active: true,
      );
      final result = _run(
        state,
        const TogglePlayPause(),
        trackLoaded: true,
        nativePlayWhenReady: true,
      );
      expect(result.effects, const [PauseAudio()]);
      expect(result.effects.whereType<LoadSurah>(), isEmpty);
    });

    test('track loaded + native paused -> resume only (no reload)', () {
      const state = RecitationState(
        status: RecitationStatus.loading,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        position: Duration(seconds: 45),
        active: true,
      );
      final result = _run(
        state,
        const TogglePlayPause(),
        trackLoaded: true,
        nativePlayWhenReady: false,
      );
      expect(result.effects, const [ResumeAudio()]);
      expect(result.effects.whereType<LoadSurah>(), isEmpty);
    });

    test('userStopped -> replay from start (not stale position)', () {
      const state = RecitationState(
        userStopped: true,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        position: Duration(seconds: 45),
        active: true,
      );
      final result = _run(state, const TogglePlayPause());
      final load = result.effects.whereType<LoadSurah>().single;
      expect(load.seekTo, isNull);
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

    test('idle with saved position resumes from checkpoint', () {
      const resume = Duration(seconds: 45);
      const state = RecitationState(
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        position: resume,
        active: true,
      );
      final result = _run(state, const TogglePlayPause());
      final load = result.effects.whereType<LoadSurah>().single;
      expect(load.seekTo, resume);
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
        const Seek(Duration(milliseconds: 7500)),
        timeline: timeline,
      );
      expect(
        result.state.position,
        const Duration(milliseconds: 5000),
      );
      expect(result.state.currentAyah, 2);
      expect(
        result.state.pendingSeekTarget,
        const Duration(milliseconds: 5000),
      );
      final seek = result.effects.whereType<SeekAudio>().firstOrNull;
      expect(seek, isNotNull);
      expect(seek!.position, const Duration(milliseconds: 5000));
      expect(result.effects.whereType<HighlightAyah>(), hasLength(1));
    });

    test('Seek on untimed timeline emits SeekAudio at scrubbed position', () {
      const target = Duration(milliseconds: 723046);
      const state = RecitationState(
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        active: true,
      );
      final result = _run(
        state,
        const Seek(target),
        timeline: _timeline(),
      );
      expect(result.state.position, target);
      expect(result.state.pendingSeekTarget, target);
      final seek = result.effects.whereType<SeekAudio>().firstOrNull;
      expect(seek, isNotNull);
      expect(seek!.position, target);
      expect(result.effects.whereType<HighlightAyah>(), isEmpty);
    });

    test('stale AudioPosition is ignored while pending seek is active', () {
      final timeline = _timeline(
        ayat: [
          const AyahTiming(ayah: 1, startMs: 0, endMs: 5000),
          const AyahTiming(ayah: 2, startMs: 5000, endMs: 10000),
        ],
      );
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        position: Duration(milliseconds: 1000),
        currentAyah: 1,
        active: true,
      );
      final sought = _run(
        state,
        const Seek(Duration(milliseconds: 5000)),
        timeline: timeline,
      );
      final tick = _run(
        sought.state,
        const AudioPosition(Duration(milliseconds: 1000)),
        timeline: timeline,
      );
      expect(tick.state.position, const Duration(milliseconds: 5000));
      expect(tick.state.currentAyah, 2);
    });

    test('Seek while ended transitions to paused when position > 0', () {
      final timeline = _timeline(
        ayat: const [AyahTiming(ayah: 1, startMs: 0, endMs: 5000)],
      );
      const state = RecitationState(
        status: RecitationStatus.ended,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        active: true,
      );
      final result = _run(
        state,
        const Seek(Duration()),
        timeline: timeline,
      );
      expect(result.state.isEnded, isTrue);
      expect(result.state.isPaused, isFalse);
    });

    test('Seek while ended with non-zero position transitions to paused', () {
      final timeline = _timeline(
        ayat: const [
          AyahTiming(ayah: 1, startMs: 0, endMs: 5000),
          AyahTiming(ayah: 2, startMs: 5000, endMs: 10000),
        ],
      );
      const state = RecitationState(
        status: RecitationStatus.ended,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        active: true,
      );
      final result = _run(
        state,
        const Seek(Duration(milliseconds: 6000)),
        timeline: timeline,
      );
      expect(result.state.isPaused, isTrue);
      expect(result.state.isEnded, isFalse);
      expect(result.state.position, const Duration(milliseconds: 5000));
    });

    test('PlaySurah clears pendingSeekTarget and resumes position ticks', () {
      final timeline = _timeline(
        ayat: const [AyahTiming(ayah: 1, startMs: 0, endMs: 5000)],
      );
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        position: Duration(milliseconds: 5000),
        currentAyah: 1,
        pendingSeekTarget: Duration(milliseconds: 5000),
        active: true,
      );
      final played = _run(
        state,
        const PlaySurah(reciter: _reciter, moshaf: _moshaf, surah: 1),
      );
      expect(played.state.pendingSeekTarget, isNull);

      final tick = _run(
        played.state.copyWith(status: RecitationStatus.playing),
        const AudioPosition(Duration(milliseconds: 1200)),
        timeline: timeline,
      );
      expect(tick.state.position, const Duration(milliseconds: 1200));
    });

    test('Stop clears pendingSeekTarget', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        pendingSeekTarget: Duration(milliseconds: 5000),
        active: true,
      );
      final result = _run(state, const Stop());
      expect(result.state.pendingSeekTarget, isNull);
    });

    test('ended seek then play resumes from scrubbed position', () {
      final timeline = _timeline(
        ayat: const [
          AyahTiming(ayah: 1, startMs: 0, endMs: 5000),
          AyahTiming(ayah: 2, startMs: 5000, endMs: 10000),
        ],
      );
      const state = RecitationState(
        status: RecitationStatus.ended,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        duration: Duration(milliseconds: 10000),
        ayahRepeatCount: 3,
        active: true,
      );
      final sought = _run(
        state,
        const Seek(Duration(milliseconds: 6000)),
        timeline: timeline,
      );
      expect(sought.state.isPaused, isTrue);
      expect(sought.state.position, const Duration(milliseconds: 5000));

      final played = _run(
        sought.state,
        const TogglePlayPause(),
        timeline: timeline,
        ayahRepeatCount: 3,
        rangeRepeatCount: 2,
      );
      expect(played.state.isPaused, isTrue);
      expect(played.state.position, const Duration(milliseconds: 5000));
      expect(played.effects, const [ResumeAudio()]);
    });

    test('ended toggle always replays from start with full repeat budgets', () {
      const state = RecitationState(
        status: RecitationStatus.ended,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        duration: Duration(milliseconds: 10000),
        position: Duration(milliseconds: 8000),
        ayahRepeatCount: 3,
        active: true,
      );
      final played = _run(
        state,
        const TogglePlayPause(),
        ayahRepeatCount: 3,
        rangeRepeatCount: 2,
      );
      expect(played.state.isLoading, isTrue);
      expect(played.state.repeatsRemaining, 2);
      expect(played.state.ayahRepeatsRemaining, 3);
      expect(played.state.position, Duration.zero);
      final load = played.effects.whereType<LoadSurah>().single;
      expect(load.seekTo, isNull);
    });

    test('Seek during loading preserves requested position', () {
      const state = RecitationState(
        status: RecitationStatus.loading,
        timelinePending: true,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        active: true,
      );
      final result = _run(
        state,
        const Seek(Duration(milliseconds: 5000)),
        timeline: const RecitationTimeline(),
      );
      expect(result.state.position, const Duration(milliseconds: 5000));
      expect(
        result.state.pendingSeekTarget,
        const Duration(milliseconds: 5000),
      );
      expect(
        result.effects.whereType<SeekAudio>().single.position,
        const Duration(milliseconds: 5000),
      );
    });

    test('SeekFailed reverts optimistic position', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        position: Duration(milliseconds: 8000),
        pendingSeekTarget: Duration(milliseconds: 3000),
        active: true,
      );
      const revert = Duration(milliseconds: 1200);
      final result = _run(state, const SeekFailed(revertTo: revert));
      expect(result.state.position, revert);
      expect(result.state.pendingSeekTarget, isNull);
    });

    test('PendingSeekTimeout clears pending seek guard and reverts', () {
      final timeline = _timeline(
        ayat: const [AyahTiming(ayah: 1, startMs: 0, endMs: 5000)],
      );
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        position: Duration(milliseconds: 5000),
        currentAyah: 1,
        pendingSeekTarget: Duration(milliseconds: 5000),
        active: true,
      );
      const revert = Duration(milliseconds: 900);
      final timedOut = _run(
        state,
        const PendingSeekTimeout(revertTo: revert),
      );
      expect(timedOut.state.pendingSeekTarget, isNull);
      expect(timedOut.state.position, revert);

      final tick = _run(
        timedOut.state,
        const AudioPosition(Duration(milliseconds: 1200)),
        timeline: timeline,
      );
      expect(tick.state.position, const Duration(milliseconds: 1200));
    });

    test('AudioPosition ignored after Stop (userStopped + idle)', () {
      const state = RecitationState(
        userStopped: true,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        active: true,
      );
      final result = _run(
        state,
        const AudioPosition(Duration(seconds: 45)),
      );
      expect(result.state.position, Duration.zero);
    });

    test('Stop resets state, sets userStopped, and emits teardown effects', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        ayahRepeatCount: 3,
        ayahRepeatsRemaining: 2,
        active: true,
      );
      final result = _run(state, const Stop());
      expect(result.state.isIdle, isTrue);
      expect(result.state.userStopped, isTrue);
      expect(result.state.position, Duration.zero);
      expect(result.state.ayahRepeatsRemaining, 3);
      expect(result.state.ayahLoopExiting, isFalse);
      expect(result.effects.whereType<StopAudio>(), hasLength(1));
      expect(result.effects.whereType<ClearPlaybackPosition>(), hasLength(1));
      expect(
        result.effects.whereType<ResetNativePlaybackModes>(),
        hasLength(1),
      );
      expect(result.effects.whereType<ClearNativeAbLoop>(), hasLength(1));
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

    test('skips HighlightAyah while loading', () {
      const state = RecitationState(
        status: RecitationStatus.loading,
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
      expect(result.effects.whereType<HighlightAyah>(), isEmpty);
    });

    test('skips HighlightAyah while timelinePending', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        timelinePending: true,
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
      expect(result.effects.whereType<HighlightAyah>(), isEmpty);
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

    test('whole surah repeat decrements via native Loop.file', () {
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
        const AudioCompleted(),
        timeline: timeline,
      );
      expect(result.state.repeatsRemaining, 1);
      expect(result.state.isPlaying, isTrue);
      expect(result.effects, isEmpty);
      expect(result.effects.whereType<LoadSurah>(), isEmpty);
    });

    test('whole surah repeat reloads when ayahRepeatCount > 1', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        duration: Duration(milliseconds: 10000),
        repeatsRemaining: 2,
        ayahRepeatCount: 3,
        active: true,
      );
      final result = _run(
        state,
        const AudioCompleted(),
        timeline: timeline,
      );
      expect(result.state.repeatsRemaining, 1);
      expect(result.state.isLoading, isTrue);
      expect(result.effects.whereType<LoadRange>(), isEmpty);
      expect(result.effects.whereType<LoadSurah>(), hasLength(1));
    });

    test('whole surah stopAtEnd ends with pause-at-EOF', () {
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
        const AudioCompleted(),
        timeline: timeline,
      );
      expect(result.state.isEnded, isTrue);
      expect(result.state.position, const Duration(milliseconds: 10000));
      expect(result.effects.whereType<PauseAtEof>(), hasLength(1));
      expect(result.effects.whereType<SetNativeLoop>(), hasLength(1));
      expect(result.effects.whereType<StopAudio>(), isEmpty);
      expect(result.effects.whereType<ClearPlaybackPosition>(), isEmpty);
    });

    test('open-ended continueFromHere loads next surah via gapless', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        rangeFrom: AyahReference(surah: 1, ayah: 5),
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
      expect(
        result.state.rangeFrom,
        const AyahReference(surah: 1, ayah: 5),
      );
      expect(result.state.rangeTo, isNull);
      expect(result.state.segmentStartAyah, isNull);
      expect(result.state.segmentEndAyah, isNull);
      expect(result.effects.whereType<LoadGaplessContinuation>(), hasLength(1));
      final effect = result.effects.whereType<LoadGaplessContinuation>().first;
      expect(effect.fromSurah, 1);
      expect(effect.toSurah, 2);

      // Second hop keeps the open-ended session and chains further.
      final hop2 = _run(
        result.state.copyWith(
          status: RecitationStatus.playing,
          duration: const Duration(milliseconds: 10000),
        ),
        const AudioCompleted(),
        timeline: timeline,
      );
      expect(hop2.state.surah, 3);
      expect(
        hop2.state.rangeFrom,
        const AyahReference(surah: 1, ayah: 5),
      );
      expect(hop2.effects.whereType<LoadGaplessContinuation>(), hasLength(1));
      expect(
        hop2.effects.whereType<LoadGaplessContinuation>().first.toSurah,
        3,
      );
    });

    test('open-ended skips unpublished surahs in moshaf surahList', () {
      const sparseMoshaf = Moshaf(
        id: 1,
        name: 'Hafs',
        server: 'https://example.com/',
        surahList: [1, 3],
        surahTotal: 2,
      );
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: Reciter(id: 1, name: 'Test', moshaf: [sparseMoshaf]),
        moshaf: sparseMoshaf,
        surah: 1,
        rangeFrom: AyahReference(surah: 1, ayah: 1),
        duration: Duration(milliseconds: 10000),
        active: true,
      );
      final result = _run(
        state,
        const AudioCompleted(),
        timeline: timeline,
      );
      expect(result.state.surah, 3);
      expect(result.state.isLoading, isTrue);
      expect(
        result.state.rangeFrom,
        const AyahReference(surah: 1, ayah: 1),
      );
      final effect = result.effects.whereType<LoadGaplessContinuation>().single;
      expect(effect.fromSurah, 1);
      expect(effect.toSurah, 3);
    });

    test('open-ended with no next surah ends cleanly', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 3,
        rangeFrom: AyahReference(surah: 3, ayah: 5),
        duration: Duration(milliseconds: 10000),
        active: true,
      );
      final result = _run(
        state,
        const AudioPosition(Duration(milliseconds: 10000)),
        timeline: timeline,
      );
      expect(result.state.isEnded, isTrue);
      expect(result.state.isError, isFalse);
      expect(result.state.surah, 3);
      expect(result.state.position, const Duration(milliseconds: 10000));
      expect(result.effects.whereType<PauseAtEof>(), hasLength(1));
      expect(result.effects.whereType<SetNativeLoop>(), hasLength(1));
      expect(result.effects.whereType<LoadSurah>(), isEmpty);
      expect(result.effects.whereType<LoadGaplessContinuation>(), isEmpty);
    });

    test('open-ended finishing surah 114 ends cleanly', () {
      const lastMoshaf = Moshaf(
        id: 1,
        name: 'Hafs',
        server: 'https://example.com/',
        surahList: [113, 114],
        surahTotal: 2,
      );
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: Reciter(id: 1, name: 'Test', moshaf: [lastMoshaf]),
        moshaf: lastMoshaf,
        surah: 114,
        rangeFrom: AyahReference(surah: 113, ayah: 1),
        duration: Duration(milliseconds: 10000),
        active: true,
      );
      final result = _run(
        state,
        const AudioCompleted(),
        timeline: timeline,
      );
      expect(result.state.isEnded, isTrue);
      expect(result.state.isError, isFalse);
      expect(result.state.error, isNull);
      expect(result.effects.whereType<PauseAtEof>(), hasLength(1));
      expect(result.effects.whereType<LoadGaplessContinuation>(), isEmpty);
    });

    test('bounded range ends at range boundary with pause-at-EOF', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        rangeFrom: AyahReference(surah: 1, ayah: 1),
        rangeTo: AyahReference(surah: 1, ayah: 2),
        segmentStartAyah: 1,
        segmentEndAyah: 2,
        duration: Duration(milliseconds: 10000),
        active: true,
      );
      final result = _run(
        state,
        const AudioPosition(Duration(milliseconds: 10000)),
        timeline: timeline,
      );
      expect(result.state.isEnded, isTrue);
      expect(result.effects.whereType<PauseAtEof>(), hasLength(1));
      expect(result.effects.whereType<StopAudio>(), isEmpty);
      expect(result.effects.whereType<ClearPlaybackPosition>(), isEmpty);
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
        loadGeneration: 3,
        pendingSeekTarget: Duration(seconds: 4),
      );
      final result = _run(state, const AlertSuspend());
      expect(result.state.isPaused, isTrue);
      expect(result.state.suspendedSnapshot, isNotNull);
      expect(result.state.loadGeneration, 4);
      expect(result.state.pendingSeekTarget, isNull);
      expect(result.effects, const [PauseAudio(), ReleaseAudioLease()]);
    });

    test('AlertSuspend yields while buffering', () {
      const state = RecitationState(
        status: RecitationStatus.buffering,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        active: true,
        loadGeneration: 1,
      );
      final result = _run(state, const AlertSuspend());
      expect(result.state.suspendedSnapshot, isNotNull);
      expect(result.state.loadGeneration, 2);
      expect(result.effects, const [PauseAudio(), ReleaseAudioLease()]);
    });

    test('AlertSuspend yields while loading', () {
      const state = RecitationState(
        status: RecitationStatus.loading,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        active: true,
      );
      final result = _run(state, const AlertSuspend());
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
      expect(result.effects.whereType<PauseAudio>(), isEmpty);
    });

    test('AlertResume reloads paused sessions then pauses', () {
      const paused = RecitationState(
        status: RecitationStatus.paused,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        position: Duration(seconds: 12),
        active: true,
      );
      final suspended = _run(paused, const AlertSuspend()).state;
      final result = _run(suspended, const AlertResume());
      expect(result.state.suspendedSnapshot, isNull);
      expect(result.effects.whereType<LoadSurah>(), hasLength(1));
      expect(
        result.effects.whereType<LoadSurah>().first.seekTo,
        paused.position,
      );
      expect(result.effects.whereType<PauseAudio>(), hasLength(1));
    });

    test('AlertResume reloads ranged sessions via LoadRange', () {
      const playing = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        rangeFrom: AyahReference(surah: 1, ayah: 2),
        rangeTo: AyahReference(surah: 1, ayah: 5),
        segmentStartAyah: 2,
        segmentEndAyah: 5,
        currentAyah: 3,
        position: Duration(seconds: 4),
        active: true,
      );
      final suspended = _run(playing, const AlertSuspend()).state;
      final result = _run(suspended, const AlertResume());
      expect(result.effects.whereType<LoadRange>(), hasLength(1));
      expect(result.effects.whereType<LoadSurah>(), isEmpty);
      final load = result.effects.whereType<LoadRange>().first;
      expect(load.from, const AyahReference(surah: 1, ayah: 2));
      expect(load.to, const AyahReference(surah: 1, ayah: 5));
      expect(load.seekTo, playing.position);
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
    test('SkipAyahNext within range seeks to next ayah', () {
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
      final result = _run(state, const SkipAyahNext(), timeline: timeline);
      expect(result.state.currentAyah, 2);
      expect(result.effects.whereType<SeekAudio>(), hasLength(1));
      expect(result.effects.whereType<HighlightAyah>(), hasLength(1));
      expect(
        result.effects.whereType<SeekAudio>().first.position,
        const Duration(milliseconds: 5000),
      );
    });

    test('SkipAyahNext at last ayah in range is a no-op', () {
      final timeline = _timeline(
        ayat: [
          const AyahTiming(ayah: 1, startMs: 0, endMs: 5000),
          const AyahTiming(ayah: 2, startMs: 5000, endMs: 10000),
        ],
      );
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        rangeFrom: AyahReference(surah: 1, ayah: 1),
        rangeTo: AyahReference(surah: 1, ayah: 2),
        segmentStartAyah: 1,
        segmentEndAyah: 2,
        currentAyah: 2,
        active: true,
      );
      final result = _run(state, const SkipAyahNext(), timeline: timeline);
      expect(result.state.currentAyah, 2);
      expect(result.effects, isEmpty);
    });

    test('SkipSurahNext loads next surah', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        active: true,
      );
      final result = _run(state, const SkipSurahNext());
      expect(result.state.surah, 2);
      expect(result.state.isLoading, isTrue);
      expect(result.effects.whereType<LoadSurah>(), hasLength(1));
    });

    test('SkipSurahNext with no next surah does nothing', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 3,
        active: true,
      );
      final result = _run(state, const SkipSurahNext());
      expect(result.state.surah, 3);
      expect(result.effects, isEmpty);
    });

    test('SkipAyahPrevious within range seeks to previous ayah', () {
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
      final result = _run(state, const SkipAyahPrevious(), timeline: timeline);
      expect(result.state.currentAyah, 2);
      expect(result.effects.whereType<SeekAudio>(), hasLength(1));
    });

    test('SkipSurahPrevious loads previous surah', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 2,
        active: true,
      );
      final result = _run(state, const SkipSurahPrevious());
      expect(result.state.surah, 1);
      expect(result.state.isLoading, isTrue);
      expect(result.effects.whereType<LoadSurah>(), hasLength(1));
    });

    test('SkipSurahNext at rangeTo surah is a no-op', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 3,
        rangeFrom: AyahReference(surah: 2, ayah: 1),
        rangeTo: AyahReference(surah: 3, ayah: 5),
        active: true,
      );
      final result = _run(state, const SkipSurahNext());
      expect(result.state.surah, 3);
      expect(result.effects, isEmpty);
    });

    test('SkipSurahPrevious before rangeFrom surah is a no-op', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 2,
        rangeFrom: AyahReference(surah: 2, ayah: 1),
        rangeTo: AyahReference(surah: 3, ayah: 5),
        active: true,
      );
      final result = _run(state, const SkipSurahPrevious());
      expect(result.state.surah, 2);
      expect(result.effects, isEmpty);
    });

    test('SkipSurahNext inside range preserves global bounds', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 2,
        rangeFrom: AyahReference(surah: 2, ayah: 3),
        rangeTo: AyahReference(surah: 3, ayah: 5),
        segmentStartAyah: 3,
        active: true,
      );
      final result = _run(state, const SkipSurahNext());
      expect(result.state.surah, 3);
      expect(result.state.rangeFrom, state.rangeFrom);
      expect(result.state.rangeTo, state.rangeTo);
      expect(result.state.segmentStartAyah, 1);
      expect(result.state.segmentEndAyah, 5);
      expect(result.effects.whereType<LoadRange>(), hasLength(1));
      expect(result.effects.whereType<LoadSurah>(), isEmpty);
    });

    test('SkipSurahPrevious inside range preserves global bounds', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 3,
        rangeFrom: AyahReference(surah: 2, ayah: 3),
        rangeTo: AyahReference(surah: 3, ayah: 5),
        segmentStartAyah: 1,
        segmentEndAyah: 5,
        active: true,
      );
      final result = transition(
        state,
        const SkipSurahPrevious(),
        timeline: _timeline(),
        defaultAyahRepeatCount: 1,
        defaultRangeRepeatCount: 1,
        surahAyahCount: (surah) => surah == 2 ? 286 : 200,
      );
      expect(result.state.surah, 2);
      expect(result.state.rangeFrom, state.rangeFrom);
      expect(result.state.rangeTo, state.rangeTo);
      expect(result.state.segmentStartAyah, 3);
      expect(result.state.segmentEndAyah, 286);
      expect(result.effects.whereType<LoadRange>(), hasLength(1));
      expect(result.effects.whereType<LoadSurah>(), isEmpty);
    });

    test('PlaySurah clears stale segment fields with the range', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        rangeFrom: AyahReference(surah: 1, ayah: 2),
        rangeTo: AyahReference(surah: 1, ayah: 5),
        segmentStartAyah: 2,
        segmentEndAyah: 5,
        active: true,
      );
      final result = _run(
        state,
        const PlaySurah(reciter: _reciter, moshaf: _moshaf, surah: 2),
      );
      expect(result.state.rangeFrom, isNull);
      expect(result.state.rangeTo, isNull);
      expect(result.state.segmentStartAyah, isNull);
      expect(result.state.segmentEndAyah, isNull);
    });
  });

  group('Preset-to-intent mapping', () {
    test('thisSurah produces PlayWholeSurahIntent', () {
      final result = playbackIntentForPreset(
        preset: RangeScopePreset.thisSurah,
        reciter: _reciter,
        moshaf: _moshaf,
        from: const AyahReference(surah: 8, ayah: 1),
        to: const AyahReference(surah: 8, ayah: 75),
        mushafReader: _intentMushaf,
      );
      expect(result, isA<PlayWholeSurahIntent>());
    });

    test(
      'continueFromHere from ayah 1 produces open-ended PlayAyahRangeIntent',
      () {
        final result =
            playbackIntentForPreset(
                  preset: RangeScopePreset.continueFromHere,
                  reciter: _reciter,
                  moshaf: _moshaf,
                  from: const AyahReference(surah: 8, ayah: 1),
                  mushafReader: _intentMushaf,
                )
                as PlayAyahRangeIntent;
        expect(result.from, const AyahReference(surah: 8, ayah: 1));
        expect(result.to, isNull);
      },
    );

    test('continueFromHere from ayah > 1 produces PlayAyahRangeIntent', () {
      final result =
          playbackIntentForPreset(
                preset: RangeScopePreset.continueFromHere,
                reciter: _reciter,
                moshaf: _moshaf,
                from: const AyahReference(surah: 8, ayah: 5),
                mushafReader: _intentMushaf,
              )
              as PlayAyahRangeIntent;
      expect(result.from, const AyahReference(surah: 8, ayah: 5));
      expect(result.to, isNull);
    });

    test('thisAyah bounded preset produces PlayAyahRangeIntent', () {
      final result = playbackIntentForPreset(
        preset: RangeScopePreset.thisAyah,
        reciter: _reciter,
        moshaf: _moshaf,
        from: const AyahReference(surah: 8, ayah: 41),
        to: const AyahReference(surah: 8, ayah: 41),
        mushafReader: _intentMushaf,
      );
      expect(result, isA<PlayAyahRangeIntent>());
    });

    test('custom preset produces PlayAyahRangeIntent', () {
      final result = playbackIntentForPreset(
        preset: RangeScopePreset.custom,
        reciter: _reciter,
        moshaf: _moshaf,
        from: const AyahReference(surah: 8, ayah: 41),
        to: const AyahReference(surah: 8, ayah: 50),
        mushafReader: _intentMushaf,
      );
      expect(result, isA<PlayAyahRangeIntent>());
    });

    test(
      'custom full-surah endpoints same surah produce PlayWholeSurahIntent',
      () {
        final result = playbackIntentForPreset(
          preset: RangeScopePreset.custom,
          reciter: _reciter,
          moshaf: _moshaf,
          from: const AyahReference(surah: 8, ayah: 1),
          to: const AyahReference(surah: 8, ayah: 75),
          mushafReader: _intentMushaf,
        );
        expect(result, isA<PlayWholeSurahIntent>());
      },
    );

    test('custom cross-surah full endpoints produce PlayAyahRangeIntent', () {
      final result = playbackIntentForPreset(
        preset: RangeScopePreset.custom,
        reciter: _reciter,
        moshaf: _moshaf,
        from: const AyahReference(surah: 8, ayah: 1),
        to: const AyahReference(surah: 9, ayah: 129),
        mushafReader: _intentMushaf,
      );
      expect(result, isA<PlayAyahRangeIntent>());
    });
  });

  group('Multi-surah range advancement', () {
    test('AudioCompleted advances bounded cross-surah range', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 8,
        rangeFrom: AyahReference(surah: 8, ayah: 1),
        rangeTo: AyahReference(surah: 9, ayah: 129),
        segmentStartAyah: 1,
        segmentEndAyah: 75,
        active: true,
      );
      final result = _run(state, const AudioCompleted());
      expect(result.state.isLoading, isTrue);
      expect(result.effects.whereType<LoadNextRangeSegment>(), hasLength(1));
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

    test('SetRepeatCounts updates budgets and refreshes native loops', () {
      const state = RecitationState(
        status: RecitationStatus.playing,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        currentAyah: 2,
        active: true,
      );
      final result = _run(
        state,
        const SetRepeatCounts(rangeRepeatCount: 3, ayahRepeatCount: 2),
      );
      expect(result.state.repeatsRemaining, 3);
      expect(result.state.ayahRepeatsRemaining, 2);
      expect(result.state.ayahRepeatCount, 2);
      expect(
        result.effects.whereType<ResetNativePlaybackModes>(),
        hasLength(1),
      );
      expect(result.effects.whereType<SetNativeLoop>(), hasLength(1));
      expect(result.effects.whereType<LoadAyahLoop>(), hasLength(1));
      expect(result.effects.whereType<RefreshAbLoop>(), hasLength(1));
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

    test('RecitationSettingsLoaded restores saved playback position', () {
      const resume = Duration(seconds: 22);
      const state = RecitationState();
      final result = _run(
        state,
        const RecitationSettingsLoaded(
          reciter: _reciter,
          moshaf: _moshaf,
          surah: 2,
          resumeFrom: resume,
        ),
      );
      expect(result.state.position, resume);
      expect(result.state.isIdle, isTrue);
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

    test('AudioCompleted delegates to selection end (whole surah ends)', () {
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
      expect(result.state.isEnded, isTrue);
      expect(result.state.position, const Duration(milliseconds: 5000));
      expect(result.effects.whereType<PauseAtEof>(), hasLength(1));
      expect(result.effects.whereType<StopAudio>(), isEmpty);
      expect(result.effects.whereType<ClearPlaybackPosition>(), isEmpty);
    });

    test('AudioCompleted with repeats remaining uses native file loop', () {
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
      expect(result.state.isPlaying, isTrue);
      expect(result.effects, isEmpty);
    });

    test(
      'duplicate AudioCompleted on same EOF ends early with repeats left',
      () {
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
        final once = _run(state, const AudioCompleted(), timeline: timeline);
        expect(once.state.repeatsRemaining, 1);
        expect(once.state.isPlaying, isTrue);
        expect(once.effects, isEmpty);

        // Mirrors completionStream + PlaybackCompleted firing on the same EOF.
        final twice = _run(
          once.state,
          const AudioCompleted(),
          timeline: timeline,
        );
        expect(twice.state.repeatsRemaining, 1);
        expect(twice.state.isEnded, isTrue);
        expect(twice.effects.whereType<PauseAtEof>(), hasLength(1));
      },
    );

    test('TogglePlayPause when ended replays whole surah', () {
      const state = RecitationState(
        status: RecitationStatus.ended,
        reciter: _reciter,
        moshaf: _moshaf,
        surah: 1,
        active: true,
        ayahRepeatCount: 2,
        repeatsRemaining: 2,
      );
      final result = _run(state, const TogglePlayPause());
      expect(result.state.isLoading, isTrue);
      expect(result.effects.whereType<LoadSurah>(), hasLength(1));
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

class _IntentMushafRepo implements IQuranRepository {
  static final _surahs = <int, Surah>{
    8: Surah(number: 8, glyph: 'S8', hasBasmalah: true, ayahCount: 75),
    9: Surah(number: 9, glyph: 'S9', hasBasmalah: false, ayahCount: 129),
  };

  @override
  void dispose() {}

  @override
  Future<void> ensureReady() async {}

  @override
  Future<List<Surah>> getAllSurahs() async => _surahs.values.toList();

  @override
  Future<Ayah> getAyah(int ayahId, [bool removeNewLines = true]) =>
      throw UnimplementedError();

  @override
  Future<Ayah> getAyahBySurah(
    int surah,
    int ayahInSurah, [
    bool removeNewLines = true,
  ]) => throw UnimplementedError();

  @override
  Future<String> getBasmalah() async => '';

  @override
  String? getBasmalahSync() => null;

  @override
  Future<Juz> getJuz(int number) => throw UnimplementedError();

  @override
  Future<List<Juz>> getJuzs() async => [];

  @override
  Map<int, Juz> getJuzsSync() => {};

  @override
  Future<int> getJuzStartPage(int juzNumber) async => 1;

  @override
  Juz? getJuzSync(int number) => null;

  @override
  ({int startAyahId, int endAyahId})? juzAyahBounds(int juzNumber) => null;

  @override
  Future<Hizb> getHizb(int number) => throw UnimplementedError();

  @override
  Future<List<Hizb>> getHizbs() async => [];

  @override
  Map<int, Hizb> getHizbsSync() => {};

  @override
  Future<int> getHizbStartPage(int hizbNumber) async => 1;

  @override
  Hizb? getHizbSync(int number) => null;

  @override
  ({int startAyahId, int endAyahId})? hizbAyahBounds(int hizbNumber) => null;

  @override
  Future<QuranPage> getPage(int page) async {
    return QuranPage(
      pageNumber: page,
      glyphText: '',
      lines: const [],
      surahs: const [],
      juzNumber: 1,
    );
  }

  @override
  QuranPage? peekCachedPage(int page) => null;

  @override
  Future<int> getPageForAyah(int ayahId) async => 1;

  @override
  Future<int> getStartPageForSurah(int surahNumber) async => 1;

  @override
  Future<Surah?> getSurah(int surahNumber) async => _surahs[surahNumber];

  @override
  List<Surah> getSurahsSync() => _surahs.values.toList();

  @override
  Surah? getSurahSync(int number) => _surahs[number];

  @override
  Future<List<Ayah>> searchAyahs(
    String query, {
    int? surahNumber,
    int maxResults = 100,
  }) async => [];

  @override
  Future<void> warmUpSearchIndex() async {}
}
