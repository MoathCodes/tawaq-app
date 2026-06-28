import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_timeline.dart';

void main() {
  group('RecitationTimeline', () {
    const timing = SurahTiming(
      surah: 1,
      readId: 1,
      ayat: [
        AyahTiming(ayah: 1, startMs: 0, endMs: 5000),
        AyahTiming(ayah: 2, startMs: 5000, endMs: 12000),
        AyahTiming(ayah: 3, startMs: 12000, endMs: 20000),
      ],
    );

    test('hasTiming is false when timing is null', () {
      const timeline = RecitationTimeline();
      expect(timeline.hasTiming, isFalse);
    });

    test('totalDuration comes from timing totalMs', () {
      const timeline = RecitationTimeline(timing: timing);
      expect(timeline.totalDuration, const Duration(milliseconds: 20000));
    });

    test('ayahAt returns correct ayah for a position', () {
      const timeline = RecitationTimeline(timing: timing);
      expect(timeline.ayahAt(const Duration(milliseconds: 1000)), 1);
      expect(timeline.ayahAt(const Duration(milliseconds: 7000)), 2);
      expect(timeline.ayahAt(const Duration(milliseconds: 15000)), 3);
    });

    test('ayahAt returns null without timing', () {
      const timeline = RecitationTimeline();
      expect(timeline.ayahAt(const Duration(milliseconds: 1000)), isNull);
    });

    test('startOfAyah and endOfAyah return segment bounds', () {
      const timeline = RecitationTimeline(timing: timing);
      expect(timeline.startOfAyah(2), const Duration(milliseconds: 5000));
      expect(timeline.endOfAyah(2), const Duration(milliseconds: 12000));
    });

    test('rangeStart and rangeEnd use range markers when set', () {
      const timeline = RecitationTimeline(
        timing: timing,
        rangeStartAyah: 2,
        rangeEndAyah: 3,
      );
      expect(timeline.rangeStart, const Duration(milliseconds: 5000));
      expect(timeline.rangeEnd, const Duration(milliseconds: 20000));
    });

    test('clampToRange clamps inside range', () {
      const timeline = RecitationTimeline(
        timing: timing,
        rangeStartAyah: 2,
        rangeEndAyah: 3,
      );
      expect(
        timeline.clampToRange(const Duration(milliseconds: 1000)),
        const Duration(milliseconds: 5000),
      );
      expect(
        timeline.clampToRange(const Duration(milliseconds: 25000)),
        const Duration(milliseconds: 20000),
      );
      expect(
        timeline.clampToRange(const Duration(milliseconds: 7000)),
        const Duration(milliseconds: 7000),
      );
    });

    test('snapToNearestAyah snaps to closest ayah start', () {
      const timeline = RecitationTimeline(timing: timing);
      expect(
        timeline.snapToNearestAyah(const Duration(milliseconds: 1000)),
        const Duration(),
      );
      expect(
        timeline.snapToNearestAyah(const Duration(milliseconds: 7000)),
        const Duration(milliseconds: 5000),
      );
      expect(
        timeline.snapToNearestAyah(const Duration(milliseconds: 9000)),
        const Duration(milliseconds: 12000),
      );
      expect(
        timeline.snapToNearestAyah(const Duration(milliseconds: 11900)),
        const Duration(milliseconds: 12000),
      );
    });

    test('snapToNearestAyah returns original position without timing', () {
      const timeline = RecitationTimeline();
      const pos = Duration(milliseconds: 5000);
      expect(timeline.snapToNearestAyah(pos), pos);
    });

    test('nextAyahAtOrAfter finds next playable ayah', () {
      const timeline = RecitationTimeline(timing: timing);
      expect(
        timeline.nextAyahAtOrAfter(const Duration(milliseconds: 1000)),
        2,
      );
      expect(
        timeline.nextAyahAtOrAfter(const Duration(milliseconds: 5001)),
        3,
      );
      expect(
        timeline.nextAyahAtOrAfter(const Duration(milliseconds: 20000)),
        3,
      );
    });
  });
}
