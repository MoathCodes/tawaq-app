import 'package:adhan_dart/adhan_dart.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_alert_kind.dart';

/// Visible prayer alert state exposed to UI.
class AdhanAlertState {
  /// Creates [AdhanAlertState].
  const AdhanAlertState({
    required this.kind,
    required this.prayer,
    required this.scheduledTime,
    required this.isCompactMorph,
    required this.playsSound,
  });

  /// No active alert.
  const AdhanAlertState.idle()
    : kind = null,
      prayer = null,
      scheduledTime = null,
      isCompactMorph = false,
      playsSound = false;

  /// Alert category, if any.
  final PrayerAlertKind? kind;

  /// Prayer being announced, if any.
  final Prayer? prayer;

  /// Scheduled time for display.
  final DateTime? scheduledTime;

  /// Whether the main window was morphed into a compact alert card.
  final bool isCompactMorph;

  /// Whether audio playback is expected for this alert.
  final bool playsSound;

  /// Whether an alert is currently shown.
  bool get isShowing => prayer != null;
}
