import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/detail/hadith_detail_pane.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/results/hadith_result_card.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/recitation_transport_controls.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

const _sourceText = 'إنما الأعمال بالنيات';
const _fixtureJudgment =
    'Fixture judgment: qualified source wording remains readable across a '
    'narrow pane and wraps without ellipsis for visual contract evidence.';

void main() {
  const language = String.fromEnvironment('PREVIEW_LOCALE', defaultValue: 'en');
  const dark = bool.fromEnvironment('PREVIEW_DARK');
  const largeText = bool.fromEnvironment('PREVIEW_LARGE_TEXT');
  const locale = Locale(language);
  final l10n = lookupAppLocalizations(locale);
  const hadith = DetailedHadith(
    hadith: _sourceText,
    rawi: 'عمر بن الخطاب',
    mohdith: 'البخاري',
    book: 'صحيح البخاري · كتاب بدء الوحي',
    numberOrPage: '1',
    grade: _fixtureJudgment,
    hadithId: 'taw-80-preview',
  );
  final playbackLabel = language == 'ar'
      ? '${l10n.quranRecitationPlay} · البقرة · قارئ تجريبي'
      : '${l10n.quranRecitationPlay} · Al-Baqarah · Fixture reciter';

  runApp(
    ProviderScope(
      overrides: [
        hadithFavoritesProvider.overrideWith((ref) async => const []),
      ],
      child: FTheme(
        data: buildAppTheme(
          palette: AppPalette.manuscript,
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          touch: false,
          textScale: largeText ? 1.3 : 1,
        ),
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 24,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        width: 500,
                        child: HadithResultCard(
                          hadith: hadith,
                          resultOrdinal: 2,
                          isFavorite: false,
                          isSelected: true,
                          onSelect: () {},
                        ),
                      ),
                      const SizedBox(width: 24),
                      SizedBox(
                        width: 500,
                        height: 620,
                        child: const HadithSelectedDetailsPane(
                          hadith: hadith,
                          resultOrdinal: 2,
                        ),
                      ),
                    ],
                  ),
                  Focus(
                    autofocus: true,
                    child: FTooltip(
                      control: const FTooltipControl.managed(initial: true),
                      tipBuilder: (_, _) => Text(playbackLabel),
                      child: RecitationPlayButton(
                        isPlaying: false,
                        isLoading: false,
                        semanticsLabel: playbackLabel,
                        tooltip: playbackLabel,
                        onPress: () async {},
                      ),
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
