import 'package:tawaq/feature/prayer/domain/models/prayer_alert_event.dart';

/// A single delivery surface for a [PrayerAlertEvent] (sound, in-app overlay,
/// OS notification, …).
///
/// Channels are intentionally dumb: they present or play when told to and tear
/// down when told to. Ordering, preemption, and completion are coordinated by
/// the dispatcher, so adding a new channel never touches scheduling logic.
abstract interface class PrayerAlertChannel {
  /// Short identifier for logging.
  String get debugName;

  /// Presents/plays [event] on this channel. A no-op when the event does not
  /// target this channel.
  Future<void> deliver(PrayerAlertEvent event);

  /// Tears down anything [deliver] started. Safe to call when idle.
  Future<void> cancel();
}
