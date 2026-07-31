import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_models.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_state.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_playback_policy.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_timeline.dart';

RecitationTimeline _timeline({List<AyahTiming>? ayat}) {
  return RecitationTimeline(
    timing: ayat == null
        ? null
        : SurahTiming(surah: 1, readId: 1, ayat: ayat),
    rangeStartAyah: 1,
    rangeEndAyah: 3,
  );
}

List<AyahTiming> get _ayat => const [
      AyahTiming(ayah: 1, startMs: 0, endMs: 1000),
      AyahTiming(ayah: 2, startMs: 1000, endMs: 2000),
      AyahTiming(ayah: 3, startMs: 2000, endMs: 3000),
    ];

void main() {
  group('recitation_playback_policy', () {
    test('positionNearTarget uses 500ms tolerance', () {
      const target = Duration(seconds: 5);
      expect(
        positionNearTarget(const Duration(milliseconds: 5500), target),
        isTrue,
      );
      expect(
        positionNearTarget(const Duration(milliseconds: 5501), target),
        isFalse,
      );
      expect(pendingSeekToleranceMs, 500);
      expect(pendingSeekTimeout, const Duration(seconds: 2));
    });

    test('isNearTrackEnd uses 500ms epsilon', () {
      const duration = Duration(seconds: 10);
      expect(
        isNearTrackEnd(const Duration(milliseconds: 9500), duration),
        isTrue,
      );
      expect(
        isNearTrackEnd(const Duration(milliseconds: 9499), duration),
        isFalse,
      );
      expect(isNearTrackEnd(Duration.zero, Duration.zero), isFalse);
    });

    test('clampRepeatCount bounds to 1..99', () {
      expect(clampRepeatCount(0), 1);
      expect(clampRepeatCount(50), 50);
      expect(clampRepeatCount(200), 99);
    });

    test('shouldUseNativeFileLoop requires whole surah and repeats', () {
      const whole = RecitationState(
        surah: 1,
        ayahRepeatCount: 1,
        repeatsRemaining: 3,
      );
      expect(eligibleForNativeFileLoop(whole), isTrue);
      expect(shouldUseNativeFileLoop(whole), isTrue);

      const eachAyah = RecitationState(
        surah: 1,
        ayahRepeatCount: 2,
        repeatsRemaining: 3,
      );
      expect(eligibleForNativeFileLoop(eachAyah), isFalse);
      expect(shouldUseNativeFileLoop(eachAyah), isFalse);

      final ranged = RecitationState(
        surah: 1,
        rangeFrom: const AyahReference(surah: 1, ayah: 1),
        rangeTo: const AyahReference(surah: 1, ayah: 3),
        segmentStartAyah: 1,
        segmentEndAyah: 3,
        ayahRepeatCount: 1,
        repeatsRemaining: 3,
      );
      expect(eligibleForNativeFileLoop(ranged), isFalse);
    });

    test('playable ayah bounds respect segment', () {
      final timeline = _timeline(ayat: _ayat);
      final state = RecitationState(
        currentAyah: 2,
        position: const Duration(milliseconds: 1500),
        segmentStartAyah: 1,
        segmentEndAyah: 3,
        rangeFrom: const AyahReference(surah: 1, ayah: 1),
        rangeTo: const AyahReference(surah: 1, ayah: 3),
      );
      expect(currentAyahOrGuess(state, timeline), 2);
      expect(firstPlayableAyah(state), 1);
      expect(lastPlayableAyah(state, timeline), 3);
      expect(
        hasNextAyahAfterLoop(
          state: state,
          timeline: timeline,
          currentAyah: 2,
        ),
        isTrue,
      );
      expect(
        hasNextAyahAfterLoop(
          state: state,
          timeline: timeline,
          currentAyah: 3,
        ),
        isFalse,
      );
    });

    test('isPastRangeEnd only for bounded ranges without ayah-repeat', () {
      final timeline = _timeline(ayat: _ayat);
      final range = RecitationState(
        rangeFrom: const AyahReference(surah: 1, ayah: 1),
        rangeTo: const AyahReference(surah: 1, ayah: 3),
        segmentStartAyah: 1,
        segmentEndAyah: 3,
        duration: const Duration(seconds: 3),
        ayahRepeatCount: 1,
      );
      expect(
        isPastRangeEnd(
          state: range,
          timeline: timeline,
          position: const Duration(milliseconds: 3000),
        ),
        isTrue,
      );
      expect(
        isPastRangeEnd(
          state: range.copyWith(ayahRepeatCount: 2),
          timeline: timeline,
          position: const Duration(milliseconds: 3000),
        ),
        isFalse,
      );
    });

    test('detectAyahLoopWrap requires near-end then near-start jump', () {
      final timeline = _timeline(ayat: _ayat);
      final state = RecitationState(
        currentAyah: 1,
        position: const Duration(milliseconds: 800),
        ayahRepeatCount: 3,
        ayahRepeatsRemaining: 3,
      );
      expect(
        detectAyahLoopWrap(
          state,
          const Duration(milliseconds: 50),
          timeline,
        ),
        isTrue,
      );
      expect(
        detectAyahLoopWrap(
          state.copyWith(position: const Duration(milliseconds: 200)),
          const Duration(milliseconds: 50),
          timeline,
        ),
        isFalse,
      );
    });

    test('sleepBoundary resolves content ends', () {
      final timeline = _timeline(ayat: _ayat);
      final state = RecitationState(
        currentAyah: 2,
        duration: const Duration(seconds: 3),
        sleep: RecitationSleep.endOfAyah,
      );
      expect(
        sleepBoundary(state, timeline: timeline),
        const Duration(milliseconds: 2000),
      );
      expect(
        sleepBoundary(
          state.copyWith(sleep: RecitationSleep.endOfSurah),
          timeline: timeline,
        ),
        const Duration(seconds: 3),
      );
      expect(
        sleepBoundary(
          state.copyWith(sleep: RecitationSleep.off),
          timeline: timeline,
        ),
        isNull,
      );
    });

    test('mergeReportedDuration keeps larger timing duration', () {
      expect(
        mergeReportedDuration(
          current: const Duration(minutes: 3),
          reported: const Duration(minutes: 2),
        ),
        const Duration(minutes: 3),
      );
      expect(
        mergeReportedDuration(
          current: Duration.zero,
          reported: const Duration(minutes: 2),
        ),
        const Duration(minutes: 2),
      );
    });
  });
}
