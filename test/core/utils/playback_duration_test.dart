import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/core/utils/playback_duration.dart';

void main() {
  group('formatPlaybackDuration', () {
    test('uses m:ss under one hour', () {
      expect(
        formatPlaybackDuration(const Duration(minutes: 7, seconds: 41)),
        '7:41',
      );
      expect(formatPlaybackDuration(const Duration(seconds: 7)), '0:07');
    });

    test('uses h:mm:ss at or above one hour', () {
      expect(
        formatPlaybackDuration(const Duration(hours: 1, minutes: 59, seconds: 41)),
        '1:59:41',
      );
      expect(
        formatPlaybackDuration(const Duration(minutes: 119, seconds: 41)),
        '1:59:41',
      );
      expect(
        formatPlaybackDuration(const Duration(hours: 2, seconds: 5)),
        '2:00:05',
      );
    });
  });
}
