import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:hasanat/core/logging/talker_provider.dart';
import 'package:hasanat/core/utils/date_formatter.dart';
import 'package:hasanat/core/utils/prayer_extensions.dart';
import 'package:hasanat/feature/prayer/data/models/prayer_completion.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_tracker_card_model.dart';
import 'package:hasanat/feature/prayer/domain/services/prayer_service.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_analytics/prayer_analytics_provider.dart';
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
  StreamSubscription<List<PrayerCompletion>>? _completionSub;
  DateFormat? _formatter;
  DateTime? _subscriptionDateKey;

  void addOrUpdateCompletion(PrayerCompletion completion) async {
    final service = ref.read(prayerServiceProvider);
    await service.addOrUpdateCompletion(completion);
    ref.invalidate(prayerAnalyticsNotifierProvider);
    ref.invalidateSelf();
  }

  @override
  Stream<List<PrayerTrackerCardModel>> build(AppLocalizations l10n) async* {
    final service = ref.read(prayerServiceProvider);
    final talker = ref.read(talkerNotifierProvider);

    final prayerSettingsSub =
        ref.listen(prayerSettingsNotifierProvider, (previous, next) {
      if (next.hasValue && previous?.valueOrNull != next.valueOrNull) {
        _settings = next.value;
        _formatter = null; // force refresh with new locale/time format
      }
    });

    _settings = ref.read(prayerSettingsNotifierProvider).valueOrNull;

    // Ensure the stream subscription is cancelled when provider is disposed.
    ref.onDispose(() {
      _completionSub?.cancel();
      prayerSettingsSub.close();
    });
    while (true) {
      try {
        if (_settings == null) {
          await Future.delayed(const Duration(milliseconds: 500));
          _settings = ref.read(prayerSettingsNotifierProvider).valueOrNull;
          continue;
        }

        final location = _settings!.location;
        // Cache DateFormat for current locale/24h preference
        _formatter ??= ref.read(timeFormatterProvider);
        final currentTime = DateTime.now().toLocation(location);

        if (_needsUpdate(currentTime)) {
          _lastPrayerTimes = service.getTodaysPrayerTimes();
          _lastDate = currentTime;
        }

        // Subscribe once per date change
        final dateKey =
            DateTime(currentTime.year, currentTime.month, currentTime.day);
        if (_completionSub == null || _subscriptionDateKey != dateKey) {
          await _completionSub?.cancel();
          _completionSub = service
              .watchPrayerCompletionByDate(currentTime)
              .listen((completions) {
            // Always update the cached map – an empty list still represents
            // a valid (yet-to-be-completed) state for the current day.
            _completionMap = {
              for (final c in completions) c.prayer: c,
            };
          });
          _subscriptionDateKey = dateKey;
        }

        // Ensure we have a non-null map so the UI can render even when no
        // completions exist for the day yet.
        _completionMap ??= {};

        final cards = _buildPrayerCards(
            _formatter!, _lastPrayerTimes!, currentTime, location, l10n);

        yield cards;
      } catch (e, stackTrace) {
        talker.handle(
            e, stackTrace, '[PrayerTrackerCards] Error producing card stream');
        // Optionally emit empty list so the UI gets something.
        yield [];
      }

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
