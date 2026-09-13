import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/audio/playback_state.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/detail/hadith_detail_pane.dart';
import 'package:tawaq/feature/hadith/presentation/widgets/results/hadith_result_card.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_settings.dart';
import 'package:tawaq/feature/quran/domain/models/recitation_state.dart';
import 'package:tawaq/feature/quran/domain/models/reciter.dart';
import 'package:tawaq/feature/quran/presentation/providers/recitation_provider.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/recitation_transport.dart';
import 'package:tawaq/feature/quran/presentation/widgets/player/recitation_transport_controls.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

const _sourceText = 'إنما الأعمال بالنيات';
const _fixtureJudgment =
    'Fixture judgment: qualified source wording remains readable across a '
    'narrow pane and wraps without ellipsis for visual contract evidence.';

const _fixtureMoshaf = Moshaf(
  id: 80,
  name: 'Fixture timed recitation',
  server: 'https://example.com/',
  surahList: [2],
  surahTotal: 1,
  timingReadId: 80,
);

const _fixtureReciterEn = Reciter(
  id: 80,
  name: 'Fixture reciter',
  moshaf: [_fixtureMoshaf],
);

const _fixtureReciterAr = Reciter(
  id: 80,
  name: 'قارئ تجريبي',
  moshaf: [_fixtureMoshaf],
);

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
  const previewView = RecitationViewState(
    session: RecitationState(
      reciter: language == 'ar' ? _fixtureReciterAr : _fixtureReciterEn,
      moshaf: _fixtureMoshaf,
      surah: 2,
    ),
    preferences: RecitationSettings(),
    audio: AudioSessionSnapshot(),
  );
  final playbackState = recitationTransportPlaybackState(previewView);
  final playbackLabel = recitationTransportPlaybackLabel(
    l10n: l10n,
    state: playbackState,
    surahName: language == 'ar' ? 'البقرة' : 'Al-Baqarah',
  );
  final appTheme = buildAppTheme(
    palette: AppPalette.manuscript,
    themeMode: dark ? ThemeMode.dark : ThemeMode.light,
    touch: false,
    textScale: largeText ? 1.3 : 1,
  );
  final materialTheme = appTheme.toApproximateMaterialTheme();

  runApp(
    ProviderScope(
      overrides: [
        hadithFavoritesProvider.overrideWith((ref) async => const []),
      ],
      child: MaterialApp(
        theme: materialTheme,
        darkTheme: materialTheme,
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: FTheme(
          data: appTheme,
          child: FScaffold(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const gap = 16.0;
                  final paneWidth = ((constraints.maxWidth - gap) / 2).clamp(
                    0.0,
                    520.0,
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 24,
                    children: [
                      SizedBox(
                        height: 640,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: paneWidth,
                              child: HadithResultCard(
                                hadith: hadith,
                                resultOrdinal: 2,
                                isFavorite: false,
                                isSelected: true,
                                onSelect: () {},
                              ),
                            ),
                            const SizedBox(width: gap),
                            SizedBox(
                              width: paneWidth,
                              child: const HadithSelectedDetailsPane(
                                hadith: hadith,
                                resultOrdinal: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Focus(
                        autofocus: true,
                        child: RecitationTransportControls(
                          isPlaying: false,
                          isLoading: false,
                          canPlay: playbackState.canPlay,
                          onPlayPause: () async {},
                          leftSlot: (
                            icon: FLucideIcons.skipBack,
                            label: l10n.quranRecitationPreviousSurah,
                            onPress: () async {},
                          ),
                          rightSlot: (
                            icon: FLucideIcons.skipForward,
                            label: l10n.quranRecitationNextSurah,
                            onPress: () async {},
                          ),
                          showSkip: false,
                          playbackSemanticsLabel: playbackLabel,
                          playbackTooltip: playbackLabel,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
