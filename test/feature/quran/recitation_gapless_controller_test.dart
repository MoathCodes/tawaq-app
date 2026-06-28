import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tawaq/core/audio/audio_lease.dart';
import 'package:tawaq/core/audio/audio_service.dart';
import 'package:tawaq/core/audio/audio_track.dart';

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

      // Mirrors RecitationController._openGaplessContinuation after surah end.
      await service.openAll(
        [current, next],
        index: 1,
        owner: kRecitationLeaseOwner,
      );

      verify(
        () => service.openAll(
          [current, next],
          index: 1,
          owner: kRecitationLeaseOwner,
        ),
      ).called(1);
    });
  });
}
