import 'package:tawaq/feature/prayer/data/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/presentation/extensions/completion_status_ui.dart';
import 'package:tawaq/l10n/app_localizations.dart';

/// Composes screen-reader labels for prayer UI from existing
/// [AppLocalizations] keys.
///
/// Labels are built once per widget build from values already on screen models.
abstract final class PrayerSemantics {
  PrayerSemantics._();

  /// Label for an expandable schedule row (name, times, status, action hint).
  static String scheduleRow({
    required AppLocalizations l10n,
    required String prayerName,
    required String adhanTime,
    required CompletionStatus status,
    required bool isCurrentPrayer,
    required bool isExpanded,
    String? iqamahTime,
    String? relativeSubtitle,
  }) {
    final parts = <String>[prayerName];

    if (isCurrentPrayer) {
      parts.add(l10n.currentPrayer);
    }

    if (status != CompletionStatus.none) {
      parts.add(status.getLocaleName(l10n));
    }

    parts.add('${l10n.adhan} $adhanTime');

    if (iqamahTime != null) {
      parts.add('${l10n.iqamah} $iqamahTime');
    }

    if (relativeSubtitle != null && relativeSubtitle.isNotEmpty) {
      parts.add(relativeSubtitle);
    }

    parts.add(isExpanded ? l10n.collapse : l10n.selectPrayerToLog);

    return parts.join(', ');
  }

  /// Label for the per-prayer notification toggle.
  static String notificationToggle({
    required String prayerName,
    required bool enabled,
    required AppLocalizations l10n,
  }) =>
      enabled
          ? '$prayerName, ${l10n.a11yNotificationsOn}'
          : '$prayerName, ${l10n.a11yNotificationsOff}';

  /// Read-only label for a hero header time box (optional caption + time).
  static String heroTimeSquare({
    required String time,
    String? caption,
  }) =>
      caption != null ? '$caption, $time' : time;

  /// Label for the hero / schedule status menu trigger.
  static String statusMenuTrigger({
    required AppLocalizations l10n,
    required CompletionStatus? status,
  }) {
    if (status == null || status == CompletionStatus.none) {
      return l10n.logPrayerStatus;
    }
    return '${status.getLocaleName(l10n)}, ${l10n.logPrayerStatus}';
  }

  /// Label for a completion status option chip.
  static String statusOption({
    required AppLocalizations l10n,
    required CompletionStatus status,
    required bool enabled,
  }) {
    final name = status.getLocaleName(l10n);
    return enabled ? name : '$name, ${l10n.prepareForPrayer}';
  }

  /// Label for the today achievement gauge (percent + caption).
  static String todayPerformance({
    required AppLocalizations l10n,
    required int percent,
  }) =>
      '$percent%, ${l10n.performanceIndicator}';

  /// Read-only label for a stat breakdown cell.
  static String statCell({
    required int value,
    required String statusLabel,
  }) =>
      '$value $statusLabel';

  /// Read-only label for a sunnah time row (name + time).
  static String sunnahTimeRow({
    required String prayerName,
    required String time,
  }) =>
      '$prayerName, $time';
}
