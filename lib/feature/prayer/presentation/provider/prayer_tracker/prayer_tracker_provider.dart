import 'package:adhan_dart/adhan_dart.dart';
import 'package:hasanat/core/utils/date_formatter.dart';
import 'package:hasanat/core/utils/prayer_extensions.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_tracker_card_model.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_completion_provider.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_data_providers.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/l10n/app_localizations.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timezone/timezone.dart';

part 'prayer_tracker_provider.g.dart';

@riverpod
class PrayerTrackerCards extends _$PrayerTrackerCards {
  // The add/update method now lives in PrayerCompletionNotifier
  // and can be accessed from the UI like this:
  // ref.read(prayerCompletionNotifierProvider.notifier).addOrUpdateCompletion(completion);

  @override
  List<PrayerTrackerCardModel> build(AppLocalizations l10n) {
    // 1. Watch all necessary data sources. Riverpod handles all updates automatically.
    final prayerTimes = ref.watch(todaysPrayerTimesProvider);
    final currentTime = ref.watch(currentLocationTimeProvider);
    final completionMap = ref.watch(prayerCompletionNotifierProvider);
    final formatter = ref.watch(timeFormatterProvider);
    final location = ref.watch(prayerSettingsNotifierProvider
        .select((s) => s.value?.location)); // Assuming settings are loaded

    // 2. The rest of the logic is for transforming data into UI models.
    final currentPrayer = prayerTimes.currentPrayer(date: currentTime);

    return Prayer.values
        .where((p) =>
            p != Prayer.fajrAfter &&
            p != Prayer.ishaBefore &&
            p != Prayer.sunrise)
        .map((prayer) {
      final prayerTime = prayerTimes
          .timeForPrayer(prayer)!
          .toLocation(location ?? getLocation('Asia/Riyadh'));
      final isCurrentPrayer = currentPrayer == prayer;
      final isTimePassed = currentTime.isAfter(prayerTime);

      final subtitle = _subtitleMessage(
        l10n,
        isCurrentPrayer,
        currentTime,
        prayerTime,
        completionMap[prayer] != null,
      );

      return PrayerTrackerCardModel(
        prayer: prayer,
        isCurrentPrayer: isCurrentPrayer,
        adhan: formatter.format(prayerTime),
        subtitle: subtitle,
        completion: completionMap[prayer],
        isTimePassed: isTimePassed,
      );
    }).toList();
  }

  String _subtitleMessage(
    AppLocalizations l10n,
    bool isCurrentPrayer,
    DateTime currentTime,
    DateTime prayerTime,
    bool isCompleted,
  ) {
    if (isCurrentPrayer) {
      return l10n.currentPrayer;
    }

    final difference = currentTime.difference(prayerTime).abs();
    final hours = difference.inHours;
    final minutes = difference.inMinutes;

    if (isCompleted) {
      final timeAgo =
          hours > 0 ? l10n.adhanHoursAgo(hours) : l10n.adhanMinsAgo(minutes);
      return "${l10n.completed} - $timeAgo";
    }

    final isPast = currentTime.isAfter(prayerTime);

    if (isPast) {
      return hours > 0 ? l10n.adhanHoursAgo(hours) : l10n.adhanMinsAgo(minutes);
    } else {
      return hours > 0
          ? l10n.adhanHoursLeft(hours)
          : l10n.adhanMinsLeft(minutes);
    }
  }
}
