// import 'package:adhan_dart/adhan_dart.dart';
import 'package:adhan_dart/adhan_dart.dart' show Prayer, PrayerTimesData;
import 'package:hasanat/core/utils/date_extensions.dart';
import 'package:hasanat/core/utils/prayer_extensions.dart';
import 'package:hasanat/feature/prayer/data/models/prayer_completion.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_tracker_card_model.dart';
import 'package:hasanat/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart';

/// Builds the list of prayer tracker card models for a given day.
List<PrayerTrackerCardModel> buildPrayerTrackerCards({
  required AppLocalizations l10n,
  required DateTime? day,
  required DateFormat formatter,
  required PrayerTimesData prayerTimes,
  required Map<Prayer, PrayerCompletion> completionByPrayer,
  required DateTime now,
  required Location location,
}) {
  final isPastDay = day?.isBeforeByDate(now) ?? false;
  final dayInLocation = day?.toLocation(location);
  final referenceMoment = isPastDay ? dayInLocation ?? now : now;
  final currentPrayer = prayerTimes.currentPrayer(date: referenceMoment);

  return Prayer.values
      .where((prayer) => prayer.isObligatory)
      .map((prayer) {
        final prayerTime = prayerTimes
            .timeForPrayer(prayer)
            .toLocation(location);
        final completion = completionByPrayer[prayer];
        final isCurrentPrayer = currentPrayer == prayer;
        final hasPassed = isPastDay || now.isAfter(prayerTime);

        return PrayerTrackerCardModel(
          prayer: prayer,
          isCurrentPrayer: isCurrentPrayer,
          adhan: formatter.format(prayerTime),
          subtitle: _subtitleMessage(
            l10n: l10n,
            isCurrentPrayer: isCurrentPrayer,
            now: now,
            prayerTime: prayerTime,
            isCompleted: completion != null,
          ),
          completion: completion,
          isTimePassed: hasPassed,
        );
      })
      .toList(growable: false);
}

String _subtitleMessage({
  required AppLocalizations l10n,
  required bool isCurrentPrayer,
  required DateTime now,
  required DateTime prayerTime,
  required bool isCompleted,
}) {
  if (isCurrentPrayer) {
    return l10n.currentPrayer;
  }

  final difference = now.difference(prayerTime).abs();
  final hours = difference.inHours;
  final minutes = difference.inMinutes;

  if (isCompleted) {
    final timeAgo = hours > 0
        ? l10n.adhanHoursAgo(hours)
        : l10n.adhanMinsAgo(minutes);
    return '${l10n.completed} - $timeAgo';
  }

  final isPast = now.isAfter(prayerTime);

  if (isPast) {
    return hours > 0 ? l10n.adhanHoursAgo(hours) : l10n.adhanMinsAgo(minutes);
  }

  return hours > 0 ? l10n.adhanHoursLeft(hours) : l10n.adhanMinsLeft(minutes);
}
