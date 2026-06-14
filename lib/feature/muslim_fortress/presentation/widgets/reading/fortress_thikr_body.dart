import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:hisn_elmoslem/hisn_elmoslem.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_dua_item.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/study/fortress_mushaf_pages.dart';
import 'package:tawaq/feature/muslim_fortress/presentation/widgets/study/fortress_quran_passage.dart';
import 'package:tawaq/feature/quran/domain/models/quran_text_scale.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';
import 'package:tawaq/gen/fonts.gen.dart';
import 'package:tawaq/theme/theme.dart';

const _kFortressAyahBaseFontSize = 32.0;

/// Renders thikr content with mushaf-backed Quranic passages.
class FortressThikrBody extends ConsumerWidget {
  /// Creates a thikr body.
  const FortressThikrBody({
    required this.dua,
    super.key,
    this.textAlign = TextAlign.center,
    this.proseStyle,
    this.muted = false,
  });

  /// The thikr to display.
  final FortressDuaItem dua;

  /// Text alignment for prose and ayah blocks.
  final TextAlign textAlign;

  /// Style for non-Quranic text.
  final TextStyle? proseStyle;

  /// Whether to use muted colors (e.g. completed state).
  final bool muted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quranTextScale = ref.watch(
      quranScreenSettingsProvider.select(
        (v) => v.value?.quranTextScale ?? QuranTextScale.medium,
      ),
    );
    final ayahFontSize = _kFortressAyahBaseFontSize * quranTextScale.boost;
    final theme = context.theme;
    final colors = theme.colors;

    final fallbackStyle =
        proseStyle ??
        theme.typography.xl3.copyWith(
          fontWeight: FontWeight.w600,
          height: 2,
          color: muted ? colors.mutedForeground : colors.foreground,
        );

    if (!dua.isQuranicPassage) {
      return Text(
        dua.text,
        style: fallbackStyle,
        textAlign: textAlign,
      );
    }

    final ayahColor = muted ? colors.mutedForeground : colors.foreground;
    final ayahStyle = TextStyle(color: ayahColor, height: 1.6);
    final loading = SizedBox(
      height: ayahFontSize * 1.6,
      child: const Center(child: FCircularProgress.loader()),
    );
    final error = Text(
      dua.text,
      style: fallbackStyle,
      textAlign: textAlign,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final line in dua.lines) ...[
          switch (line) {
            HisnPlainLine(:final text) when text.trim().isNotEmpty => Text(
              text,
              style: fallbackStyle,
              textAlign: textAlign,
            ),
            HisnQuranLine(:final presentation) => switch (presentation) {
              HisnQuranSingleAyah(:final range) => AyahWidget.fromSurahAyah(
                surah: range.surah,
                ayah: range.startAyah,
                fontSize: ayahFontSize,
                style: ayahStyle,
                loadingWidget: loading,
                errorWidget: error,
              ),
              HisnQuranMushafPages(:final pages) => FortressMushafPages(
                pages: pages,
                loadingWidget: loading,
              ),
              HisnQuranPassage(:final ranges) => FortressQuranPassage(
                ranges: ranges,
                fontSize: ayahFontSize,
                textStyle: ayahStyle,
                loadingWidget: loading,
                errorWidget: error,
              ),
            },
            _ => const SizedBox.shrink(),
          },
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

/// Compact thikr preview for category list tiles.
///
/// Quranic items use [dua.text] from the bundled Uthmani database with
/// [FontFamily.uthmanicHafs] (plain text, not mushaf page layout).
class FortressThikrPreview extends StatelessWidget {
  /// Creates a list-tile thikr preview.
  const FortressThikrPreview({
    required this.dua,
    required this.isExpanded,
    super.key,
  });

  final FortressDuaItem dua;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final isQuran = dua.isQuranicPassage;

    var style = theme.typography.sm.copyWith(
      color: theme.colors.mutedForeground,
      height: isQuran ? 2 : 1.6,
      fontSize: isQuran ? (isExpanded ? 22 : 20) : null,
    );
    if (isQuran) {
      style = style.copyWith(fontFamily: FontFamily.uthmanicHafs);
    }

    return Text(
      dua.text,
      style: style,
      textAlign: TextAlign.start,
      maxLines: isExpanded ? null : 2,
      overflow: isExpanded ? null : TextOverflow.ellipsis,
    );
  }
}
