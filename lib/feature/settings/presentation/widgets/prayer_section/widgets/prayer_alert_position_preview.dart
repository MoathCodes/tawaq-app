import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/utils/reduce_motion.dart';
import 'package:tawaq/feature/prayer/domain/models/adhan_settings.dart';
import 'package:tawaq/theme/theme.dart';

/// Inert miniature of the native window. Uses its physical position mapping.
class PrayerAlertPositionPreview extends StatelessWidget {
  const new({required this.position, required this.enabled, super.key});
  final AdhanAlertPosition position;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colors = theme.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.sm,
      children: [
        Semantics(
          label: context.l10n.alertPositionPreview,
          child: Container(
            height: 156,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: colors.muted,
              borderRadius: theme.radii.lg,
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                Row(
                  spacing: AppSpacing.xs,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: colors.mutedForeground.withValues(alpha: .4),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: AnimatedAlign(
                    alignment: Alignment(
                      position.horizontalFraction * 2 - 1,
                      position.verticalFraction * 2 - 1,
                    ),
                    duration: reduceMotion(context)
                        ? Duration.zero
                        : theme.durations.normal,
                    curve: Curves.easeOut,
                    child: Opacity(
                      opacity: enabled ? 1 : .5,
                      child: Container(
                        key: const ValueKey('prayer-alert-position-card'),
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: colors.card,
                          borderRadius: theme.radii.md,
                          border: Border.all(color: colors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: AppSpacing.sm,
                          children: [
                            Icon(
                              FLucideIcons.bell,
                              size: 16,
                              color: colors.primary,
                            ),
                            Text(
                              context.l10n.alertPositionPreview,
                              style: theme.typography.body.xs,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!enabled)
          Text(
            context.l10n.alertPositionPreviewDisabled,
            style: theme.typography.body.sm.copyWith(
              color: colors.mutedForeground,
            ),
          ),
      ],
    );
  }
}
