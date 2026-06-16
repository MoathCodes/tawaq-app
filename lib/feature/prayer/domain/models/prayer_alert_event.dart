import 'package:adhan_dart/adhan_dart.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_alert_kind.dart';

/// A fully-resolved prayer alert ready to be delivered across channels.
///
/// All locale-dependent strings are resolved by the scheduler before
/// construction so delivery channels stay free of presentation concerns and a
/// single place owns the wording.
class PrayerAlertEvent {
  /// Creates a [PrayerAlertEvent].
  const PrayerAlertEvent({
    required this.kind,
    required this.prayer,
    required this.scheduledTime,
    required this.playSound,
    required this.showInApp,
    required this.showOsNotification,
    required this.volume,
    this.soundAssetPath,
    this.soundTitle,
    this.soundSubtitle,
    this.osTitle,
    this.osBody,
  });

  /// Alert category.
  final PrayerAlertKind kind;

  /// Prayer this alert belongs to.
  final Prayer prayer;

  /// Local scheduled time for the event.
  final DateTime scheduledTime;

  /// Whether bundled audio should play.
  final bool playSound;

  /// Whether the in-app overlay / compact morph should show.
  final bool showInApp;

  /// Whether an OS notification should show.
  final bool showOsNotification;

  /// Output volume (0-100) for the sound channel.
  final double volume;

  /// Bundled asset path when [playSound] is true.
  final String? soundAssetPath;

  /// Media-session title for the playing track.
  final String? soundTitle;

  /// Media-session subtitle (typically the prayer name).
  final String? soundSubtitle;

  /// OS notification title.
  final String? osTitle;

  /// OS notification body.
  final String? osBody;

  /// Whether any channel is active for this event.
  bool get hasAnyEffect => playSound || showInApp || showOsNotification;

  /// Stable identifier used for track ids and notification ids.
  String get slug => '${kind.name}-${prayer.name}';
}
