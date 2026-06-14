import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/core/audio/audio_track.dart';
import 'package:tawaq/core/audio/playback_queue.dart';
import 'package:tawaq/core/audio/playback_state.dart';
import 'package:tawaq/gen/assets.gen.dart';

AudioTrack _track(String id) => AudioTrack.asset(
  id: id,
  title: id,
  assetPath: Assets.audio.adhan.misharyAlafasi,
);

void main() {
  group('PlaybackQueue', () {
    test('next respects off repeat mode', () {
      final queue = PlaybackQueue(
        tracks: [_track('a'), _track('b')],
        currentIndex: 1,
      );
      expect(queue.next(), isNull);
    });

    test('next wraps with all repeat mode', () {
      final queue = PlaybackQueue(
        tracks: [_track('a'), _track('b')],
        currentIndex: 1,
        repeatMode: PlaybackRepeatMode.all,
      );
      expect(queue.next()?.currentIndex, 0);
    });

    test('previous returns null at start when repeat off', () {
      final queue = PlaybackQueue(
        tracks: [_track('a'), _track('b')],
      );
      expect(queue.previous(), isNull);
    });

    test('currentTrack returns active item', () {
      final queue = PlaybackQueue(
        tracks: [_track('a'), _track('b')],
        currentIndex: 1,
      );
      expect(queue.currentTrack?.id, 'b');
    });
  });
}
