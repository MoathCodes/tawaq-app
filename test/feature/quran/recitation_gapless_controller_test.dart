import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/core/audio/audio_lease.dart';
import 'package:tawaq/core/audio/audio_service.dart';
import 'package:tawaq/core/audio/audio_track.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_state.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_timeline.dart';

class _MockTawaqAudioService extends Mock implements TawaqAudioService {}

void main() {
  group('gapless continuation playlist index', () {
    test('post-EOF continuation opens playlist at index 1', () async {
      final service = _MockTawaqAudioService();
      final current = AudioTrack.network(
        id: 'recitation-1-1',
        title: 'Surah 1',
        url: 'file:///surah1.mp3',
      );
      final next = AudioTrack.network(
        id: 'recitation-1-2',
        title: 'Surah 2',
        url: 'file:///surah2.mp3',
      );

      when(
        () => service.openAll(
          any(),
          index: any(named: 'index'),
          owner: any(named: 'owner'),
        ),
      ).thenAnswer((_) async {});

      const state = RecitationState(surah: 2, active: true);
      final bookkeeping = gaplessContinuationBookkeeping(
        nextUri: next.uri,
        stateForTimeline: state,
      );

      await service.openAll(
        [current, next],
        index: bookkeeping.openAtIndex,
        owner: kRecitationLeaseOwner,
      );

      verify(
        () => service.openAll(
          [current, next],
          index: 1,
          owner: kRecitationLeaseOwner,
        ),
      ).called(1);
      expect(bookkeeping.openAtIndex, 1);
      expect(bookkeeping.seededTrackIndex, 0);
    });

    test('sets lastResolvedUri, timeline, and GaplessTrackAdvanced', () {
      const nextUri = 'file:///surah2.mp3';
      const timing = SurahTiming(
        surah: 2,
        readId: 1,
        ayat: [
          AyahTiming(ayah: 1, startMs: 0, endMs: 4000),
          AyahTiming(ayah: 2, startMs: 4000, endMs: 8000),
        ],
      );
      const state = RecitationState(surah: 2, active: true);

      final result = gaplessContinuationBookkeeping(
        nextUri: nextUri,
        nextTiming: timing,
        stateForTimeline: state,
      );

      expect(result.lastResolvedUri, nextUri);
      expect(result.openAtIndex, 1);
      expect(result.seededTrackIndex, 0);
      // Simulate openAll leaving the seeded index (no currentIndex tick).
      expect(
        shouldExplicitGaplessAdvance(
          trackIndexAfterOpen: result.seededTrackIndex,
          seededTrackIndex: result.seededTrackIndex,
        ),
        isTrue,
      );
      expect(result.timeline.startOfAyah(1), Duration.zero);
      expect(
        result.timeline.endOfAyah(2),
        const Duration(milliseconds: 8000),
      );
    });
  });
}
