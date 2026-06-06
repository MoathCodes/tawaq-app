import 'package:tawaq/feature/prayer/data/models/prayer_completion.dart';
import 'package:tawaq/l10n/app_localizations.dart';

/// Relative subtitle for a schedule row (e.g. "in 2 hours", "30 mins ago").
String? computePrayerRelativeTime({
  required DateTime prayerTime,
  required DateTime now,
  required bool isCurrentPrayer,
  required CompletionStatus status,
  required AppLocalizations l10n,
}) {
  if (isCurrentPrayer) {
    return l10n.currentPrayer;
  }

  final isFuture = prayerTime.isAfter(now);
  final difference = now.difference(prayerTime).abs();
  final hours = difference.inHours;
  final totalMinutes = difference.inMinutes;

  if (status != CompletionStatus.none) {
    if (isFuture) {
      return l10n.completed;
    }
    final timeAgo = hours > 0
        ? l10n.adhanHoursAgo(hours)
        : l10n.adhanMinsAgo(totalMinutes);
    return '${l10n.completed} - $timeAgo';
  }

  if (isFuture) {
    return hours > 0
        ? l10n.adhanHoursLeft(hours)
        : l10n.adhanMinsLeft(totalMinutes);
  } else {
    return hours > 0
        ? l10n.adhanHoursAgo(hours)
        : l10n.adhanMinsAgo(totalMinutes);
  }
}
