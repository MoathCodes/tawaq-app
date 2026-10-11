import 'package:adhan_dart/adhan_dart.dart';
import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/utils/prayer_extensions.dart';
import 'package:tawaq/core/utils/reduce_motion.dart';
import 'package:tawaq/feature/prayer/domain/models/adhan_settings.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_alert_kind.dart';
import 'package:tawaq/feature/prayer/presentation/prayer_alert_copy.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/prayer_alert_card.dart';
import 'package:tawaq/theme/theme.dart';

/// An inert example using exactly the live notification's presentation.
class PrayerAlertPositionPreview extends StatelessWidget {
  const new({required this.position, required this.enabled, super.key});
  final AdhanAlertPosition position;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.sm,
      children: [
        Text(l10n.alertPositionPreview, style: theme.typography.body.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 200),
          child: AnimatedAlign(
            alignment: Alignment(
              position.horizontalFraction * 2 - 1,
              position.verticalFraction * 2 - 1,
            ),
            duration: reduceMotion(context)
                ? Duration.zero
                : theme.durations.normal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: IgnorePointer(
                child: ExcludeFocus(
                  child: Opacity(
                    opacity: enabled ? 1 : .5,
                    child: PrayerAlertCard(
                      prayer: Prayer.fajr,
                      title: prayerAlertTitle(
                        l10n,
                        PrayerAlertKind.adhan,
                        Prayer.fajr.getLocaleName(l10n),
                      ),
                      timeLabel: '05:00',
                      showCloseButton: true,
                      showPlayback: true,
                      progress: .4,
                      onDismiss: () async {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (!enabled)
          Text(
            l10n.alertPositionPreviewDisabled,
            style: theme.typography.body.sm.copyWith(
              color: theme.colors.mutedForeground,
            ),
          ),
      ],
    );
  }
}
