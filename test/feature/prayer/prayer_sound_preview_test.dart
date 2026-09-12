import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/feature/prayer/domain/models/adhan_settings.dart';
import 'package:tawaq/feature/prayer/presentation/provider/adhan_preview_provider.dart';
import 'package:tawaq/feature/prayer/presentation/provider/adhan_settings_provider.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/prayer_sound_preview.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme.dart';
import 'package:tawaq/theme/theme_model.dart';

class _FakePreview extends AdhanPreview {
  _FakePreview({this.playGate});

  Completer<void>? playGate;
  Object? playError;
  int plays = 0;
  int stops = 0;

  @override
  AdhanPreviewState build() => const AdhanPreviewState();

  @override
  Future<void> previewAdhan(
    AdhanSound sound, {
    required String label,
    required double volume,
  }) async {
    plays++;
    if (state.isActiveAdhan(sound)) {
      await stop();
      return;
    }
    state = AdhanPreviewState(
      status: AdhanPreviewStatus.loading,
      adhanSound: sound,
    );
    final gate = playGate;
    if (gate != null) await gate.future;
    if (playError != null) {
      state = state.copyWith(
        status: AdhanPreviewStatus.error,
        error: () => '$playError',
      );
      return;
    }
    state = state.copyWith(status: AdhanPreviewStatus.playing);
  }

  @override
  Future<void> previewIqamah(
    IqamahSound sound, {
    required String label,
    required double volume,
  }) async {
    plays++;
    if (state.isActiveIqamah(sound)) {
      await stop();
      return;
    }
    state = AdhanPreviewState(
      status: AdhanPreviewStatus.loading,
      iqamahSound: sound,
    );
    state = state.copyWith(status: AdhanPreviewStatus.playing);
  }

  @override
  Future<void> stop() async {
    stops++;
    state = const AdhanPreviewState();
  }
}

class _Settings extends AdhanSettingsNotifier {
  @override
  Future<AdhanSettings> build() async {
    state = AsyncData(AdhanSettings.defaults());
    return AdhanSettings.defaults();
  }
}

class _PendingSettings extends AdhanSettingsNotifier {
  @override
  Future<AdhanSettings> build() => Completer<AdhanSettings>().future;
}

Widget _settingsRow(Widget preview) => Row(
  spacing: AppSpacing.sm,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    const Expanded(child: SizedBox(height: 44)),
    preview,
  ],
);

Widget _wrap(
  Widget child, {
  double width = 400,
  TextDirection textDirection = TextDirection.ltr,
}) => FTheme(
  data: buildAppTheme(
    palette: AppPalette.neutral,
    themeMode: ThemeMode.light,
    touch: false,
    textScale: 1,
  ),
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Directionality(
        textDirection: textDirection,
        child: SizedBox(width: width, child: child),
      ),
    ),
  ),
);

void main() {
  testWidgets('adhan and iqamah share one preview slot', (tester) async {
    final preview = _FakePreview();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adhanPreviewProvider.overrideWith(() => preview),
          adhanSettingsProvider.overrideWith(_Settings.new),
        ],
        child: _wrap(
          Column(
            children: [
              _settingsRow(
                const AdhanSoundPreviewButton(
                  sound: AdhanSound.misharyAlafasi,
                  label: 'Mishary',
                ),
              ),
              _settingsRow(
                const IqamahSoundPreviewButton(
                  sound: IqamahSound.misharyAlafasi,
                  label: 'Mishary',
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(FLucideIcons.play), findsNWidgets(2));
    expect(find.byIcon(FLucideIcons.square), findsNothing);

    await tester.tap(find.byIcon(FLucideIcons.play).first);
    await tester.pumpAndSettle();

    expect(preview.plays, 1);
    expect(find.byIcon(FLucideIcons.square), findsOneWidget);
    expect(find.byIcon(FLucideIcons.play), findsOneWidget);

    // Preview iqamah instead: the single slot switches over.
    await tester.tap(find.byIcon(FLucideIcons.play));
    await tester.pumpAndSettle();

    expect(preview.plays, 2);
    expect(find.byIcon(FLucideIcons.square), findsOneWidget);
    expect(find.byIcon(FLucideIcons.play), findsOneWidget);

    await tester.tap(find.byIcon(FLucideIcons.square));
    await tester.pumpAndSettle();

    expect(preview.stops, 1);
    expect(find.byIcon(FLucideIcons.play), findsNWidgets(2));
  });

  testWidgets(
    'renders the production row at narrow and desktop widths in both directions',
    (tester) async {
      for (final direction in TextDirection.values) {
        for (final width in [180.0, 1024.0]) {
          final preview = _FakePreview();
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                adhanPreviewProvider.overrideWith(() => preview),
                adhanSettingsProvider.overrideWith(_Settings.new),
              ],
              child: _wrap(
                _settingsRow(
                  const AdhanSoundPreviewButton(
                    sound: AdhanSound.misharyAlafasi,
                    label: 'Mishary',
                  ),
                ),
                width: width,
                textDirection: direction,
              ),
            ),
          );
          await tester.pump();

          expect(tester.takeException(), isNull);
        }
      }
    },
  );

  testWidgets('disables preview until adhan settings are hydrated', (
    tester,
  ) async {
    final preview = _FakePreview();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adhanPreviewProvider.overrideWith(() => preview),
          adhanSettingsProvider.overrideWith(_PendingSettings.new),
        ],
        child: _wrap(
          _settingsRow(
            const AdhanSoundPreviewButton(
              sound: AdhanSound.misharyAlafasi,
              label: 'Mishary',
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final button = tester.widget<FButton>(find.byType(FButton));
    expect(button.onPress, isNull);
    await tester.tap(find.byType(FButton));
    await tester.pump(const Duration(milliseconds: 200));
    expect(preview.plays, 0);
  });

  testWidgets(
    'shows loading, playing, and error states without changing row width',
    (tester) async {
      final preview = _FakePreview(playGate: Completer<void>());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adhanPreviewProvider.overrideWith(() => preview),
            adhanSettingsProvider.overrideWith(_Settings.new),
          ],
          child: _wrap(
            _settingsRow(
              const AdhanSoundPreviewButton(
                sound: AdhanSound.misharyAlafasi,
                label: 'Mishary',
              ),
            ),
            width: 180,
            textDirection: TextDirection.rtl,
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byIcon(FLucideIcons.play));
      await tester.pump();

      expect(find.byType(FCircularProgress), findsOneWidget);
      expect(tester.takeException(), isNull);

      preview.playGate!.complete();
      await tester.pump();
      expect(find.byIcon(FLucideIcons.square), findsOneWidget);

      await tester.tap(find.byIcon(FLucideIcons.square));
      await tester.pumpAndSettle();
      expect(preview.stops, 1);

      preview
        ..playGate = null
        ..playError = StateError('preview failed');
      await tester.tap(find.byIcon(FLucideIcons.play));
      await tester.pumpAndSettle();
      expect(find.byIcon(FLucideIcons.circleAlert), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
