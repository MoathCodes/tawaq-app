import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_settings.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_url_builder.dart';
import 'package:tawaq/feature/quran/domain/services/reciter_tags.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';

void main() {
  group('surahAudioUrl', () {
    test('zero-pads the surah to three digits', () {
      expect(
        surahAudioUrl('https://server6.mp3quran.net/akdr/', 1),
        'https://server6.mp3quran.net/akdr/001.mp3',
      );
      expect(
        surahAudioUrl('https://server6.mp3quran.net/akdr/', 114),
        'https://server6.mp3quran.net/akdr/114.mp3',
      );
    });

    test('tolerates a server without a trailing slash', () {
      expect(
        surahAudioUrl('https://x.net/akdr', 12),
        'https://x.net/akdr/012.mp3',
      );
    });
  });

  group('SurahTiming', () {
    const timing = SurahTiming(
      surah: 1,
      readId: 1,
      ayat: [
        AyahTiming(ayah: 0, startMs: 0, endMs: 8200),
        AyahTiming(ayah: 1, startMs: 8200, endMs: 13960),
        AyahTiming(ayah: 2, startMs: 13960, endMs: 19240),
      ],
    );

    test('forAyah returns the matching entry', () {
      expect(timing.forAyah(2)?.startMs, 13960);
      expect(timing.forAyah(9), isNull);
    });

    test('ayahAt resolves a position to the containing ayah', () {
      expect(timing.ayahAt(8200), 1); // inclusive start
      expect(timing.ayahAt(13959), 1); // exclusive end
      expect(timing.ayahAt(13960), 2); // next ayah start
    });

    test('ayahAt ignores the ayah-0 intro window', () {
      expect(timing.ayahAt(100), isNull);
    });

    test('firstAyah skips the ayah-0 intro', () {
      expect(timing.firstAyah, 1);
    });

    test('totalMs is the largest ayah endMs (ignoring the intro)', () {
      expect(timing.totalMs, 19240);
      expect(const SurahTiming(surah: 1, readId: 1, ayat: []).totalMs, 0);
    });
  });

  group('moshafTags', () {
    test('parses style from the moshaf name', () {
      expect(moshafTags('حفص عن عاصم - مرتل').style, RecitationStyle.murattal);
      expect(
        moshafTags('المصحف المجود - حفص').style,
        RecitationStyle.mujawwad,
      );
      expect(moshafTags('حفص عن عاصم').style, isNull);
    });

    test('parses the canonical riwayah', () {
      expect(moshafTags('حفص عن عاصم - مرتل').riwayah, 'حفص');
      expect(moshafTags('ورش عن نافع').riwayah, 'ورش');
      expect(moshafTags('الدوري عن أبي عمرو').riwayah, 'الدوري');
      expect(moshafTags('قالون عن نافع').riwayah, 'قالون');
    });

    test('returns null tags for an unrecognized name', () {
      final tags = moshafTags('تلاوة خاصة');
      expect(tags.style, isNull);
      expect(tags.riwayah, isNull);
    });
  });

  group('isHafsRiwayah', () {
    test('returns true for Hafs moshaf names', () {
      expect(isHafsRiwayah('حفص عن عاصم - مرتل'), isTrue);
      expect(isHafsRiwayah('المصحف المجود - حفص'), isTrue);
    });

    test('returns false for other recognized riwayat', () {
      expect(isHafsRiwayah('ورش عن نافع'), isFalse);
      expect(isHafsRiwayah('قالون عن نافع'), isFalse);
    });

    test('returns false for unrecognized names', () {
      expect(isHafsRiwayah('تلاوة خاصة'), isFalse);
    });
  });

  group('setReciter highlight auto-disable', () {
    test('disables highlightAyah for non-Hafs moshaf', () {
      final container = ProviderContainer(
        overrides: [
          recitationSettingsProvider.overrideWith(
            _TestRecitationSettingsNotifier.new,
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(recitationSettingsProvider.notifier);
      notifier.setHighlightAyah(value: true);
      final autoHighlight = notifier.setReciter(
        reciterId: 1,
        moshafId: 2,
        moshafName: 'ورش عن نافع',
      );

      final settings = container.read(recitationSettingsProvider).value;
      expect(settings?.reciterId, 1);
      expect(settings?.moshafId, 2);
      expect(settings?.highlightAyah, isFalse);
      expect(autoHighlight, isFalse);
    });

    test('re-enables highlightAyah when switching from non-Hafs to Hafs', () {
      final container = ProviderContainer(
        overrides: [
          recitationSettingsProvider.overrideWith(
            _TestRecitationSettingsNotifier.new,
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(recitationSettingsProvider.notifier);
      notifier.setReciter(
        reciterId: 1,
        moshafId: 2,
        moshafName: 'ورش عن نافع',
      );
      expect(
        container.read(recitationSettingsProvider).value?.highlightAyah,
        isFalse,
      );

      final autoHighlight = notifier.setReciter(
        reciterId: 3,
        moshafId: 4,
        moshafName: 'حفص عن عاصم - مرتل',
      );
      expect(
        container.read(recitationSettingsProvider).value?.highlightAyah,
        isTrue,
      );
      expect(autoHighlight, isTrue);
    });

    test('enables highlightAyah for Hafs moshaf', () {
      final container = ProviderContainer(
        overrides: [
          recitationSettingsProvider.overrideWith(
            _TestRecitationSettingsNotifier.new,
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(recitationSettingsProvider.notifier);
      notifier.setHighlightAyah(value: false);
      final autoHighlight = notifier.setReciter(
        reciterId: 1,
        moshafId: 2,
        moshafName: 'حفص عن عاصم - مرتل',
      );

      expect(
        container.read(recitationSettingsProvider).value?.highlightAyah,
        isTrue,
      );
      expect(autoHighlight, isTrue);
    });

    test('leaves highlightAyah unchanged for unrecognized moshaf name', () {
      final container = ProviderContainer(
        overrides: [
          recitationSettingsProvider.overrideWith(
            _TestRecitationSettingsNotifier.new,
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(recitationSettingsProvider.notifier);
      notifier.setHighlightAyah(value: true);
      final autoHighlight = notifier.setReciter(
        reciterId: 1,
        moshafId: 2,
        moshafName: 'تلاوة خاصة',
      );

      expect(
        container.read(recitationSettingsProvider).value?.highlightAyah,
        isTrue,
      );
      expect(autoHighlight, isNull);
    });
  });
}

class _TestRecitationSettingsNotifier extends RecitationSettingsNotifier {
  @override
  Future<RecitationSettings> build() async {
    state = const AsyncData(RecitationSettings());
    return const RecitationSettings();
  }
}
