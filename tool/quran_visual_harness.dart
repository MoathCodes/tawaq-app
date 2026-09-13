/// Reproducible native widget evidence for the Quran study/read surface.
///
/// Run from the repository root with:
///
///   TAWAQ_SCREENSHOT=/tmp/quran-study-light.png \
///     fvm flutter run -d linux -t tool/quran_visual_harness.dart \
///     --dart-define=DARK=false
///
/// Set `DARK=true` for the Manuscript dark capture. The right-hand column is
/// the actual `QuranMushafPane` composition with its selected-ayah action bar;
/// the left-hand column uses the actual `StudyContentSection` and
/// `TranslationProse`. The small language panel below is a labeled font
/// specimen using the literal first-row strings from the bundled databases.
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/quran/data/models/translation.dart';
import 'package:tawaq/feature/quran/domain/models/translation_source.dart';
import 'package:tawaq/feature/quran/presentation/models/quran_ui_models.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_mushaf_controller_provider.dart';
import 'package:tawaq/feature/quran/presentation/providers/quran_screen_settings_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_mushaf_pane.dart';
import 'package:tawaq/feature/quran/presentation/widgets/quran_semantics.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/translation_source_selector.dart';
import 'package:tawaq/feature/quran/presentation/widgets/study/study_content_section.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

class _HarnessSettings extends QuranScreenSettingsNotifier {
  @override
  Future<QuranScreenState> build() async => QuranScreenState.initial().copyWith(
    layout: QuranReadingLayout.studyMode,
    translationEnabled: true,
    selectedTranslation: TranslationId.saheehInternational,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Use a dedicated app-data subdirectory so this preview reads the shipped
  // Hive fixture without contending with a running Tawaq instance's lock.
  await MushafReaderLibrary.ensureInitialized(
    subDirectory: 'tawaq-quran-review-harness',
  );
  final controller = MushafReaderController();
  const dark = bool.fromEnvironment('DARK');
  final theme = buildAppTheme(
    palette: AppPalette.manuscript,
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    touch: false,
    textScale: 1,
  );

  runApp(
    ProviderScope(
      overrides: [
        quranMushafControllerProvider.overrideWithValue(controller),
        quranScreenSettingsProvider.overrideWith(_HarnessSettings.new),
        appThemeDataProvider.overrideWithValue(theme),
        quranSelectedAyahProvider.overrideWithValue(
          AsyncData(
            Ayah(
              ayahId: 1,
              juz: 1,
              page: 1,
              surahNumber: 1,
              numberInSurah: 1,
              text: 'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
              textPlain: 'In the name of Allah',
            ),
          ),
        ),
        quranSelectedAyahIdProvider.overrideWith(_HarnessSelectedAyah.new),
      ],
      child: FTheme(
        data: theme,
        child: FToaster(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: _HarnessPage(theme: theme),
          ),
        ),
      ),
    ),
  );

  // Allow the real reader's initial Hive page and study animations to settle.
  await Future<void>.delayed(const Duration(seconds: 4));
  final path = Platform.environment['TAWAQ_SCREENSHOT'];
  if (path != null && path.isNotEmpty) {
    final renderObject = _captureKey.currentContext!.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      throw StateError('Screenshot boundary was not laid out');
    }
    final boundary = renderObject;
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes != null) {
      await File(path).writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    }
  }
  controller.dispose();
  exit(0);
}

final GlobalKey _captureKey = GlobalKey();

class _HarnessSelectedAyah extends QuranSelectedAyahId {
  @override
  int? build() => 1;
}

class _HarnessPage extends StatelessWidget {
  const _HarnessPage({required this.theme});

  final FThemeData theme;

  @override
  Widget build(BuildContext context) {
    final colors = theme.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: RepaintBoundary(
          key: _captureKey,
          child: ColoredBox(
            color: colors.background,
            child: SizedBox(
              width: 940,
              height: 680,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: 350, child: _StudyFixture(theme: theme)),
                    const SizedBox(width: 20),
                    Expanded(
                      child: QuranSemantics.landmark(
                        label: 'Quran reader',
                        child: const QuranMushafPane(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StudyFixture extends StatelessWidget {
  const _StudyFixture({required this.theme});

  final FThemeData theme;

  @override
  Widget build(BuildContext context) {
    final colors = theme.colors;
    final typography = theme.typography;
    const source = TranslationId.saheehInternational;
    const translation = Translation(
      id: 1,
      sura: 1,
      aya: 1,
      translation: 'In the name of Allāh,[2] the Entirely Merciful, the Especially Merciful.[3]',
    );
    return QuranSemantics.landmark(
      label: 'Quran study',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Study · Read mode',
              style: typography.body.lg.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            StudyContentSection<Translation?>(
              asyncValue: const AsyncData(translation),
              contentKey: 'harness-translation',
              errorMessage: 'Translation unavailable',
              emptyMessage: 'No translation available',
              sourceSelector: const TranslationSourceSelector(showLabel: false),
              contentBuilder: (value) => TranslationProse(
                translation: value!,
                source: source,
                style: typography.body.md.copyWith(
                  color: colors.foreground,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Font specimens · bundled source rows',
              style: typography.body.sm.copyWith(
                color: colors.mutedForeground,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const _Specimen(
              label: 'Arabic · tafsir shell',
              text: 'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
              direction: TextDirection.rtl,
            ),
            const _Specimen(
              label: 'Urdu · quran_ur row 1:1',
              text: 'اللہ کے نام سے جو رحمان و رحیم ہے',
              direction: TextDirection.rtl,
              fontFamily: 'NotoNastaliqUrdu',
            ),
            const _Specimen(
              label: 'Bengali · quran_bn row 1:1',
              text: 'শুরু করছি আল্লাহর নামে যিনি পরম করুণাময়, অতি দয়ালু।',
              direction: TextDirection.ltr,
              fontFamily: 'NotoSansBengali',
            ),
            const _Specimen(
              label: 'Chinese · quran_zh row 1:1',
              text: '奉至仁至慈的安拉之名',
              direction: TextDirection.ltr,
              fontFamily: 'NotoSansSC',
            ),
          ],
        ),
      ),
    );
  }
}

class _Specimen extends StatelessWidget {
  const _Specimen({
    required this.label,
    required this.text,
    required this.direction,
    this.fontFamily,
  });

  final String label;
  final String text;
  final TextDirection direction;
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    final typography = context.theme.typography;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Directionality(
        textDirection: direction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label,
              textDirection: TextDirection.ltr,
              style: typography.body.xs.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
            Text(
              text,
              style: typography.body.md.copyWith(
                fontFamily: fontFamily,
                height: direction == TextDirection.rtl ? 1.8 : 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
