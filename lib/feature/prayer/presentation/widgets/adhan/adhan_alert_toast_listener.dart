import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tawaq/core/desktop/adhan_alert_controller.dart';
import 'package:tawaq/core/desktop/adhan_alert_state.dart';
import 'package:tawaq/core/utils/platform.dart';
import 'package:tawaq/feature/prayer/presentation/widgets/adhan/prayer_alert_banner.dart';
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

    final settings = ref.read(adhanSettingsProvider).value;
    final alignment = _toastAlignment(
      settings?.alertPosition ?? AdhanAlertPosition.topEnd,
    );

    final entry = showRawFToast(
      context: context,
      alignment: alignment,
      duration: null,
      swipeToDismiss: const [],
      builder: (context, toastEntry) => PrayerAlertBanner(compact: true),
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
