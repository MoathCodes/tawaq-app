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

part 'prayer_table_provider.g.dart';

const _logPrefix = '[PrayerTable]';

/// Notifier for the prayer times table.
@riverpod
class PrayerTable extends _$PrayerTable {
  _Cache? _cache;

  @override
  Stream<List<PrayerTableRow>> build(AppLocalizations l10n) async* {
    final log = ref.read(loggerProvider);
    final service = ref.read(prayerServiceProvider);
    final settings = ref.watch(prayerSettingsProvider).value;
    if (settings == null) {
      yield [];
      return;
    }

    final fmt = ref.watch(timeFormatterProvider);
    yield* _ticker().map((_) {
      try {
        final now = DateTime.now().toLocation(settings.location);
        _ensureCache(now, settings, service, log);
        return _cache == null
            ? <PrayerTableRow>[]
            : _buildRows(
                fmt,
                _cache!.today,
                _cache!.sunnah,
                now,
                settings,
                l10n,
              );
      } catch (e, st) {
        log.e('$_logPrefix Error', error: e, stackTrace: st);
        return <PrayerTableRow>[];
      }
    });
  }

  void _ensureCache(
    DateTime now,
    PrayerSettings s,
    PrayerService svc,
    Logger log,
  ) {
    final anchor = DateTime(now.year, now.month, now.day);
    if (_cache?.anchor == anchor) return;
    log.d('$_logPrefix Refreshing cache');
    final today = svc.getTodaysPrayerTimes(now);
    _cache = _Cache(
      anchor: anchor,
      today: today,
      sunnah: svc.getSunnahTime(today),
    );
  }

  Stream<DateTime> _ticker() async* {
    yield DateTime.now();
    while (true) {
      final now = DateTime.now();
      await Future<void>.delayed(
        DateTime(
          now.year,
          now.month,
          now.day,
          now.hour,
          now.minute + 1,
        ).difference(now),
      );
      yield DateTime.now();
    }
  }

  String? _adhanMsg(
    bool isCurrent,
    DateTime now,
    DateTime t,
    AppLocalizations l10n,
  ) {
    if (isCurrent) return l10n.currentPrayer;
    final diff = now.isAfter(t) ? now.difference(t) : t.difference(now);
    final isPast = now.isAfter(t);
    return diff.inHours > 0
        ? (isPast
              ? l10n.adhanHoursAgo(diff.inHours)
              : l10n.adhanHoursLeft(diff.inHours))
        : (isPast
              ? l10n.adhanMinsAgo(diff.inMinutes)
              : l10n.adhanMinsLeft(diff.inMinutes));
  }

  List<PrayerTableRow> _buildRows(
    DateFormat fmt,
    PrayerTimes times,
    SunnahTimes sunnah,
    DateTime now,
    PrayerSettings settings,
    AppLocalizations l10n,
  ) {
    final loc = settings.location;
    final current = times.currentPrayer(time: now);

    final sunnahRows =
        [
          (Prayer.fajrAfter, sunnah.middleOfTheNight),
          (Prayer.ishaBefore, sunnah.lastThirdOfTheNight),
        ].map((e) {
          final t = e.$2.toLocation(loc);
          return PrayerTableRow(
            prayer: e.$1,
            isNextPrayer: false,
            isCurrentPrayer: current == e.$1,
            adhan: (
              title: fmt.format(t),
              subtitle: _adhanMsg(current == e.$1, now, t, l10n),
            ),
            iqamah: (title: '------', subtitle: null),
          );
        }).toList();

    final prayerRows = Prayer.values
        .where((p) => p != Prayer.fajrAfter && p != Prayer.ishaBefore)
        .map((p) {
          final t = times.getTimesForPrayer(p, loc);
          final iqamahMins = settings.iqamahSettings[p] ?? 0;
          final adhan = fmt.format(t);
          var iqamah = iqamahMins == 0
              ? '------'
              : fmt.format(t.add(Duration(minutes: iqamahMins)));
          if (adhan == iqamah || p == Prayer.sunrise) iqamah = '------';
          final iqamahSub = (p != Prayer.sunrise && iqamahMins != 0)
              ? l10n.iqamahSubtitleMessage(iqamahMins)
              : null;
          return PrayerTableRow(
            prayer: p,
            isNextPrayer: false,
            isCurrentPrayer: current == p,
            adhan: (
              title: adhan,
              subtitle: _adhanMsg(current == p, now, t, l10n),
            ),
            iqamah: (title: iqamah, subtitle: iqamahSub),
          );
        })
        .toList();

    final all = [...prayerRows, ...sunnahRows];
    final idx = all.indexWhere((r) => r.isCurrentPrayer);
    if (idx != -1) {
      final nextIdx = (idx + 1) % all.length;
      all[nextIdx] = all[nextIdx].copyWith(isNextPrayer: true);
    }
    return all;
  }
}

class _Cache {
  _Cache({required this.anchor, required this.today, required this.sunnah});
  final DateTime anchor;
  final PrayerTimes today;
  final SunnahTimes sunnah;
}
