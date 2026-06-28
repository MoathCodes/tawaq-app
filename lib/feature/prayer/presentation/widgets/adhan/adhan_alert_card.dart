import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/desktop/alerts/prayer_alert_dispatcher.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/adhan/prayer_alert_banner.dart';
import 'package:tawaq/theme/theme.dart';

/// Forui card shown during prayer alert presentation.
class AdhanAlertCard extends HookConsumerWidget {
  /// Creates [AdhanAlertCard].
  const AdhanAlertCard({
    this.showCloseButton = false,
    super.key,
  });

  /// Whether to show a dismiss control in the title row (overlay mode).
  final bool showCloseButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.theme;
    final colors = theme.colors;

    Future<void> dismiss() =>
        ref.read(prayerAlertDispatcherProvider.notifier).dismiss();

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
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: theme.radii.lg,
          border: Border.all(color: colors.primary.withValues(alpha: 0.45)),
          boxShadow: [
            BoxShadow(
              color: colors.barrier.withValues(alpha: 0.28),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: theme.radii.lg,
          child: PrayerAlertBanner(showCloseButton: showCloseButton),
        ),
      ),
    );
  }
}
