import 'package:flutter/material.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:mushaf_reader/src/core/extensions.dart';
import 'package:mushaf_reader/src/core/mushaf_page_range_layout.dart';
import 'package:mushaf_reader/src/presentation/widgets/page_ayah_widget.dart';

/// Shared surah-block rendering for [MushafPage] and [MushafPageRange].
abstract final class MushafPageSurahBlocks {
  /// Builds surah headers, optional basmalah, and ayah text for [data].
  static Iterable<Widget> build({
    required QuranPage data,
    required int pageNumber,
    required double width,
    required double scale,
    required TextStyle defaultAyahStyle,
    required TextStyle activeStyle,
    required MushafStyle mushafStyle,
    required double basmalahFontSize,
    bool? isDark,
    Set<int>? selectedAyahIds,
    bool showSurahHeader = true,
    bool showBasmalah = true,
    bool preserveMushafLineBreaks = false,
    bool enableAyahHighlight = false,
    int? selectedAyahId,
    void Function(int ayahId)? onAyahSelection,
    AyahIdLongPressCallback? onAyahLongPress,
    SurahTapCallback? onTapSurahHeader,
    SurahTapCallback? onLongPressSurahHeader,
    bool addTrailingSpacer = true,
    IQuranRepository? repository,
    String? basmalahGlyph,
  }) {
    final isRangeMode = selectedAyahIds != null;
    final selectedIds = selectedAyahIds ?? const <int>{};

    return data.surahs.expand((block) {
      final fragments = isRangeMode
          ? MushafPageRangeLayout.fragmentsForSelection(block, selectedIds)
          : block.ayahs;
      if (fragments.isEmpty) return const <Widget>[];

      final widgets = <Widget>[];

      final renderSurahHeader = isRangeMode
          ? showSurahHeader &&
                MushafPageRangeLayout.shouldShowSurahHeader(block, selectedIds)
          : block.hasBasmalah;

      if (renderSurahHeader) {
        widgets.addAll([
          SurahHeaderWidget(
            surahData: block.toSurah(),
            width: width,
            fontSize: basmalahFontSize,
            textStyle:
                mushafStyle.headerSurahNameStyle ?? mushafStyle.surahNameStyle,
            styleModifier:
                mushafStyle.headerSurahNameStyleModifier ??
                mushafStyle.surahNameStyleModifier,
            customHeaderImageLight: mushafStyle.surahHeaderImage,
            customHeaderImageDark: mushafStyle.surahHeaderImageDark,
            isDark: isDark,
            onTap: onTapSurahHeader,
            onLongPress: onLongPressSurahHeader,
          ),
          SizedBox(height: 12 * scale),
        ]);
      }

      final renderBasmalah = isRangeMode
          ? showBasmalah &&
                MushafPageRangeLayout.shouldShowBasmalah(block, selectedIds)
          : block.hasBasmalah &&
                block.surahNumber != 9 &&
                block.surahNumber != 1;

      if (renderBasmalah) {
        widgets.add(
          BasmalahWidget(
            fontSize: basmalahFontSize,
            textStyle: mushafStyle.basmalahStyle,
            styleModifier: mushafStyle.basmalahStyleModifier,
            glyph: basmalahGlyph,
            repository: repository,
          ),
        );
      }

      final compactNewlines = isRangeMode &&
          !preserveMushafLineBreaks &&
          MushafPageRangeLayout.shouldCompactNewlines(
            data,
            block,
            selectedIds,
          );

      widgets.add(
        PageAyahWidget(
          fullText: data.glyphText,
          ayahs: fragments,
          style: defaultAyahStyle,
          enableHighlight: enableAyahHighlight,
          activeStyle: activeStyle,
          selectedAyahId: enableAyahHighlight ? selectedAyahId : null,
          removeNewLines: compactNewlines,
          onAyahSelection: onAyahSelection,
          onAyahLongPress: enableAyahHighlight ? onAyahLongPress : null,
        ),
      );

      if (addTrailingSpacer && data.surahs.last == block) {
        widgets.add(const Spacer());
      }

      return widgets;
    });
  }
}
