import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/feature/quran/domain/services/ayah_share_logic.dart';
import 'package:tawaq/feature/quran/presentation/models/ayah_share_ui.dart';
import 'package:tawaq/theme/theme.dart';

/// Card rendered with mushaf typography for sharing as an image.
class AyahShareCard extends StatelessWidget {
  /// Creates a share card.
  const AyahShareCard({
    required this.boundaryKey,
    required this.page,
    required this.ayahIds,
    required this.style,
    required this.showSurahHeader,
    required this.showBasmalah,
    required this.showAppName,
    required this.appName,
    required this.isDark,
    super.key,
  });

  /// Key attached to the internal [RepaintBoundary] for image capture.
  final GlobalKey boundaryKey;

  /// Page model used to resolve surah blocks and glyph text.
  final QuranPage page;

  /// Ayah IDs to include, in reading order.
  final List<int> ayahIds;

  /// Mushaf styling aligned with the Quran reader.
  final MushafStyle style;

  /// Whether to show the decorative surah header above the verses.
  final bool showSurahHeader;

  /// Whether to show the basmalah when the model allows it.
  final bool showBasmalah;

  /// Whether to show the app name below the verses.
  final bool showAppName;

  /// Localized app name shown in the footer.
  final String appName;

  /// Whether to use the dark surah banner variant.
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    final scale = style.scale;
    final ayahFontSize = scale.getAyahFontSize(1);
    final basmalahFontSize = scale.getBasmalahFontSize(1);
    final ayahStyle = MushafTextStyleMerger.mergeAyahStyle(
      userStyle: style.ayahStyle,
      modifier: style.ayahStyleModifier,
      pageNumber: page.pageNumber,
      baseSize: ayahFontSize,
    );
    const horizontalPadding = AppSpacing.xl;
    const contentWidth = kAyahShareCardWidth - (horizontalPadding * 2);
    final selectedIds = ayahIds.toSet();

    final card = Container(
      width: kAyahShareCardWidth,
      padding: const EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: style.backgroundColor ?? colors.background,
        borderRadius: context.theme.radii.lg,
        border: Border.all(color: colors.border, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final block in page.surahs) ...[
            if (showSurahHeader &&
                AyahShareLogic.shouldShowShareSurahHeader(block, selectedIds))
              ...[
              SurahHeaderWidget(
                surahData: Surah(
                  number: block.surahNumber,
                  glyph: block.glyph,
                  hasBasmalah: block.hasBasmalah,
                ),
                width: contentWidth,
                fontSize: basmalahFontSize,
                textStyle: style.headerSurahNameStyle ?? style.surahNameStyle,
                styleModifier: style.headerSurahNameStyleModifier ??
                    style.surahNameStyleModifier,
                customHeaderImage: style.surahHeaderImage,
                isDark: isDark,
              ),
              SizedBox(height: 12 * scale.readingBoost.clamp(0.85, 1.15)),
            ],
            if (showBasmalah &&
                AyahShareLogic.shouldShowShareBasmalah(block, selectedIds)) ...[
              BasmalahWidget(
                fontSize: basmalahFontSize,
                textStyle: style.basmalahStyle,
                styleModifier: style.basmalahStyleModifier,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            ..._buildBlockAyahs(
              block: block,
              selectedIds: selectedIds,
              ayahStyle: ayahStyle,
            ),
          ],
          if (showAppName) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              appName,
              textAlign: TextAlign.center,
              style: typography.sm.copyWith(
                color: colors.mutedForeground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );

    return RepaintBoundary(key: boundaryKey, child: card);
  }

  List<Widget> _buildBlockAyahs({
    required SurahBlock block,
    required Set<int> selectedIds,
    required TextStyle ayahStyle,
  }) {
    final fragments = block.ayahs
        .where((fragment) => selectedIds.contains(fragment.ayahId))
        .toList();
    if (fragments.isEmpty) return const [];

    return [
      PageAyahWidget(
        fullText: page.glyphText,
        ayahs: fragments,
        style: ayahStyle,
        enableHighlight: false,
        activeStyle: ayahStyle,
        removeNewLines: AyahShareLogic.shouldRemoveNewLinesForBlock(
          page,
          block,
          selectedIds,
        ),
        onAyahSelection: (_) {},
      ),
    ];
  }
}
