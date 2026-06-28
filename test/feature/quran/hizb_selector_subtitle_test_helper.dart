import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/hizb_selector.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/app_theme_builder.dart';
import 'package:tawaq/theme/theme_model.dart';

/// Test helper: builds the hizb tile subtitle widget in a themed shell.
Widget hizbSelectorStartAyahSubtitleForTest({
  required Hizb hizb,
  required MushafReaderController controller,
  required bool isArabic,
  required AppLocalizations l10n,
  required String fallbackSurahName,
}) {
  final appTheme = buildAppTheme(
    palette: AppPalette.zinc,
    themeMode: ThemeMode.light,
    touch: false,
    textScale: 1,
  );

  return FTheme(
    data: appTheme,
    child: MaterialApp(
      locale: Locale(isArabic ? 'ar' : 'en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => hizbSelectSubtitle(
          context: context,
          controller: controller,
          startSurahNumber: hizb.startSurahNumber,
          startAyahInSurah: hizb.startAyahInSurah,
          startAyahUthmaniText: hizb.startAyahUthmaniText,
        ),
      ),
    ),
  );
}
