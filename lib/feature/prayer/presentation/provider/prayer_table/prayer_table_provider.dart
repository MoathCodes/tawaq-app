import 'package:adhan_dart/adhan_dart.dart';
import 'package:hasanat/core/logging/logger_provider.dart';
import 'package:hasanat/core/utils/date_formatter.dart';
import 'package:hasanat/core/utils/prayer_extensions.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_table_model.dart';
import 'package:hasanat/feature/prayer/domain/services/prayer_service.dart';
import 'package:hasanat/feature/settings/data/models/prayer_settings_model.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timezone/timezone.dart';

part 'prayer_table_provider.g.dart';

const String _prayerTableLogPrefix = '[PrayerTable]';

/// Notifier for the prayer times table.
@riverpod
class PrayerTable extends _$PrayerTable {
  _TableCache? _cache;

  @override
  Stream<List<PrayerTableRow>> build(AppLocalizations l10n) async* {
    final log = ref.read(loggerProvider);
    final service = ref.read(prayerServiceProvider);

    final settings = ref.watch(prayerSettingsProvider).value;
    if (settings == null) {
      log.d('$_prayerTableLogPrefix No settings yet – emitting empty table.');
      yield [];
      return;
    }

    log.i('$_prayerTableLogPrefix Stream started (auto-dispose)');
    final formatter = ref.watch(timeFormatterProvider);

    // Emit immediately, then on every minute boundary to keep times fresh
    yield* _minuteTicker().map((_) {
      try {
        final now = DateTime.now().toLocation(settings.location);
        _ensureCache(now, settings, service, log);
        if (_cache == null) return <PrayerTableRow>[];

        return _buildPrayerTableRows(
          formatter,
          _cache!.today,
          _cache!.todaySunnah,
          now,
          settings,
          settings.location,
          l10n,
        );
      } catch (e, stackTrace) {
        log.e(
          '$_prayerTableLogPrefix Error producing table',
          error: e,
          stackTrace: stackTrace,
        );
        return <PrayerTableRow>[];
      }
    });
  }

  String? _adhanMessage(
    bool isCurrentPrayer,
    DateTime currentTime,
    DateTime times,
    AppLocalizations l10n,
  ) {
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
    PrayerTimes prayerTimes,
    SunnahTimes sunnahTimes,
    DateTime currentTime,
    PrayerSettings settings,
    Location location,
    AppLocalizations l10n,
  ) {
    final midnightTime = sunnahTimes.middleOfTheNight.toLocation(location);
    final lastThirdTime = sunnahTimes.lastThirdOfTheNight.toLocation(location);
    final currentPrayer = prayerTimes.currentPrayer(time: currentTime);
    final sunnahPrayers = <PrayerTableRow>[
      // Prayer.fajrAfter is used as midnight
      PrayerTableRow(
        prayer: Prayer.fajrAfter,
        isNextPrayer: false,
        isCurrentPrayer: currentPrayer == Prayer.fajrAfter,
        // isNextPrayer: next == Prayer.fajrAfter,
        adhan: (
          title: formatter.format(midnightTime),
          subtitle: _adhanMessage(
            currentPrayer == Prayer.fajrAfter,
            currentTime,
            midnightTime,
            l10n,
          ),
        ),
        iqamah: (title: '------', subtitle: null),
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
            currentPrayer == Prayer.ishaBefore,
            currentTime,
            lastThirdTime,
            l10n,
          ),
        ),
        iqamah: (title: '------', subtitle: null),
        // isChecked: currentTime.isAfter(lastThirdTime),
      ),
    ];

    final prayers = Prayer.values
        .where(
          (element) =>
              element != Prayer.fajrAfter && element != Prayer.ishaBefore,
        )
        .map((prayer) {
          final times = prayerTimes.getTimesForPrayer(prayer, location);
          final adhanTime = formatter.format(times);
          final iqamahMinutes = settings.iqamahSettings[prayer] ?? 0;
          var iqamahTime = iqamahMinutes == 0
              ? '------'
              : formatter.format(times.add(Duration(minutes: iqamahMinutes)));

          if (adhanTime == iqamahTime) {
            iqamahTime = '------';
          }
          // final l10n = AppLocalizationsEn(); // This was creating a new instance, should use the passed one

          final isCurrentPrayer = currentPrayer == prayer;
          String? adhanMessage;
          var iqamahMessage = iqamahMinutes != 0
              ? l10n.iqamahSubtitleMessage(iqamahMinutes)
              : null;
          if (prayer == Prayer.sunrise) {
            iqamahMessage = null;
            iqamahTime = '------';
          }

          // logic to write a message on how long ago or
          // left for adhan or iqamah
          // either in hours or minutes
          adhanMessage = _adhanMessage(
            isCurrentPrayer,
            currentTime,
            times,
            l10n,
          );

          return PrayerTableRow(
            prayer: prayer,
            isNextPrayer: false,
            isCurrentPrayer: isCurrentPrayer,
            adhan: (title: adhanTime, subtitle: adhanMessage),
            iqamah: (title: iqamahTime, subtitle: iqamahMessage),
            // isChecked: currentTime.isAfter(times),
          );
        })
        .toList();
    final allRows = [...prayers, ...sunnahPrayers];

    // the row after the isCurrentPrayer will be the next prayer.
    final currentPrayerIndex = allRows.indexWhere((row) => row.isCurrentPrayer);
    if (currentPrayerIndex != -1) {
      if (currentPrayerIndex + 1 < allRows.length) {
        allRows[currentPrayerIndex + 1] = allRows[currentPrayerIndex + 1]
            .copyWith(isNextPrayer: true);
      } else {
        // If current prayer is the last one, we can
        // set the first prayer as next
        allRows[0] = allRows[0].copyWith(isNextPrayer: true);
      }
    }

    return allRows;
  }

  void _ensureCache(
    DateTime now,
    PrayerSettings settings,
    PrayerService service,
    Logger log,
  ) {
    final anchor = DateTime(now.year, now.month, now.day);

    if (_cache != null && _cache!.anchorDate == anchor) return;

    log.d('$_prayerTableLogPrefix Refreshing cache …');

    final todayTimes = service.getTodaysPrayerTimes(now);
    final todaySunnah = service.getSunnahTime(todayTimes);

    _cache = _TableCache(
      anchorDate: anchor,
      today: todayTimes,
      todaySunnah: todaySunnah,
    );
  }

  /// Emits immediately, then at each next minute boundary.
  Stream<DateTime> _minuteTicker() async* {
    yield DateTime.now();
    while (true) {
      final now = DateTime.now();
      final next = DateTime(
        now.year,
        now.month,
        now.day,
        now.hour,
        now.minute + 1,
      );
      await Future<void>.delayed(next.difference(now));
      yield DateTime.now();
    }
  }
}

class _TableCache {
  _TableCache({
    required this.anchorDate,
    required this.today,
    required this.todaySunnah,
  });
  final DateTime anchorDate;
  final PrayerTimes today;
  final SunnahTimes todaySunnah;
}
