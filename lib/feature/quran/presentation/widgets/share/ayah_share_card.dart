import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:mushaf_reader/mushaf_reader.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/quran/presentation/models/ayah_share_ui.dart';
import 'package:tawaq/gen/assets.gen.dart';
import 'package:tawaq/theme/theme.dart';

const _kShareAttributionIconSize = 32.0;
const _kShareAttributionFade = 0.7;

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
    required this.preserveMushafLineBreaks,
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

  /// Whether to keep mushaf line breaks for partial-page selections.
  final bool preserveMushafLineBreaks;

  /// Whether to use the dark surah banner variant.
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    final l10n = context.l10n;
    final radii = context.theme.radii;
    final attributionStyle = typography.xs.copyWith(
      color: colors.mutedForeground.withValues(alpha: _kShareAttributionFade),
      fontWeight: FontWeight.w500,
    );

    return RepaintBoundary(
      key: boundaryKey,
      child: Container(
        width: kAyahShareCardWidth,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
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
            MushafPageRange.onPage(
              page: page.pageNumber,
              startAyahId: ayahIds.first,
              endAyahId: ayahIds.last,
              pageData: page,
              style: style,
              showSurahHeader: showSurahHeader,
              showBasmalah: showBasmalah,
              preserveMushafLineBreaks: preserveMushafLineBreaks,
              isDark: isDark,
            ),
            if (showAppName) ...[
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: AppSpacing.xs,
                  children: [
                    Opacity(
                      opacity: _kShareAttributionFade,
                      child: ClipRRect(
                        borderRadius: radii.xs,
                        child: Assets.images.appIcon.image(
                          width: _kShareAttributionIconSize,
                          height: _kShareAttributionIconSize,
                          fit: BoxFit.cover,
                          cacheWidth:
                              (_kShareAttributionIconSize *
                                      MediaQuery.devicePixelRatioOf(context))
                                  .round(),
                          cacheHeight:
                              (_kShareAttributionIconSize *
                                      MediaQuery.devicePixelRatioOf(context))
                                  .round(),
                        ),
                      ),
                    ),
                    Text(l10n.shareAttributionPrefix, style: attributionStyle),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
