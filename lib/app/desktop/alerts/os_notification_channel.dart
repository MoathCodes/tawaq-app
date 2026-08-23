import 'dart:async';

import 'package:local_notifier/local_notifier.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_alert_event.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_alert_channel.dart';

/// Shows a desktop OS notification via `local_notifier`.
class OsNotificationChannel implements PrayerAlertChannel {
  /// Creates an [OsNotificationChannel].
  ///
  /// [onClick] runs when the user clicks the notification body (typically to
  /// focus the alert window). [onStop] runs when the Stop action button is
  /// pressed (when [PrayerAlertEvent.osActionLabel] is set).
  new({
    required this.onClick,
    required this.onStop,
  });

  /// Invoked when the notification body is clicked.
  final Future<void> Function() onClick;

  /// Invoked when the Stop action button is pressed.
  final Future<void> Function() onStop;

  LocalNotification? _notification;

  @override
  String get debugName => 'os';

  @override
  Future<void> deliver(PrayerAlertEvent event) async {
    if (!event.showOsNotification) return;
    await cancel();

    final actionLabel = event.osActionLabel;
    final handleClick = onClick;
    final handleStop = onStop;
    // Per-kind/per-prayer identifier so distinct alerts never clobber one
    // another in the OS notification center.
    final notification =
        LocalNotification(
            identifier: 'tawaq-${event.slug}',
            title: event.osTitle ?? '',
            body: event.osBody ?? '',
            actions: actionLabel == null
                ? null
                : [LocalNotificationAction(text: actionLabel)],
          )
          ..onClick = () {
            unawaited(handleClick());
          }
          ..onClickAction = actionLabel == null
              ? null
              : (_) {
                  unawaited(handleStop());
                };

    _notification = notification;
    await notification.show();
  }

  @override
  Future<void> cancel() async {
    final notification = _notification;
    _notification = null;
    if (notification != null) await notification.close();
  }
}
