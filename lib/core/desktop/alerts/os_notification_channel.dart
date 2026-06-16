import 'dart:async';

import 'package:local_notifier/local_notifier.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_alert_event.dart';
import 'package:tawaq/feature/prayer/domain/services/prayer_alert_channel.dart';

/// Shows a desktop OS notification via `local_notifier`.
class OsNotificationChannel implements PrayerAlertChannel {
  /// Creates an [OsNotificationChannel]. [onClick] runs when the user clicks
  /// the notification (typically to focus the alert window).
  OsNotificationChannel({required this.onClick});

  /// Invoked when the notification is clicked.
  final Future<void> Function() onClick;

  LocalNotification? _notification;

  @override
  String get debugName => 'os';

  @override
  Future<void> deliver(PrayerAlertEvent event) async {
    if (!event.showOsNotification) return;
    await cancel();

    // Per-kind/per-prayer identifier so distinct alerts never clobber one
    // another in the OS notification center.
    final notification = LocalNotification(
      identifier: 'tawaq-${event.slug}',
      title: event.osTitle ?? '',
      body: event.osBody ?? '',
    )..onClick = () => unawaited(onClick());

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
