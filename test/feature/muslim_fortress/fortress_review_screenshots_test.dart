import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:hisn_elmoslem/hisn_elmoslem.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/experimental/persist.dart';
import 'package:tawaq/core/bootstrap/app_init_providers.dart';
import 'package:tawaq/core/storage/settings_storage.dart';
import 'package:tawaq/core/widgets/custom_cards.dart';
import 'package:tawaq/feature/muslim_fortress/domain/fortress_models.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_dua_item.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/browse/fortress_category_detail.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme.dart';
import 'package:tawaq/theme/theme_model.dart';

const _category = FortressCategory(
  chapterId: 9,
  title: 'Morning remembrance',
  recurrence: HisnRecurrence.daily,
  supplicationCount: 4,
);

const _dua = FortressDuaItem(
  contentId: 91,
  category: 'Review fixture',
  text: 'O Allah, help me remember You, give thanks to You, and worship You in the best manner. This is synthetic review content.',
  targetCount: 3,
  lines: [
    HisnPlainLine(
      'O Allah, help me remember You, give thanks to You, and worship You in the best manner.',
    ),
  ],
  commentary: HisnCommentary(
    id: 92,
    contentId: 91,
    sharh: 'Synthetic explanation for the review image.',
    hadith: 'Synthetic related hadith for the review image.',
    benefit: 'Synthetic benefit for the review image.',
  ),
);

Widget _gallery({
  required double width,
  required Locale locale,
  required ThemeMode themeMode,
  required AppPalette palette,
  required double textScale,
}) {
  final key = ValueKey('${locale.languageCode}-${themeMode.name}-$width');
  return ProviderScope(
    overrides: [
      hiveCoreInitProvider.overrideWith((ref) async {}),
      settingsStorageProvider.overrideWith(
        (ref) async => Storage<String, String>.inMemory(),
      ),
    ],
    child: FTheme(
      data: buildAppTheme(
        palette: palette,
        themeMode: themeMode,
        touch: false,
        textScale: textScale,
      ),
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: width,
              child: RepaintBoundary(
                key: key,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FortressCategoryDetailHeader(
                      category: _category,
                      duaCount: 4,
                      onStartReading: () {},
                    ),
                    const SizedBox(height: 16),
                    FortressDuaPreviewCard(
                      index: 0,
                      dua: _dua,
                      isExpanded: false,
                      onToggleExpanded: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _baselineGallery({
  required double width,
  required Locale locale,
  required ThemeMode themeMode,
  required AppPalette palette,
  required double textScale,
}) {
  final key = ValueKey(
    'baseline-${locale.languageCode}-${themeMode.name}-$width',
  );
  return ProviderScope(
    overrides: [
      hiveCoreInitProvider.overrideWith((ref) async {}),
      settingsStorageProvider.overrideWith(
        (ref) async => Storage<String, String>.inMemory(),
      ),
    ],
    child: FTheme(
      data: buildAppTheme(
        palette: palette,
        themeMode: themeMode,
        touch: false,
        textScale: textScale,
      ),
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: width,
              child: RepaintBoundary(
                key: key,
                child: Column(
                  children: [
                    StaticCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _BaselineHeader(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    FortressDuaPreviewCard(
                      index: 0,
                      dua: _dua,
                      isExpanded: false,
                      onToggleExpanded: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _BaselineHeader extends StatelessWidget {
  const _BaselineHeader();

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                _category.title,
                style: theme.typography.body.xl2.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const SizedBox(width: 30, height: 30),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          fortressRecurrenceLabel(_category.recurrence, l10n),
          style: theme.typography.body.md.copyWith(
            color: theme.colors.mutedForeground,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FBadge(child: Text(l10n.fortressSupplicationsInSection(4))),
        const SizedBox(height: AppSpacing.lg),
        FButton(
          prefix: const Icon(FLucideIcons.bookOpen),
          onPress: () {},
          child: Text(l10n.fortressStartReading),
        ),
      ],
    );
  }
}

void main() {
  setUpAll(() async {
    final loader = FontLoader('IBMPlexSansArabic')
      ..addFont(
        rootBundle.load(
          'assets/fonts/IBM_Plex_Sans_Arabic/IBMPlexSansArabic-Regular.ttf',
        ),
      );
    await loader.load();
  });

  _goldenTest(
    'desktop English Manuscript light',
    width: 720,
    locale: const Locale('en'),
    themeMode: ThemeMode.light,
    palette: AppPalette.manuscript,
    textScale: 1,
    file: 'goldens/fortress_desktop_en_manuscript_light.png',
  );
  _goldenTest(
    'narrow Arabic Manuscript dark large text',
    width: 360,
    locale: const Locale('ar'),
    themeMode: ThemeMode.dark,
    palette: AppPalette.manuscript,
    textScale: 1.3,
    file: 'goldens/fortress_narrow_ar_manuscript_dark_large.png',
  );
  _goldenTest(
    'desktop English Neutral light',
    width: 720,
    locale: const Locale('en'),
    themeMode: ThemeMode.light,
    palette: AppPalette.neutral,
    textScale: 1,
    file: 'goldens/fortress_desktop_en_neutral_light.png',
  );
  _goldenTest(
    'narrow Arabic Neutral dark',
    width: 360,
    locale: const Locale('ar'),
    themeMode: ThemeMode.dark,
    palette: AppPalette.neutral,
    textScale: 1,
    file: 'goldens/fortress_narrow_ar_neutral_dark.png',
  );

  _baselineGoldenTest(
    'baseline desktop English Manuscript light',
    width: 720,
    locale: const Locale('en'),
    themeMode: ThemeMode.light,
    palette: AppPalette.manuscript,
    textScale: 1,
    file: 'goldens/baseline_desktop_en_manuscript_light.png',
  );
  _baselineGoldenTest(
    'baseline narrow Arabic Manuscript dark large text',
    width: 360,
    locale: const Locale('ar'),
    themeMode: ThemeMode.dark,
    palette: AppPalette.manuscript,
    textScale: 1.3,
    file: 'goldens/baseline_narrow_ar_manuscript_dark_large.png',
  );
  _baselineGoldenTest(
    'baseline desktop English Neutral light',
    width: 720,
    locale: const Locale('en'),
    themeMode: ThemeMode.light,
    palette: AppPalette.neutral,
    textScale: 1,
    file: 'goldens/baseline_desktop_en_neutral_light.png',
  );
  _baselineGoldenTest(
    'baseline narrow Arabic Neutral dark',
    width: 360,
    locale: const Locale('ar'),
    themeMode: ThemeMode.dark,
    palette: AppPalette.neutral,
    textScale: 1,
    file: 'goldens/baseline_narrow_ar_neutral_dark.png',
  );
}

void _goldenTest(
  String description, {
  required double width,
  required Locale locale,
  required ThemeMode themeMode,
  required AppPalette palette,
  required double textScale,
  required String file,
}) {
  testWidgets(description, (tester) async {
    await tester.pumpWidget(
      _gallery(
        width: width,
        locale: locale,
        themeMode: themeMode,
        palette: palette,
        textScale: textScale,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(ValueKey('${locale.languageCode}-${themeMode.name}-$width')),
      matchesGoldenFile(file),
    );
  });
}

void _baselineGoldenTest(
  String description, {
  required double width,
  required Locale locale,
  required ThemeMode themeMode,
  required AppPalette palette,
  required double textScale,
  required String file,
}) {
  testWidgets(description, (tester) async {
    await tester.pumpWidget(
      _baselineGallery(
        width: width,
        locale: locale,
        themeMode: themeMode,
        palette: palette,
        textScale: textScale,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(
        ValueKey('baseline-${locale.languageCode}-${themeMode.name}-$width'),
      ),
      matchesGoldenFile(file),
    );
  });
}
