import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/audio/playback_state.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_settings.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_state.dart';
import 'package:tawaq/feature/quran/domain/models/reciter.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/recitation_transport_controls.dart';
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
}

const _moshaf = Moshaf(
  id: 1,
  name: 'Hafs',
  server: 'https://example.com/',
  surahList: [1],
  surahTotal: 1,
);

const _reciter = Reciter(id: 1, name: 'Test reciter', moshaf: [_moshaf]);

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
