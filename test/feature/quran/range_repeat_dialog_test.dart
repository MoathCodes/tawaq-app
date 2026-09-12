import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_models.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_settings.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_state.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/dialogs/range_repeat_dialog.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

class _Repository extends Mock implements IQuranRepository {}

class _Controller extends RecitationController {
  _Controller(this.value);

  final RecitationState value;

  @override
  RecitationState build() => value;
}

class _Settings extends RecitationSettingsNotifier {
  _Settings(this.value);

  final RecitationSettings value;

  @override
  Future<RecitationSettings> build() async {
    state = AsyncData(value);
    return value;
  }
}

class _OpenDialog extends StatefulWidget {
  const _OpenDialog({required this.initial});

  final RangeRepeatInit? initial;

  @override
  State<_OpenDialog> createState() => _OpenDialogState();
}

class _OpenDialogState extends State<_OpenDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(showRangeRepeatDialog(context, initial: widget.initial));
      }
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

Widget _app({
  required RecitationState playback,
  required RecitationSettings settings,
  required RecitationInitializationStatus initialization,
  Locale locale = const Locale('en'),
}) {
  final repository = _Repository();
  when(() => repository.ensureReady()).thenAnswer((_) async {});
  when(() => repository.getBasmalah()).thenAnswer((_) async => '');
  when(() => repository.getJuzs()).thenAnswer((_) async => []);
  when(() => repository.getHizbs()).thenAnswer((_) async => []);
  when(() => repository.getAllSurahs()).thenAnswer(
    (_) async => [
      for (var number = 1; number <= 114; number++)
        Surah(
          number: number,
          glyph: '',
          hasBasmalah: true,
          ayahCount: number == 2 ? 286 : 7,
        ),
    ],
  );
  when(() => repository.getPage(any())).thenAnswer(
    (invocation) async => QuranPage(
      pageNumber: invocation.positionalArguments.single as int,
      glyphText: '',
      lines: const [],
      surahs: const [],
      juzNumber: 1,
    ),
  );
  when(() => repository.getSurahSync(any())).thenAnswer(
    (invocation) => Surah(
      number: invocation.positionalArguments.single as int,
      glyph: '',
      hasBasmalah: true,
      ayahCount: 7,
    ),
  );
  final mushaf = MushafReaderController.withRepository(
    repository: repository,
  );
  return ProviderScope(
    overrides: [
      recitationControllerProvider.overrideWith(
        () => _Controller(
          playback.copyWith(initializationStatus: initialization),
        ),
      ),
      recitationSettingsProvider.overrideWith(() => _Settings(settings)),
      quranSelectedAyahProvider.overrideWith((ref) async => null),
      selectedRecitationProvider.overrideWith((ref) async => null),
      quranMushafControllerProvider.overrideWithValue(mushaf),
    ],
    child: FTheme(
      data: buildAppTheme(
        palette: AppPalette.neutral,
        themeMode: ThemeMode.light,
        touch: false,
        textScale: 1,
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: _OpenDialog(initial: null)),
      ),
    ),
  );
}

void main() {
  testWidgets('renders suggestion in a narrow RTL dialog', (tester) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _app(
        playback: const RecitationState(),
        settings: const RecitationSettings(),
        initialization: RecitationInitializationStatus.ready,
        locale: const Locale('ar'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('اقتراح'), findsOneWidget);
    expect(find.text('حفظ المدى'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('restores a saved whole-surah range without suggestion', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        playback: const RecitationState(),
        settings: const RecitationSettings(
          lastSurah: 2,
          lastRangePreset: RangeScopePreset.thisSurah,
        ),
        initialization: RecitationInitializationStatus.ready,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Suggested'), findsNothing);
    expect(find.text('Save range'), findsOneWidget);
    expect(find.text('Select reciter'), findsOneWidget);
    final saveButton = find.ancestor(
      of: find.text('Save range'),
      matching: find.byType(FButton),
    );
    expect(
      tester.widget<FButton>(saveButton).onPress,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows a disabled save action while initializing', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        playback: const RecitationState(),
        settings: const RecitationSettings(),
        initialization: RecitationInitializationStatus.initializing,
      ),
    );
    await tester.pump();

    expect(find.text('Range & repeat for memorization'), findsOneWidget);
    expect(find.text('Save range'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows retry UI when initialization fails', (tester) async {
    await tester.pumpWidget(
      _app(
        playback: const RecitationState(),
        settings: const RecitationSettings(),
        initialization: RecitationInitializationStatus.failed,
      ),
    );
    await tester.pump();

    expect(find.byType(FAlert), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
