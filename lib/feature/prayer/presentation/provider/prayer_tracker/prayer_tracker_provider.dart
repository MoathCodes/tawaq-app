import 'package:adhan_dart/adhan_dart.dart';
import 'package:hasanat/core/utils/date_formatter.dart';
import 'package:hasanat/core/utils/prayer_extensions.dart';
import 'package:hasanat/feature/prayer/data/models/prayer_completion.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_tracker_card_model.dart';
import 'package:hasanat/feature/prayer/domain/services/prayer_service.dart';
import 'package:hasanat/feature/settings/data/models/prayer_settings_model.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timezone/timezone.dart';

part 'prayer_tracker_provider.g.dart';

@Riverpod(keepAlive: true)
class PrayerTrackerCards extends _$PrayerTrackerCards {
  DateTime? _lastDate;
  PrayerTimes? _lastPrayerTimes;
  PrayerSettings? _settings;
  Map<Prayer, PrayerCompletion>? _completionMap;
  // bool _hasChanged = false;

  // void addOrUpdateCompletion(PrayerCompletion completion) async {
  //   final service = ref.read(prayerServiceProvider);
  //   await service.addOrUpdateCompletion(completion);
  //   ref.invalidateSelf();
  // }

  @override
  Stream<List<PrayerTrackerCardModel>> build(AppLocalizations l10n) async* {
    final service = ref.read(prayerServiceProvider);

    ref.listen(prayerSettingsNotifierProvider, (previous, next) {
      if (next.hasValue && previous?.valueOrNull != next.valueOrNull) {
        _settings = next.value;
      }
    });

    _settings = ref.read(prayerSettingsNotifierProvider).valueOrNull;

    while (true) {
      if (_settings == null) {
        await Future.delayed(const Duration(milliseconds: 500));
        _settings = ref.read(prayerSettingsNotifierProvider).valueOrNull;
        continue;
      }

      final location = _settings!.location;
      final formatter =
          ref.read(timeFormatterProvider(is24Hours: _settings!.is24Hours));
      final currentTime = DateTime.now().toLocation(location);

      if (_needsUpdate(currentTime)) {
        // _hasChanged = false;
        _lastPrayerTimes = service.getTodaysPrayerTimes();
        _lastDate = currentTime;
      }

      // service.watchPrayerCompletionByDate(currentTime).listen((completions) {
      //   if (completions != _completionMap?.values.toList()) {
      //     _completionMap = Map.fromEntries(
      //       completions.map((c) => MapEntry(c.prayer, c)),
      //     );
      //     // _hasChanged = true;
      //   }
      // });

      if (_completionMap == null) {
        await Future.delayed(const Duration(milliseconds: 500));
        continue;
      }

      yield _buildPrayerCards(
          formatter, _lastPrayerTimes!, currentTime, location, l10n);
      await Future.delayed(const Duration(minutes: 1));
    }
  }

  DateTime currentLocationTime() {
    return DateTime.now().toLocation(
        _settings?.location ?? PrayerSettings.defaultSettings().location);
  }


  List<PrayerTrackerCardModel> _buildPrayerCards(
      DateFormat formatter,
      PrayerTimes prayerTimes,
      DateTime currentTime,
      Location location,
      AppLocalizations l10n) {
    final currentPrayer = prayerTimes.currentPrayer(date: currentTime);

    return Prayer.values
        .where((element) =>
            element != Prayer.fajrAfter &&
            element != Prayer.ishaBefore &&
            element != Prayer.sunrise)
        .map((prayer) {
      final times = prayerTimes.getTimesForPrayer(prayer, location);
      final adhanTime = formatter.format(times);
      final isCurrentPrayer = currentPrayer == prayer;
      final isTimePassed = currentTime.isAfter(times);

      final subtitle =
          _subtitleMessage(isCurrentPrayer, prayer, currentTime, times, l10n);



      return PrayerTrackerCardModel(
        prayer: prayer,
        isCurrentPrayer: isCurrentPrayer,
        adhan: adhanTime,
        subtitle: subtitle ?? "------",
        completion: _completionMap?[prayer],
        isTimePassed: isTimePassed,
      );
    }).toList();
  }

  bool _needsUpdate(DateTime currentTime) =>
      _lastDate == null ||
      _lastDate?.day != currentTime.day ||
      _settings == null ||
      // _hasChanged == true ||
      _lastPrayerTimes == null;

  String? _subtitleMessage(bool isCurrentPrayer, Prayer prayer,
      DateTime currentTime, DateTime times, AppLocalizations l10n) {
    if (isCurrentPrayer) {
      return l10n.currentPrayer;
    }

    final isPastAdhan = currentTime.isAfter(times);
    final timeDifference = isPastAdhan
        ? currentTime.difference(times)
        : times.difference(currentTime);

    if (_completionMap?[prayer] != null) {
      final subtitle = timeDifference.inHours > 0
          ? l10n.adhanHoursAgo(timeDifference.inHours)
          : l10n.adhanMinsAgo(timeDifference.inMinutes);
      return "${l10n.completed} $subtitle";
    } else {
      return timeDifference.inHours > 0
          ? l10n.adhanHoursLeft(timeDifference.inHours)
          : l10n.adhanMinsLeft(timeDifference.inMinutes);
    }
  }
}
