import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/feature/quran/domain/models/ayah_reference.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_sleep.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_state.dart';
import 'package:tawaq/feature/quran/domain/models/reciter.dart';

void main() {
  group('RecitationState', () {
    const reciter = Reciter(id: 1, name: 'Test', moshaf: []);
    const moshaf = Moshaf(
      id: 1,
      name: 'Hafs',
      server: '',
      surahList: [],
      surahTotal: 114,
    );

    test('default state is idle and inactive', () {
      const state = RecitationState();
      expect(state.isIdle, isTrue);
      expect(state.active, isFalse);
      expect(state.isRange, isFalse);
      expect(state.isWholeSurah, isFalse);
    });

    test('whole surah state', () {
      const state = RecitationState(
        reciter: reciter,
        moshaf: moshaf,
        surah: 2,
        status: RecitationStatus.playing,
        active: true,
      );
      expect(state.isWholeSurah, isTrue);
      expect(state.isRange, isFalse);
      expect(state.isCrossSurahRange, isFalse);
    });

    test('range within surah', () {
      const state = RecitationState(
        surah: 2,
        rangeFrom: AyahReference(surah: 2, ayah: 3),
        rangeTo: AyahReference(surah: 2, ayah: 5),
        status: RecitationStatus.playing,
        active: true,
      );
      expect(state.isRange, isTrue);
      expect(state.isWholeSurah, isFalse);
      expect(state.isCrossSurahRange, isFalse);
    });

    test('cross-surah range', () {
      const state = RecitationState(
        surah: 2,
        rangeFrom: AyahReference(surah: 2, ayah: 250),
        rangeTo: AyahReference(surah: 3, ayah: 5),
        status: RecitationStatus.playing,
        active: true,
      );
      expect(state.isRange, isTrue);
      expect(state.isCrossSurahRange, isTrue);
    });

    test('status helpers', () {
      const loading = RecitationState(status: RecitationStatus.loading);
      const playing = RecitationState(status: RecitationStatus.playing);
      const paused = RecitationState(status: RecitationStatus.paused);
      const error = RecitationState(status: RecitationStatus.error);

      expect(loading.isLoading, isTrue);
      expect(playing.isPlaying, isTrue);
      expect(paused.isPaused, isTrue);
      expect(error.isError, isTrue);
    });

    test('copyWith preserves immutability', () {
      const state = RecitationState(surah: 2, currentAyah: 5);
      final next = state.copyWith(
        currentAyah: 6,
        position: const Duration(seconds: 10),
      );
      expect(state.currentAyah, 5);
      expect(next.currentAyah, 6);
      expect(next.position, const Duration(seconds: 10));
    });

    test('sleep defaults to off', () {
      const state = RecitationState();
      expect(state.sleep, RecitationSleep.off);
    });
  });
}
