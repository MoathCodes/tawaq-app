import 'dart:async';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tawaq/core/desktop/adhan_alert_controller.dart';
import 'package:tawaq/core/desktop/adhan_alert_state.dart';
import 'package:tawaq/core/desktop/alerts/prayer_alert_dispatcher.dart';
import 'package:tawaq/core/locale/locale_extension.dart';
import 'package:tawaq/core/utils/platform.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_alert_kind.dart';
import 'package:tawaq/feature/prayer/domain/prayer_extensions.dart';
import 'package:tawaq/feature/settings/data/models/adhan_settings.dart';
import 'package:tawaq/feature/settings/presentation/provider/adhan_settings_provider.dart';

/// Shows an in-app prayer alert toast when the alert is in overlay mode.
class AdhanAlertToastListener extends ConsumerWidget {
  /// Creates [AdhanAlertToastListener].
  const AdhanAlertToastListener({required this.child, super.key});

  /// Wrapped shell content.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isDesktopPlatform) {
      ref.listen(adhanAlertControllerProvider, (previous, next) {
        final wasShowing = previous?.isShowing ?? false;
        if (!wasShowing && next.isShowing && !next.isCompactMorph) {
          _showToast(context, ref, next);
        }
      });
    }

    return child;
  }

  void _showToast(
    BuildContext context,
    WidgetRef ref,
    AdhanAlertState alert,
  ) {
    final kind = alert.kind;
    final prayer = alert.prayer;
    final scheduledTime = alert.scheduledTime;
    if (kind == null || prayer == null || scheduledTime == null) return;

    final l10n = context.l10n;
    final prayerName = prayer.getLocaleName(l10n);
    final timeLabel = DateFormat.Hm().format(scheduledTime);
    final settings = ref.read(adhanSettingsProvider).value;
    final alignment = _toastAlignment(
      settings?.alertPosition ?? AdhanAlertPosition.topEnd,
    );
    final title = switch (kind) {
      PrayerAlertKind.adhan => l10n.adhanAlertTitle(prayerName),
      PrayerAlertKind.iqamah => l10n.iqamahAlertTitle(prayerName),
      PrayerAlertKind.sunnah => l10n.sunnahAlertTitle(prayerName),
    };

    final entry = showFToast(
      context: context,
      alignment: alignment,
      duration: null,
      swipeToDismiss: const [],
      icon: Icon(FLucideIcons.bellRing, color: context.theme.colors.primary),
      title: Text(title),
      description: Text(timeLabel),
      suffixBuilder: (context, toastEntry) => FButton(
        variant: .secondary,
        onPress: () {
          unawaited(
            ref.read(prayerAlertDispatcherProvider.notifier).dismiss(),
          );
        },
        child: Text(
          alert.playsSound ? l10n.adhanStop : l10n.prayerAlertDismiss,
        ),
      ),
    );

    ref.read(adhanAlertControllerProvider.notifier).registerToastEntry(entry);
  }

  FToastAlignment _toastAlignment(AdhanAlertPosition position) {
    return switch (position) {
      AdhanAlertPosition.topEnd => FToastAlignment.topEnd,
      AdhanAlertPosition.topStart => FToastAlignment.topStart,
      AdhanAlertPosition.center => FToastAlignment.topCenter,
    };
  }
}
