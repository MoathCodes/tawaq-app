import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hivez_flutter/hivez_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/core/audio/audio_player_provider.dart';
import 'package:tawaq/core/audio/audio_service.dart';
import 'package:tawaq/core/locale/locale_provider.dart';
import 'package:tawaq/core/widgets/dialog_shell.dart';
import 'package:tawaq/feature/quran/data/sources/recitation_cache.dart';
import 'package:tawaq/feature/quran/domain/models/quran_screen_state.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_settings.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_state.dart';
import 'package:tawaq/feature/quran/domain/models/reciter.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/recitation_drawer.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/recitation_transport.dart';
import 'package:tawaq/hive/hive_registrar.g.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

/// Minimal theme wrapper so the drawer surface renders without a full
/// ProviderScope. The animation tests only need widget geometry, not the
/// Riverpod-backed panel content.
Widget _wrap(Widget child, {TextDirection dir = TextDirection.ltr}) {
  final theme = buildAppTheme(
    palette: AppPalette.neutral,
    themeMode: ThemeMode.light,
    touch: false,
    textScale: 1,
  );
  return FTheme(
    data: theme,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Directionality(
          textDirection: dir,
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    registerFallbackValue(const Media('asset:///fallback'));
    registerFallbackValue(Duration.zero);
    registerFallbackValue(0.0);
    registerFallbackValue(const MediaSession());
    registerFallbackValue('');

    Hive
      ..init('./test/hive_test_db')
      ..registerAdapters();
  });

  group('skip-control RTL helpers', () {
    test('LTR: left slot is previous (skipBack + skipPrevious)', () {
      final left = leftSkipControl(
        isRtl: false,
        skipPrevious: () async {},
        skipNext: () async {},
        previousLabel: 'Previous',
        nextLabel: 'Next',
      );
      expect(left.icon, FLucideIcons.skipBack);
      expect(left.label, 'Previous');
    });

    test('LTR: right slot is next (skipForward + skipNext)', () {
      final right = rightSkipControl(
        isRtl: false,
        skipPrevious: () async {},
        skipNext: () async {},
        previousLabel: 'Previous',
        nextLabel: 'Next',
      );
      expect(right.icon, FLucideIcons.skipForward);
      expect(right.label, 'Next');
    });

    test('RTL: left slot is next action with left-pointing icon', () {
      final left = leftSkipControl(
        isRtl: true,
        skipPrevious: () async {},
        skipNext: () async {},
        previousLabel: 'Previous',
        nextLabel: 'Next',
      );
      expect(left.icon, FLucideIcons.skipBack);
      expect(left.label, 'Next');
    });

    test('RTL: right slot is previous action with right-pointing icon', () {
      final right = rightSkipControl(
        isRtl: true,
        skipPrevious: () async {},
        skipNext: () async {},
        previousLabel: 'Previous',
        nextLabel: 'Next',
      );
      expect(right.icon, FLucideIcons.skipForward);
      expect(right.label, 'Previous');
    });

    test('custom icons: ayah uses arrows by side', () {
      final left = leftSkipControl(
        isRtl: false,
        skipPrevious: () async {},
        skipNext: () async {},
        previousLabel: 'Previous ayah',
        nextLabel: 'Next ayah',
        icon: FLucideIcons.arrowLeft,
      );
      final right = rightSkipControl(
        isRtl: false,
        skipPrevious: () async {},
        skipNext: () async {},
        previousLabel: 'Previous ayah',
        nextLabel: 'Next ayah',
        icon: FLucideIcons.arrowRight,
      );
      expect(left.icon, FLucideIcons.arrowLeft);
      expect(right.icon, FLucideIcons.arrowRight);
    });

    test('RTL: icons stay side-pointing while actions mirror', () {
      final left = leftSkipControl(
        isRtl: true,
        skipPrevious: () async {},
        skipNext: () async {},
        previousLabel: 'Previous ayah',
        nextLabel: 'Next ayah',
        icon: FLucideIcons.arrowLeft,
      );
      final right = rightSkipControl(
        isRtl: true,
        skipPrevious: () async {},
        skipNext: () async {},
        previousLabel: 'Previous ayah',
        nextLabel: 'Next ayah',
        icon: FLucideIcons.arrowRight,
      );
      expect(left.icon, FLucideIcons.arrowLeft);
      expect(left.label, 'Next ayah');
      expect(right.icon, FLucideIcons.arrowRight);
      expect(right.label, 'Previous ayah');
    });

    test('LTR left + right slots dispatch to distinct actions', () {
      var previousCalls = 0;
      var nextCalls = 0;
      final left = leftSkipControl(
        isRtl: false,
        skipPrevious: () async => previousCalls++,
        skipNext: () async => nextCalls++,
        previousLabel: 'Previous',
        nextLabel: 'Next',
      );
      final right = rightSkipControl(
        isRtl: false,
        skipPrevious: () async => previousCalls++,
        skipNext: () async => nextCalls++,
        previousLabel: 'Previous',
        nextLabel: 'Next',
      );
      unawaited(left.onPress());
      unawaited(right.onPress());
      expect(previousCalls, 1);
      expect(nextCalls, 1);
    });

    test('RTL left + right slots dispatch to distinct actions (mirrored)', () {
      var previousCalls = 0;
      var nextCalls = 0;
      final left = leftSkipControl(
        isRtl: true,
        skipPrevious: () async => previousCalls++,
        skipNext: () async => nextCalls++,
        previousLabel: 'Previous',
        nextLabel: 'Next',
      );
      final right = rightSkipControl(
        isRtl: true,
        skipPrevious: () async => previousCalls++,
        skipNext: () async => nextCalls++,
        previousLabel: 'Previous',
        nextLabel: 'Next',
      );
      // In RTL the left slot is "next", the right slot is "previous".
      unawaited(left.onPress());
      unawaited(right.onPress());
      expect(nextCalls, 1);
      expect(previousCalls, 1);
    });
  });

  group('RecitationDrawerSurface animation', () {
    testWidgets('runs forward (0 -> 1) when opened', (tester) async {
      await tester.pumpWidget(
        _wrap(
          RecitationDrawerSurface(
            open: false,
            onClose: () {},
            child: const SizedBox(height: 100, width: 100),
          ),
        ),
      );
      await tester.pump();

      // Closed initially: controller at 0, no panel in tree.
      final stateClosed = tester
          .state<RecitationDrawerSurfaceState>(find.byType(
        RecitationDrawerSurface,
      ));
      expect(stateClosed.controller.value, 0);
      expect(find.byType(SizedBox), findsWidgets);

      // Swap to open and pump partway through the forward animation.
      await tester.pumpWidget(
        _wrap(
          RecitationDrawerSurface(
            open: true,
            onClose: () {},
            child: const SizedBox(height: 100, width: 100),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      final stateOpen = tester
          .state<RecitationDrawerSurfaceState>(find.byType(
        RecitationDrawerSurface,
      ));
      // Forward animation has advanced past 0.
      expect(stateOpen.controller.value, greaterThan(0));
      expect(stateOpen.controller.value, lessThanOrEqualTo(1));

      // Let the forward animation finish.
      await tester.pumpAndSettle();
      expect(stateOpen.controller.value, 1);
    });

    testWidgets('runs reverse (1 -> 0) when closed', (tester) async {
      // Start open so the controller initializes at 1.
      await tester.pumpWidget(
        _wrap(
          RecitationDrawerSurface(
            open: true,
            onClose: () {},
            child: const SizedBox(height: 100, width: 100),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final stateOpen = tester
          .state<RecitationDrawerSurfaceState>(find.byType(
        RecitationDrawerSurface,
      ));
      expect(stateOpen.controller.value, 1);

      // Close and pump partway through the reverse animation.
      await tester.pumpWidget(
        _wrap(
          RecitationDrawerSurface(
            open: false,
            onClose: () {},
            child: const SizedBox(height: 100, width: 100),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      final stateClosing = tester
          .state<RecitationDrawerSurfaceState>(find.byType(
        RecitationDrawerSurface,
      ));
      // Reverse animation has started: value dropped below 1 but above 0.
      expect(stateClosing.controller.value, lessThan(1));
      expect(stateClosing.controller.value, greaterThanOrEqualTo(0));

      // Let the reverse animation finish.
      await tester.pumpAndSettle();
      expect(stateClosing.controller.value, 0);
    });

    testWidgets('scrim tap calls onClose only while open', (tester) async {
      var closeCalls = 0;
      await tester.pumpWidget(
        _wrap(
          RecitationDrawerSurface(
            open: true,
            onClose: () => closeCalls++,
            child: const SizedBox(height: 100, width: 100),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the scrim (the ColoredBox filling the stack behind the panel).
      await tester.tap(find.byType(ColoredBox).first);
      await tester.pumpAndSettle();
      expect(closeCalls, 1);
    });

    testWidgets('RTL directionality does not throw and animates open',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          Directionality(
            textDirection: TextDirection.rtl,
            child: RecitationDrawerSurface(
              open: true,
              onClose: () {},
              child: const SizedBox(height: 100, width: 100),
            ),
          ),
          dir: TextDirection.rtl,
        ),
      );
      await tester.pumpAndSettle();
      final state = tester
          .state<RecitationDrawerSurfaceState>(find.byType(
        RecitationDrawerSurface,
      ));
      expect(state.controller.value, 1);
    });
  });

  group('cache management tile', () {
    late _FakePlayer player;
    late _FakePlayerStream stream;
    late StreamController<DemuxerCacheState> demuxerCacheState;
    late TawaqAudioService audioService;

    setUp(() {
      stream = _FakePlayerStream();
      player = _FakePlayer();
      demuxerCacheState =
          StreamController<DemuxerCacheState>.broadcast();
      when(() => stream.demuxerCacheState)
          .thenAnswer((_) => demuxerCacheState.stream);
      when(() => stream.playing)
          .thenAnswer((_) => const Stream<bool>.empty());
      when(() => stream.playWhenReady)
          .thenAnswer((_) => const Stream<bool>.empty());
      when(() => stream.completed)
          .thenAnswer((_) => const Stream<bool>.empty());
      when(() => stream.eofReached)
          .thenAnswer((_) => const Stream<bool>.empty());
      when(() => stream.error)
          .thenAnswer((_) => const Stream<MpvPlayerError>.empty());
      when(() => stream.endFile)
          .thenAnswer((_) => const Stream<MpvFileEndedEvent>.empty());
      when(() => stream.buffering)
          .thenAnswer((_) => const Stream<bool>.empty());
      when(() => stream.pausedForCache)
          .thenAnswer((_) => const Stream<bool>.empty());
      when(() => stream.seekCompleted)
          .thenAnswer((_) => const Stream<void>.empty());
      when(() => stream.position)
          .thenAnswer((_) => const Stream<Duration>.empty());
      when(() => stream.duration)
          .thenAnswer((_) => const Stream<Duration>.empty());
      when(() => stream.remainingAbLoops)
          .thenAnswer((_) => const Stream<int?>.empty());
      when(() => stream.mediaSessionCommands)
          .thenAnswer((_) => const Stream<MediaSessionCommand>.empty());
      when(() => player.stream).thenReturn(stream);
      when(() => player.state).thenReturn(const PlayerState());
      when(() => player.setAudioClientName(any())).thenAnswer((_) async {});
      when(player.dispose).thenAnswer((_) async {});
      audioService = TawaqAudioService(player: player);
    });

    tearDown(() async {
      await demuxerCacheState.close();
      await audioService.dispose();
    });

    Widget scopeWrap(Widget child) {
      final theme = buildAppTheme(
        palette: AppPalette.neutral,
        themeMode: ThemeMode.light,
        touch: false,
        textScale: 1,
      );
      return ProviderScope(
        overrides: [
          recitationDrawerProvider.overrideWith(
            _TestRecitationDrawerNotifier.new,
          ),
          recitationControllerProvider.overrideWith(
            _TestRecitationControllerNotifier.new,
          ),
          recitationSettingsProvider.overrideWith(
            _TestRecitationSettingsNotifier.new,
          ),
          quranScreenSettingsProvider.overrideWith(
            _TestQuranScreenSettingsNotifier.new,
          ),
          quranMushafControllerProvider.overrideWithValue(
            MushafReaderController.withRepository(repository: _FakeRepo()),
          ),
          recitationDownloadProgressProvider.overrideWithValue(null),
          cachedRecitationsSnapshotProvider.overrideWithValue(
            const AsyncData((
              files: <CachedRecitation>[],
              totalBytes: 2 * 1024 * 1024,
            )),
          ),
          recitersProvider.overrideWithValue(const AsyncData(<Reciter>[])),
          localeProvider.overrideWith(_TestLocaleNotifier.new),
          tawaqAudioServiceProvider.overrideWithValue(audioService),
        ],
        child: FTheme(
          data: theme,
          child: const MaterialApp(
            debugShowCheckedModeBanner: false,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MediaQuery(
              data: MediaQueryData(size: Size(400, 1600)),
              child: Scaffold(
                body: SizedBox(
                  width: 400,
                  child: RecitationDrawerOverlay(),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('shows cache tile with formatted total bytes', (tester) async {
      tester.view.physicalSize = const Size(400, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(scopeWrap(const SizedBox.shrink()));
      await tester.pump();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.byType(RecitationDrawerOverlay), findsOneWidget);
      expect(find.text('Offline files'), findsOneWidget);
      expect(find.text('2 MB'), findsOneWidget);
    });

    testWidgets('opens offline files dialog when cache tile tapped',
        (tester) async {
      tester.view.physicalSize = const Size(400, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(scopeWrap(const SizedBox.shrink()));
      await tester.pump();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.tap(find.text('Offline files'));
      await tester.pump();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.byType(PlayerDialogShell), findsOneWidget);
    });
  });
}

class _TestRecitationDrawerNotifier extends RecitationDrawer {
  @override
  bool build() => true;
}

class _TestRecitationControllerNotifier extends RecitationController {
  @override
  RecitationState build() => const RecitationState();
}

class _TestRecitationSettingsNotifier extends RecitationSettingsNotifier {
  @override
  Future<RecitationSettings> build() async => RecitationSettings.initial();
}

class _TestQuranScreenSettingsNotifier extends QuranScreenSettingsNotifier {
  @override
  Future<QuranScreenState> build() async => QuranScreenState.initial();
}

class _FakeRepo implements IQuranRepository {
  @override
  void dispose() {}

  @override
  Future<void> ensureReady() async {}

  @override
  Future<List<Surah>> getAllSurahs() async => [];

  @override
  Future<Ayah> getAyah(int ayahId, [bool removeNewLines = true]) async =>
      throw UnimplementedError();

  @override
  Future<Ayah> getAyahBySurah(
    int surah,
    int ayahInSurah, [
    bool removeNewLines = true,
  ]) async =>
      throw UnimplementedError();

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
  Future<int> getPageForAyah(int ayahId) async => 1;

  @override
  Future<int> getStartPageForSurah(int surahNumber) async => 1;

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

  bool isReady() => true;
}

class _FakePlayer extends Mock implements PlayerApi {}

class _FakePlayerStream extends Mock implements PlayerStream {}

class _TestLocaleNotifier extends LocaleNotifier {
  @override
  Future<String> build() async => 'en';
}
