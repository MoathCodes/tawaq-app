import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/quran/domain/models/quran_screen_state.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_settings.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_state.dart';
import 'package:tawaq/feature/quran/domain/models/reciter.dart';
import 'package:tawaq/feature/quran/domain/services/recitation_timeline.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_route_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_provider.dart';

const _untimedMoshaf = Moshaf(
  id: 1,
  name: 'untimed',
  server: 'https://example.com/x/',
  surahList: [1, 2, 114],
  surahTotal: 114,
);

const _timedMoshaf = Moshaf(
  id: 2,
  name: 'timed',
  server: 'https://example.com/x/',
  surahList: [1, 2, 114],
  surahTotal: 114,
  timingReadId: 1,
);

const _surah1Timing = SurahTiming(
  surah: 1,
  readId: 1,
  ayat: [
    AyahTiming(ayah: 1, startMs: 0, endMs: 5000),
    AyahTiming(ayah: 2, startMs: 5000, endMs: 12000),
    AyahTiming(ayah: 3, startMs: 12000, endMs: 20000),
  ],
);

void main() {
  group('goToPlaybackInMushaf', () {
    testWidgets('untimed reciter jumps to surah start and clears selection',
        (tester) async {
      final repo = _GoToRepo();
      final harness = await _pumpHarness(
        tester,
        repo: repo,
        playback: const RecitationState(
          surah: 2,
          moshaf: _untimedMoshaf,
          active: true,
        ),
      );

      await harness.notifier.goToPlaybackInMushaf(harness.context);
      await tester.pumpAndSettle();

      expect(repo.lastSurahJump, 2);
      expect(repo.lastAyahPageLookup, isNull);
      expect(harness.mushaf.currentPage, 20);
      expect(harness.mushaf.selectedAyahId, isNull);
    });

    testWidgets(
      'timed reciter highlights current ayah even when highlight setting is off',
      (tester) async {
        final repo = _GoToRepo();
        final harness = await _pumpHarness(
          tester,
          repo: repo,
          playback: const RecitationState(
            surah: 2,
            moshaf: _timedMoshaf,
            currentAyah: 5,
            active: true,
          ),
          settings: RecitationSettings.initial().copyWith(highlightAyah: false),
        );

        await harness.notifier.goToPlaybackInMushaf(harness.context);
        await tester.pumpAndSettle();

        expect(repo.lastSurahJump, isNull);
        expect(repo.lastAyahPageLookup, 2005);
        expect(harness.mushaf.currentPage, 50);
        expect(harness.mushaf.selectedAyahId, 2005);
      },
    );

    testWidgets(
      'timed reciter resolves ayah from position when currentAyah is null',
      (tester) async {
        final repo = _GoToRepo();
        final harness = await _pumpHarness(
          tester,
          repo: repo,
          playback: const RecitationState(
            surah: 1,
            moshaf: _timedMoshaf,
            position: Duration(milliseconds: 7000),
            active: true,
          ),
          timeline: const RecitationTimeline(timing: _surah1Timing),
        );

        await harness.notifier.goToPlaybackInMushaf(harness.context);
        await tester.pumpAndSettle();

        expect(repo.lastAyahPageLookup, 1002);
        expect(harness.mushaf.selectedAyahId, 1002);
      },
    );
  });
}

class _GoToHarness {
  _GoToHarness({
    required this.container,
    required this.context,
    required this.notifier,
    required this.mushaf,
  });

  final ProviderContainer container;
  final BuildContext context;
  final RecitationController notifier;
  final MushafReaderController mushaf;
}

Future<_GoToHarness> _pumpHarness(
  WidgetTester tester, {
  required _GoToRepo repo,
  required RecitationState playback,
  RecitationTimeline? timeline,
  RecitationSettings? settings,
}) async {
  final resolvedSettings = settings ?? RecitationSettings.initial();
  final pageController = PageController();
  final mushaf = MushafReaderController.withRepository(
    repository: repo,
    pageController: pageController,
  );

  late ProviderContainer container;
  late BuildContext context;
  late RecitationController notifier;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        quranMushafControllerProvider.overrideWithValue(mushaf),
        recitationControllerProvider.overrideWith(
          () => _FixedRecitationController(playback, timeline),
        ),
        quranRouteActiveProvider.overrideWith(_AlwaysQuranRoute.new),
        recitationSettingsProvider.overrideWith(
          () => _FixedRecitationSettings(resolvedSettings),
        ),
        quranScreenSettingsProvider.overrideWith(_SyncQuranScreenSettings.new),
      ],
      child: Builder(
        builder: (ctx) {
          container = ProviderScope.containerOf(ctx);
          context = ctx;
          notifier = container.read(recitationControllerProvider.notifier);
          return MaterialApp(
            home: PageView(
              controller: pageController,
              children: const [
                SizedBox.expand(),
                SizedBox.expand(),
              ],
            ),
          );
        },
      ),
    ),
  );
  await tester.pump();
  await container.read(quranScreenSettingsProvider.future);

  return _GoToHarness(
    container: container,
    context: context,
    notifier: notifier,
    mushaf: mushaf,
  );
}

class _FixedRecitationController extends RecitationController {
  _FixedRecitationController(this._initial, this._timeline);

  final RecitationState _initial;
  final RecitationTimeline? _timeline;

  @override
  RecitationState build() {
    if (_timeline != null) {
      timelineForTest = _timeline;
    }
    return _initial;
  }
}

class _FixedRecitationSettings extends RecitationSettingsNotifier {
  _FixedRecitationSettings(this._settings);

  final RecitationSettings _settings;

  @override
  Future<RecitationSettings> build() async {
    state = AsyncData(_settings);
    return _settings;
  }
}

class _SyncQuranScreenSettings extends QuranScreenSettingsNotifier {
  @override
  Future<QuranScreenState> build() async {
    state = AsyncData(QuranScreenState.initial());
    return QuranScreenState.initial();
  }

  @override
  void selectAyah(Ayah? ayah) {
    if (!state.hasValue) return;
    state = AsyncData(state.value!.copyWith(selectedAyah: ayah));
  }
}

class _AlwaysQuranRoute extends QuranRouteActive {
  @override
  bool build() => true;
}

class _GoToRepo implements IQuranRepository {
  int? lastSurahJump;
  int? lastAyahPageLookup;

  @override
  void dispose() {}

  @override
  Future<void> ensureReady() async {}

  @override
  Future<List<Surah>> getAllSurahs() async => [];

  @override
  Future<Ayah> getAyah(int ayahId, [bool removeNewLines = true]) async =>
      _ayahFromId(ayahId);

  @override
  Future<Ayah> getAyahBySurah(
    int surah,
    int ayahInSurah, [
    bool removeNewLines = true,
  ]) async =>
      Ayah(
        ayahId: surah * 1000 + ayahInSurah,
        juz: 1,
        page: 50,
        surahNumber: surah,
        numberInSurah: ayahInSurah,
        text: '',
        textPlain: '$surah:$ayahInSurah',
      );

  @override
  Future<String> getBasmalah() async => '';

  @override
  String? getBasmalahSync() => null;

  @override
  Future<Juz> getJuz(int number) async => throw UnimplementedError();

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
  Future<Hizb> getHizb(int number) async => throw UnimplementedError();

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
  Future<QuranPage> getPage(int page) async => QuranPage(
        pageNumber: page,
        glyphText: '',
        lines: const [],
        surahs: const [],
        juzNumber: 1,
      );

  @override
  QuranPage? peekCachedPage(int page) => null;

  @override
  Future<int> getPageForAyah(int ayahId) async {
    lastAyahPageLookup = ayahId;
    return 50;
  }

  @override
  Future<int> getStartPageForSurah(int surahNumber) async {
    lastSurahJump = surahNumber;
    return surahNumber * 10;
  }

  @override
  Future<Surah?> getSurah(int number) async => null;

  @override
  List<Surah> getSurahsSync() => [];

  @override
  Surah? getSurahSync(int number) => null;

  @override
  Future<List<Ayah>> searchAyahs(
    String query, {
    int? surahNumber,
    int maxResults = 100,
  }) async =>
      [];

  @override
  Future<void> warmUpSearchIndex() async {}

  @override
  bool isReady() => true;
}

Ayah _ayahFromId(int ayahId) {
  final surah = ayahId ~/ 1000;
  final ayahInSurah = ayahId % 1000;
  return Ayah(
    ayahId: ayahId,
    juz: 1,
    page: 50,
    surahNumber: surah,
    numberInSurah: ayahInSurah,
    text: '',
    textPlain: '$surah:$ayahInSurah',
  );
}
