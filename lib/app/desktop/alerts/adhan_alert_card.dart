import 'dart:async';

import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tawaq/app/desktop/alerts/prayer_alert_dispatcher.dart';
import 'package:tawaq/core/audio/audio_lease.dart';
import 'package:tawaq/core/audio/audio_player_provider.dart';
import 'package:tawaq/core/audio/playback_state.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/utils/prayer_extensions.dart';
import 'package:tawaq/feature/prayer/presentation/prayer_alert_copy.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/prayer_alert_card.dart';

/// Forui card shown during prayer alert presentation.
class AdhanAlertCard extends ConsumerWidget {
  /// Creates [AdhanAlertCard].
  const new({this.showCloseButton = false, super.key});

  /// Whether to show a dismiss control in the title row (overlay mode).
  final bool showCloseButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alert = ref.watch(prayerAlertSessionStateProvider);
    if (alert == null) {
      return const SizedBox.shrink();
    }
    final kind = alert.event.kind;
    final prayer = alert.event.prayer;
    final scheduledTime = alert.event.scheduledTime;

    final l10n = context.l10n;
    final prayerName = prayer.getLocaleName(l10n);
    final timeLabel = DateFormat.Hm().format(scheduledTime);
    final title = prayerAlertTitle(l10n, kind, prayerName);
    final audioSession = ref.watch(audioSessionProvider);
    // Only mirror progress while adhan owns the shared player — otherwise the
    // bar reads stale recitation position/duration (often near EOF → full).
    final adhanOwnsPlayer = audioSession.owner == kAdhanLeaseOwner;
    final showPlayback =
        alert.event.playSound &&
        adhanOwnsPlayer &&
        audioSession.lifecycle != AudioSessionLifecycle.idle &&
        audioSession.lifecycle != AudioSessionLifecycle.error;
    final maxMs = audioSession.duration.inMilliseconds;
    final progress = maxMs <= 0
        ? 0.0
        : (audioSession.position.inMilliseconds / maxMs).clamp(0.0, 1.0);

    Future<void> dismiss() =>
        ref.read(prayerAlertDispatcherProvider.notifier).dismiss();

    final card = PrayerAlertCard(
      prayer: prayer,
      title: title,
      timeLabel: timeLabel,
      compact: alert.isCompactMorph,
      showCloseButton: showCloseButton,
      showPlayback: showPlayback,
      progress: progress,
      onDismiss: dismiss,
    );
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          unawaited(dismiss());
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: card,
    );
  }
}
