import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/feature/hadith/domain/models/hadith_judgment.dart';
import 'package:tawaq/theme/theme.dart';

/// Badge showing the hadith grading (hukm).
class HadithHukmBadge extends StatelessWidget {
  /// Creates a [HadithHukmBadge].
  const new({required this.hukm, this.tone, super.key});

  /// The grading text.
  final String hukm;

  /// Emphasis considering both short and expanded source rulings, if provided.
  final HadithJudgmentTone? tone;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    final judgment = hukm.trim();
    final resolvedTone = tone ?? hadithJudgmentTone(hukm);
    final warning = resolvedTone != HadithJudgmentTone.neutral;
    final tint = resolvedTone == HadithJudgmentTone.chainWarning ? 0.07 : 0.13;

    final background = warning
        ? Color.alphaBlend(
            colors.destructive.withValues(alpha: tint),
            colors.card,
          )
        : colors.card;
    final ink = warning
        ? _readableWarningInk(colors.destructive, colors.foreground, background)
        : colors.foreground;

    if (!hasHadithMetadata(judgment)) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          constraints: BoxConstraints(maxWidth: constraints.maxWidth),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: theme.radii.md,
            border: Border.all(
              color: warning
                  ? colors.destructive.withValues(alpha: 0.35)
                  : colors.border,
            ),
          ),
          child: Text(
            hukm,
            style: theme.typography.body.sm.copyWith(
              color: ink,
              fontWeight: FontWeight.w600,
            ),
            softWrap: true,
          ),
        );
      },
    );
  }
}

// A tinted warning plane needs its own readable ink, especially in light mode.
// Stay in the theme's destructive hue, mixing toward its readable foreground
// only as much as necessary for normal-sized source text.
Color _readableWarningInk(Color destructive, Color foreground, Color surface) {
  final background = surface.computeLuminance();
  for (var step = 0; step <= 10; step++) {
    final ink = Color.lerp(destructive, foreground, step / 10)!;
    final light = ink.computeLuminance();
    final ratio =
        ((light > background ? light : background) + .05) /
        ((light < background ? light : background) + .05);
    if (ratio >= 4.5) return ink;
  }
  return foreground;
}
