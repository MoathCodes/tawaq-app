import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/quran/domain/services/ayah_reference_logic.dart';
import 'package:tawaq/feature/quran/presentation/widgets/selectors/quran_division_ordinals.dart';
import 'package:tawaq/feature/quran/presentation/widgets/surah_name_text.dart';
import 'package:tawaq/gen/fonts.gen.dart';
import 'package:tawaq/l10n/app_localizations.dart';
import 'package:tawaq/theme/theme.dart';

/// Renders a Juz QCF4 glyph using the mushaf basmalah font.
class JuzNameText extends StatelessWidget {
  /// Creates a [JuzNameText].
  const JuzNameText(
    this.glyph, {
    this.style,
    this.fontSize = 36,
    super.key,
  });

  /// QCF4-encoded Juz marker glyph.
  final String glyph;

  /// Optional base style; [fontSize] overrides size when set.
  final TextStyle? style;

  /// Glyph size in logical pixels.
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        glyph,
        textDirection: TextDirection.rtl,
        style: (style ?? const TextStyle()).copyWith(
          fontFamily: 'QCF4_BSML',
          package: 'mushaf_reader',
          fontSize: fontSize,
        ),
      ),
    );
  }
}

/// Renders a Surah QCF4 name glyph for Arabic Juz subtitles.
class SurahGlyphText extends StatelessWidget {
  /// Creates a [SurahGlyphText].
  const SurahGlyphText(
    this.glyph, {
    this.style,
    this.fontSize = 28,
    super.key,
  });

  /// QCF4-encoded surah name glyph.
  final String glyph;

  /// Optional base style.
  final TextStyle? style;

  /// Glyph size in logical pixels.
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        glyph,
        textDirection: TextDirection.rtl,
        style: (style ?? const TextStyle()).copyWith(
          fontFamily: 'QCF4_BSML',
          package: 'mushaf_reader',
          fontSize: fontSize,
        ),
      ),
    );
  }
}

/// Division kind for [QuranDivisionSelectItem].
enum QuranDivisionKind {
  /// A Juz (1–30).
  juz,

  /// A Hizb (1–60).
  hizb,
}

/// Shared FSelect tile layout for Juz and Hizb pickers.
abstract final class QuranDivisionSelectItem {
  /// Title row for a division list item or closed field preview.
  static Widget title({
    required BuildContext context,
    required QuranDivisionKind kind,
    required int number,
    String? juzGlyph,
    TextStyle? style,
  }) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return switch (kind) {
      QuranDivisionKind.juz => _juzTitle(
        isArabic: isArabic,
        number: number,
        glyph: juzGlyph ?? '',
        style: style,
      ),
      QuranDivisionKind.hizb => Text(
        localizedHizbTitle(number, isArabic: isArabic),
        style: style,
      ),
    };
  }

  /// Subtitle row (start surah reference or Uthmani ayah preview).
  static Widget subtitle({
    required BuildContext context,
    required QuranDivisionKind kind,
    required MushafReaderController controller,
    int? startSurahNumber,
    int? startAyahInSurah,
    String? startAyahUthmaniText,
  }) {
    final theme = context.theme;
    final l10n = context.l10n;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final subtitleStyle = theme.typography.body.sm.copyWith(
      color: theme.colors.mutedForeground,
    );

    return switch (kind) {
      QuranDivisionKind.juz => _juzSubtitle(
        controller: controller,
        isArabic: isArabic,
        l10n: l10n,
        startSurahNumber: startSurahNumber,
        startAyahInSurah: startAyahInSurah,
        style: subtitleStyle,
      ),
      QuranDivisionKind.hizb => _hizbSubtitle(
        controller: controller,
        isArabic: isArabic,
        l10n: l10n,
        startSurahNumber: startSurahNumber,
        startAyahInSurah: startAyahInSurah,
        startAyahUthmaniText: startAyahUthmaniText,
        style: subtitleStyle,
      ),
    };
  }

  static Widget _juzTitle({
    required bool isArabic,
    required int number,
    required String glyph,
    TextStyle? style,
  }) {
    if (isArabic) {
      return Text(
        localizedJuzNumericLabel(number, isArabic: true),
        textDirection: TextDirection.rtl,
        style: (style ?? const TextStyle()).copyWith(
          fontFamily: FontFamily.uthmanicHafs,
        ),
      );
    }

    if (glyph.isNotEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          JuzNameText(glyph, style: style, fontSize: 28),
          const SizedBox(width: AppSpacing.sm),
          Text(englishJuzLabel(number), style: style),
        ],
      );
    }
    return Text(englishJuzLabel(number), style: style);
  }

  static Widget _juzSubtitle({
    required MushafReaderController controller,
    required bool isArabic,
    required AppLocalizations l10n,
    required int? startSurahNumber,
    required int? startAyahInSurah,
    required TextStyle style,
  }) {
    if (startSurahNumber == null || startAyahInSurah == null) {
      return const SizedBox.shrink();
    }

    final surah = controller.getSurahSync(startSurahNumber);
    if (isArabic) {
      final glyph = surah?.glyph;
      if (glyph != null && glyph.isNotEmpty) {
        return SurahGlyphText(glyph, style: style, fontSize: 24);
      }
      final surahName = AyahReferenceLogic.surahName(
        surah,
        startSurahNumber,
        preferArabic: true,
        fallbackName: l10n.surahNameDefault(startSurahNumber),
      );
      return SurahNameText(surahName, style: style);
    }

    final surahName = AyahReferenceLogic.surahName(
      surah,
      startSurahNumber,
      preferArabic: false,
      fallbackName: l10n.surahNameDefault(startSurahNumber),
    );
    return Text(
      l10n.surahAyahInfo(surahName, startAyahInSurah),
      style: style,
    );
  }

  static Widget _hizbSubtitle({
    required MushafReaderController controller,
    required bool isArabic,
    required AppLocalizations l10n,
    required int? startSurahNumber,
    required int? startAyahInSurah,
    required String? startAyahUthmaniText,
    required TextStyle style,
  }) {
    final uthmani = startAyahUthmaniText?.trim();
    if (uthmani == null || uthmani.isEmpty) {
      return const SizedBox.shrink();
    }

    final uthmaniWidget = Text(
      uthmani,
      style: style.copyWith(fontFamily: FontFamily.uthmanicHafs),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textDirection: TextDirection.rtl,
    );

    if (isArabic) return uthmaniWidget;

    if (startSurahNumber == null || startAyahInSurah == null) {
      return uthmaniWidget;
    }

    final surah = controller.getSurahSync(startSurahNumber);
    final surahName = AyahReferenceLogic.surahName(
      surah,
      startSurahNumber,
      preferArabic: false,
      fallbackName: l10n.surahNameDefault(startSurahNumber),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.surahAyahInfo(surahName, startAyahInSurah),
          style: style,
        ),
        const SizedBox(height: AppSpacing.xs),
        uthmaniWidget,
      ],
    );
  }
}
