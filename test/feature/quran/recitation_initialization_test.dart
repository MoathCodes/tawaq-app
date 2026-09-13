import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/audio/audio_lease.dart';
import 'package:tawaq/core/audio/playback_state.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_models.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_settings.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_state.dart';
import 'package:tawaq/feature/quran/domain/models/reciter.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/recitation_transport.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/recitation_transport_controls.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

Widget _wrap(Widget child) => FTheme(
  data: buildAppTheme(
    palette: AppPalette.neutral,
    themeMode: ThemeMode.light,
    touch: false,
    textScale: 1,
  ),
  child: MaterialApp(home: Scaffold(body: child)),
);

void main() {
  group('recitation initialization state', () {
    test('is separate from audio loading', () {
      const state = RecitationState(
        initializationStatus: RecitationInitializationStatus.initializing,
      );

      expect(state.isInitializing, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.isInitializationReady, isFalse);
    });

    test('play remains unavailable without a restored selection', () {
      const view = RecitationViewState(
        session: RecitationState(),
        preferences: RecitationSettings(),
        audio: AudioSessionSnapshot(),
      );

      expect(view.canPlay, isFalse);
    });

    test(
      'switching reciter recovers a failed session without a surah',
      () async {
        final container = ProviderContainer(
          overrides: [
            recitationControllerProvider.overrideWith(
              _FailedRecitationController.new,
            ),
            recitationSettingsProvider.overrideWith(
              _TestRecitationSettingsNotifier.new,
            ),
          ],
        );
        addTearDown(container.dispose);

        await container.read(recitationSettingsProvider.future);
        final controller = container.read(
          recitationControllerProvider.notifier,
        );

        await controller.switchReciter(_reciter, _moshaf);

        expect(
          controller.state.initializationStatus,
          RecitationInitializationStatus.ready,
        );
        expect(controller.state.initializationError, isNull);
        expect(controller.state.reciter, _reciter);
        expect(controller.state.moshaf, _moshaf);
      },
    );
  });

  testWidgets('initialization renders a non-interactive play loader', (
    tester,
  ) async {
    var pressed = false;
    await tester.pumpWidget(
      _wrap(
        RecitationPlayButton(
          isPlaying: false,
          isLoading: false,
          isInitializing: true,
          onPress: () async => pressed = true,
        ),
      ),
    );

    expect(find.byType(FCircularProgress), findsOneWidget);
    await tester.tap(find.byType(FCircularProgress));
    expect(pressed, isFalse);
  });

  testWidgets('no saved selection renders a disabled play button', (
    tester,
  ) async {
    var pressed = false;
    await tester.pumpWidget(
      _wrap(
        RecitationPlayButton(
          isPlaying: false,
          isLoading: false,
          enabled: false,
          onPress: () async => pressed = true,
        ),
      ),
    );

    await tester.tap(find.byIcon(FLucideIcons.play));
    await tester.pump(const Duration(milliseconds: 100));
    expect(pressed, isFalse);
  });

  testWidgets('focused play control reveals context tooltip and activates', (
    tester,
  ) async {
    var pressed = false;
    const label = 'Play · Al-Baqarah · Test reciter';
    await tester.pumpWidget(
      _wrap(
        Focus(
          autofocus: true,
          child: RecitationPlayButton(
            isPlaying: false,
            isLoading: false,
            semanticsLabel: label,
            tooltip: label,
            onPress: () async => pressed = true,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump(const Duration(seconds: 1));

    expect(find.text(label), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(pressed, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(seconds: 1));
  });

  test('title-bar playback label includes action and hydrated context', () {
    final l10n = lookupAppLocalizations(const Locale('en'));

    expect(
      recitationTransportPlaybackLabel(
        l10n: l10n,
        state: recitationTransportPlaybackState(
          _view(
            const RecitationState(
              reciter: _reciter,
              moshaf: _timedMoshaf,
              surah: 2,
              status: RecitationStatus.playing,
            ),
            audio: const AudioSessionSnapshot(
              owner: kRecitationLeaseOwner,
              lifecycle: AudioSessionLifecycle.playing,
              playIntent: true,
            ),
          ),
        ),
        surahName: 'Al-Baqarah',
      ),
      'Pause · Al-Baqarah · Test reciter',
    );
    expect(
      recitationTransportPlaybackLabel(
        l10n: l10n,
        state: recitationTransportPlaybackState(
          _view(const RecitationState()),
        ),
      ),
      contains('Choose a reciter'),
    );
    expect(
      recitationTransportPlaybackLabel(
        l10n: l10n,
        state: recitationTransportPlaybackState(
          _view(const RecitationState(reciter: _reciter)),
        ),
      ),
      contains('Choose a recitation'),
    );
    expect(
      recitationTransportPlaybackLabel(
        l10n: l10n,
        state: recitationTransportPlaybackState(
          _view(
            const RecitationState(reciter: _reciter, moshaf: _timedMoshaf),
          ),
        ),
      ),
      contains('Choose a surah'),
    );
    expect(
      recitationTransportPlaybackLabel(
        l10n: l10n,
        state: recitationTransportPlaybackState(
          _view(
            const RecitationState(
              rangeFrom: AyahReference(surah: 2, ayah: 1),
            ),
          ),
        ),
      ),
      isNot(contains('timed reciter')),
    );
    expect(
      recitationTransportPlaybackLabel(
        l10n: l10n,
        state: recitationTransportPlaybackState(
          _view(
            const RecitationState(
              initializationStatus: RecitationInitializationStatus.initializing,
            ),
          ),
        ),
      ),
      contains('Loading'),
    );
    expect(
      recitationTransportPlaybackLabel(
        l10n: l10n,
        state: recitationTransportPlaybackState(
          _view(
            const RecitationState(
              initializationStatus: RecitationInitializationStatus.failed,
              initializationError: 'Fixture failure',
            ),
          ),
        ),
      ),
      contains(l10n.quranRecitationInitializationFailed),
    );
    expect(
      recitationTransportPlaybackLabel(
        l10n: l10n,
        state: recitationTransportPlaybackState(
          _view(
            const RecitationState(
              reciter: _reciter,
              moshaf: _timedMoshaf,
              surah: 2,
              status: RecitationStatus.ended,
            ),
          ),
        ),
      ),
      startsWith('Replay'),
    );
    expect(
      recitationTransportPlaybackLabel(
        l10n: l10n,
        state: recitationTransportPlaybackState(
          _view(
            const RecitationState(status: RecitationStatus.loading),
          ),
        ),
      ),
      contains('Loading'),
    );
  });
}

const _moshaf = Moshaf(
  id: 1,
  name: 'Hafs',
  server: 'https://example.com/',
  surahList: [1],
  surahTotal: 1,
);

const _timedMoshaf = Moshaf(
  id: 2,
  name: 'Timed Hafs',
  server: 'https://example.com/',
  surahList: [1, 2],
  surahTotal: 2,
  timingReadId: 22,
);

const _reciter = Reciter(id: 1, name: 'Test reciter', moshaf: [_moshaf]);

RecitationViewState _view(
  RecitationState session, {
  AudioSessionSnapshot audio = const AudioSessionSnapshot(),
}) => RecitationViewState(
  session: session,
  preferences: const RecitationSettings(),
  audio: audio,
);

class _FailedRecitationController extends RecitationController {
  @override
  RecitationState build() => const RecitationState(
    active: true,
    initializationStatus: RecitationInitializationStatus.failed,
    initializationError: 'Reference data unavailable',
  );
}

class _TestRecitationSettingsNotifier extends RecitationSettingsNotifier {
  @override
  Future<RecitationSettings> build() async {
    const settings = RecitationSettings();
    state = const AsyncData(settings);
    return settings;
  }

  @override
  bool? setReciter({
    required int reciterId,
    int? moshafId,
    String? moshafName,
  }) {
    state = AsyncData(
      state.requireValue.copyWith(reciterId: reciterId, moshafId: moshafId),
    );
    return null;
  }
}
