import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_judgment.dart';
import 'package:tawaq/theme/theme.dart';

/// Prominent source wording; the SDK's observed highlight owns semantic tone.
class HadithSourceRuling extends StatelessWidget {
  const HadithSourceRuling({
    required this.hukm,
    this.tone = VerdictTone.unmarked,
    this.label,
    this.fontSize,
    this.fitContent = false,
    super.key,
  });
  final String hukm;
  final VerdictTone tone;
  final String? label;
  final double? fontSize;
  final bool fitContent;
  @override
  Widget build(BuildContext context) {
    if (!hasHadithMetadata(hukm)) return const SizedBox.shrink();
    final theme = context.theme;
    final dark = theme.colors.brightness == Brightness.dark;
    final saturation = HSLColor.fromColor(theme.colors.primary).saturation
        .clamp(.30, .55);
    var foreground = switch (tone) {
      VerdictTone.positive => HSLColor.fromAHSL(
        1,
        150,
        saturation,
        dark ? .72 : .25,
      ).toColor(),
      VerdictTone.negative => theme.colors.destructive,
      VerdictTone.unmarked => theme.colors.foreground,
    };
    var background = tone == VerdictTone.unmarked
        ? theme.colors.secondary
        : Color.alphaBlend(
            foreground.withValues(alpha: dark ? .10 : .07),
            theme.colors.card,
          );
    // Tinting a surface reduces token contrast. Keep the theme hue and adjust
    // only its lightness against the surface that will actually be painted.
    double contrast(Color a, Color b) {
      final x = a.computeLuminance();
      final y = b.computeLuminance();
      return ((x > y ? x : y) + .05) / ((x < y ? x : y) + .05);
    }

    for (
      var step = 0;
      tone != VerdictTone.unmarked &&
          contrast(foreground, background) < 4.6 &&
          step < 30;
      step++
    ) {
      final color = HSLColor.fromColor(foreground);
      foreground = color
          .withLightness((color.lightness + (dark ? .015 : -.015)).clamp(0, 1))
          .toColor();
      background = Color.alphaBlend(
        foreground.withValues(alpha: dark ? .10 : .07),
        theme.colors.card,
      );
    }
    return Container(
      key: ValueKey('hadith-ruling-${tone.name}'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: theme.radii.md,
      ),
      child: Row(
        mainAxisSize: fitContent ? MainAxisSize.min : MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tone != VerdictTone.unmarked) ...[
            ExcludeSemantics(
              child: Icon(
                tone == VerdictTone.negative
                    ? FLucideIcons.triangleAlert
                    : FLucideIcons.circleCheck,
                size: 19,
                color: foreground,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            fit: fitContent ? FlexFit.loose : FlexFit.tight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label ?? context.l10n.hadithScholarRuling,
                  style: theme.typography.body.xs.copyWith(
                    color: foreground,
                    fontSize: fontSize == null ? null : 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hukm,
                  softWrap: true,
                  textDirection: TextDirection.rtl,
                  style: theme.typography.body.md.copyWith(
                    color: foreground,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    height: 1.65,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
