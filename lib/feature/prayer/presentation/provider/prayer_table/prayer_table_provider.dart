import 'package:adhan_dart/adhan_dart.dart';
import 'package:hasanat/core/logging/talker_provider.dart';
import 'package:hasanat/core/utils/date_formatter.dart';
import 'package:hasanat/core/utils/prayer_extensions.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_table_model.dart';
import 'package:hasanat/feature/prayer/domain/services/prayer_service.dart';
import 'package:hasanat/feature/settings/data/models/prayer_settings_model.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:timezone/timezone.dart';

part 'prayer_table_provider.g.dart';

const String _prayerTableLogPrefix = "[PrayerTable]";

@riverpod
class PrayerTable extends _$PrayerTable {
  _TableCache? _cache;

  @override
  Stream<List<PrayerTableRow>> build(AppLocalizations l10n) async* {
    final log = ref.read(talkerNotifierProvider);
    final service = ref.read(prayerServiceProvider);

    final settings = ref.watch(prayerSettingsNotifierProvider).value;

    if (settings == null) {
      log.debug(
          "$_prayerTableLogPrefix No settings yet – emitting empty table.");
      yield [];
      return;
    }

    log.info("$_prayerTableLogPrefix Stream started (auto-dispose)");

    while (true) {
      try {
        final now = DateTime.now().toLocation(settings.location);

        _ensureCache(now, settings, service, log);

        if (_cache == null) {
          yield [];
          await Future.delayed(const Duration(minutes: 1));
          continue;
        }

        final formatter = ref.watch(timeFormatterProvider);

        final rows = _buildPrayerTableRows(
          formatter,
          _cache!.today,
          _cache!.todaySunnah,
          now,
          settings,
          settings.location,
          l10n,
        );

        yield rows;
      } catch (e, stackTrace) {
        log.handle(
            e, stackTrace, '$_prayerTableLogPrefix Error producing table');
        yield [];
      }

      await Future.delayed(const Duration(minutes: 1));
    }
  }

  String? _adhanMessage(bool isCurrentPrayer, DateTime currentTime,
      DateTime times, AppLocalizations l10n) {
    String? adhanMessage;
    if (isCurrentPrayer) {
      adhanMessage = l10n.currentPrayer;
    } else {
      final isPastAdhan = currentTime.isAfter(times);
      if (isPastAdhan) {
        final timeDifference = currentTime.difference(times);
        if (timeDifference.inHours > 0) {
          adhanMessage = l10n.adhanHoursAgo(timeDifference.inHours);
        } else {
          adhanMessage = l10n.adhanMinsAgo(timeDifference.inMinutes);
        }
      } else {
        final timeDifference = times.difference(currentTime);
        if (timeDifference.inHours > 0) {
          adhanMessage = l10n.adhanHoursLeft(timeDifference.inHours);
        } else {
          adhanMessage = l10n.adhanMinsLeft(timeDifference.inMinutes);
        }
      }
    }
    return adhanMessage;
  }

  List<PrayerTableRow> _buildPrayerTableRows(
      DateFormat formatter,
      PrayerTimesData prayerTimes,
      SunnahTimes sunnahTimes,
      DateTime currentTime,
      PrayerSettings settings,
      Location location,
      AppLocalizations l10n) {
    final midnightTime = sunnahTimes.middleOfTheNight.toLocation(location);
    final lastThirdTime = sunnahTimes.lastThirdOfTheNight.toLocation(location);
    final currentPrayer = prayerTimes.currentPrayer(date: currentTime);
    final List<PrayerTableRow> sunnahPrayers = [
      // Prayer.fajrAfter is used as midnight
      PrayerTableRow(
        prayer: Prayer.fajrAfter,
        isNextPrayer: false,
        isCurrentPrayer: currentPrayer == Prayer.fajrAfter,
        // isNextPrayer: next == Prayer.fajrAfter,
        adhan: (
          title: formatter.format(midnightTime),
          subtitle: _adhanMessage(
              prayerTimes.currentPrayer(date: currentTime) == Prayer.fajrAfter,
              currentTime,
              midnightTime,
              l10n),
        ),
        iqamah: (
          title: "------",
          subtitle: null,
        ),
        // isChecked: currentTime.isAfter(midnightTime),
      ),
      // Prayer.ishaBefore is used as Last Third of the Night
      PrayerTableRow(
        prayer: Prayer.ishaBefore,
        isNextPrayer: false,
        isCurrentPrayer: currentPrayer == Prayer.ishaBefore,
        adhan: (
          title: formatter.format(lastThirdTime),
          subtitle: _adhanMessage(
              prayerTimes.currentPrayer(date: currentTime) == Prayer.ishaBefore,
              currentTime,
              lastThirdTime,
              l10n),
        ),
        iqamah: (
          title: "------",
          subtitle: null,
        ),
        // isChecked: currentTime.isAfter(lastThirdTime),
      ),
    ];

    final prayers = Prayer.values
        .where((element) =>
            element != Prayer.fajrAfter && element != Prayer.ishaBefore)
        .map((prayer) {
      final times = prayerTimes.getTimesForPrayer(prayer, location);
      final adhanTime = formatter.format(times);
      String iqamahTime = formatter.format(
        times.add(Duration(minutes: settings.iqamahSettings[prayer] ?? 0)),
      );
      // final l10n = AppLocalizationsEn(); // This was creating a new instance, should use the passed one

      final isCurrentPrayer = currentPrayer == prayer;
      String? adhanMessage;
      String? iqamahMessage = settings.iqamahSettings[prayer] != null
          ? l10n.iqamahSubtitleMessage(settings.iqamahSettings[prayer]!)
          : null;
      if (prayer == Prayer.sunrise) {
        iqamahMessage = null;
        iqamahTime = "------";
      }

      // logic to write a message on how long ago or left for adhan or iqamah
      // either in hours or minutes
      adhanMessage = _adhanMessage(isCurrentPrayer, currentTime, times, l10n);

      // talker.debug("$_prayerTableLogPrefix Adan Message for $prayer: $adhanMessage");
      // talker.debug("$_prayerTableLogPrefix Iqamah Message for $prayer: $iqamahMessage");

      return PrayerTableRow(
        prayer: prayer,
        isNextPrayer: false,
        isCurrentPrayer: isCurrentPrayer,
        adhan: (title: adhanTime, subtitle: adhanMessage),
        iqamah: (title: iqamahTime, subtitle: iqamahMessage),
        // isChecked: currentTime.isAfter(times),
      );
    }).toList();
    final allRows = [...prayers, ...sunnahPrayers];

    // the row after the isCurrentPrayer will be the next prayer.
    final currentPrayerIndex = allRows.indexWhere((row) => row.isCurrentPrayer);
    if (currentPrayerIndex != -1) {
      if (currentPrayerIndex + 1 < allRows.length) {
        allRows[currentPrayerIndex + 1] =
            allRows[currentPrayerIndex + 1].copyWith(isNextPrayer: true);
      } else {
        // If current prayer is the last one, we can set the first prayer as next
        allRows[0] = allRows[0].copyWith(isNextPrayer: true);
      }
    }

    return allRows;
  }

  void _ensureCache(
    DateTime now,
    PrayerSettings settings,
    PrayerService service,
    Talker log,
  ) {
    final anchor = DateTime(now.year, now.month, now.day);

    if (_cache != null && _cache!.anchorDate == anchor) return;

    log.debug("$_prayerTableLogPrefix Refreshing cache …");

    final todayTimes = service.getTodaysPrayerTimes(now);
    final todaySunnah = service.getSunnahTime(todayTimes);

    _cache = _TableCache(
      anchorDate: anchor,
      today: todayTimes,
      todaySunnah: todaySunnah,
    );
  }
}

class _TableCache {
  final DateTime anchorDate;

  final PrayerTimesData today;
  final SunnahTimes todaySunnah;
  _TableCache({
    required this.anchorDate,
    required this.today,
    required this.todaySunnah,
  });
}
