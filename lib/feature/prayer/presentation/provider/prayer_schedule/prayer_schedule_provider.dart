import 'package:adhan_dart/adhan_dart.dart';
import 'package:hasanat/core/logging/logger_provider.dart';
import 'package:hasanat/core/utils/date_formatter.dart';
import 'package:hasanat/core/utils/prayer_extensions.dart';
import 'package:hasanat/feature/prayer/data/models/prayer_completion.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_schedule_row.dart';
import 'package:hasanat/feature/prayer/domain/services/prayer_service.dart';
import 'package:hasanat/feature/prayer/presentation/provider/prayer_completion_provider.dart';
import 'package:hasanat/feature/settings/data/models/prayer_settings_model.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:hasanat/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'prayer_schedule_provider.g.dart';

const _logPrefix = '[PrayerSchedule]';

/// The list of obligatory prayers to display in the schedule.
const List<Prayer> _obligatoryPrayers = [
  Prayer.fajr,
  Prayer.dhuhr,
  Prayer.asr,
  Prayer.maghrib,
  Prayer.isha,
];

/// Provider for the prayer schedule list.
///
/// This combines prayer times, completion statuses, and relative time
/// calculations into a single stream of [PrayerScheduleRow] items.
@riverpod
class PrayerSchedule extends _$PrayerSchedule {
  _Cache? _cache;

  @override
  Stream<List<PrayerScheduleRow>> build(
    AppLocalizations l10n, [
    DateTime? forDate,
  ]) async* {
    final log = ref.read(loggerProvider);
    final service = ref.read(prayerServiceProvider);
    final settings = ref.watch(prayerSettingsProvider).value;

    if (settings == null) {
      yield [];
      return;
    }

    final formatter = ref.watch(timeFormatterProvider);

    // Watch completions reactively
    final completionsAsync = ref.watch(prayerCompletionProvider);

    yield* _ticker().map((_) {
      try {
        final now = DateTime.now().toLocation(settings.location);
        // Use forDate if provided, otherwise use current time
        final targetDate = forDate ?? now;
        _ensureCache(targetDate, settings, service, log);

        if (_cache == null) {
          return <PrayerScheduleRow>[];
        }

        // Build completion map from current state
        final completionMap = completionsAsync.maybeWhen(
          data: (list) => {for (final c in list) c.prayer: c},
          orElse: () => <Prayer, PrayerCompletion>{},
        );

        return _buildRows(
          formatter: formatter,
          times: _cache!.today,
          now: now,
          targetDate: targetDate,
          settings: settings,
          l10n: l10n,
          completions: completionMap,
        );
      } catch (e, st) {
        log.e('$_logPrefix Error', error: e, stackTrace: st);
        return <PrayerScheduleRow>[];
      }
    });
  }

  void _ensureCache(
    DateTime now,
    PrayerSettings settings,
    PrayerService service,
    Logger log,
  ) {
    final anchor = DateTime(now.year, now.month, now.day);
    if (_cache?.anchor == anchor) return;
    log.d('$_logPrefix Refreshing cache');
    final today = service.getTodaysPrayerTimes(now);
    _cache = _Cache(anchor: anchor, today: today);
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

  /// Computes the relative time subtitle for a prayer.
  String? _computeRelativeTime({
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

  List<PrayerScheduleRow> _buildRows({
    required DateFormat formatter,
    required PrayerTimes times,
    required DateTime now,
    required DateTime targetDate,
    required PrayerSettings settings,
    required AppLocalizations l10n,
    required Map<Prayer, PrayerCompletion> completions,
  }) {
    final location = settings.location;
    final currentPrayer = times.currentPrayer(time: now);
    final completionDate = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );

    final rows = <PrayerScheduleRow>[];

    for (final prayer in _obligatoryPrayers) {
      final prayerTime = times.getTimesForPrayer(prayer, location);
      final iqamahMinutes = settings.iqamahSettings[prayer] ?? 0;

      final formattedAdhan = formatter.format(prayerTime);
      final formattedIqamah = iqamahMinutes > 0
          ? formatter.format(prayerTime.add(Duration(minutes: iqamahMinutes)))
          : null;

      // Only mark a prayer as "active" if we're viewing today
      // Past dates should not have any active prayer
      final isToday =
          targetDate.year == now.year &&
          targetDate.month == now.month &&
          targetDate.day == now.day;

      // Determine if this is the "active" prayer (only for today)
      // When between prayers (e.g., before Fajr or after Isha),
      // highlight the next obligatory prayer
      final isActive =
          isToday &&
          (currentPrayer.isObligatory
              ? prayer == currentPrayer
              : currentPrayer == Prayer.ishaBefore ||
                    currentPrayer == Prayer.fajrAfter
              ? prayer == Prayer.fajr
              : prayer == Prayer.dhuhr);

      final completion = completions[prayer];
      final status = completion?.status ?? CompletionStatus.none;

      final relativeTime = _computeRelativeTime(
        prayerTime: prayerTime,
        now: now,
        isCurrentPrayer: isActive,
        status: status,
        l10n: l10n,
      );

      rows.add(
        PrayerScheduleRow(
          prayer: prayer,
          prayerTime: prayerTime,
          formattedAdhanTime: formattedAdhan,
          formattedIqamahTime: formattedIqamah,
          relativeTimeSubtitle: relativeTime,
          isCurrentPrayer: isActive,
          completionStatus: status,
          completionDate: completionDate,
        ),
      );
    }

    // Mark the next prayer
    final currentIdx = rows.indexWhere((r) => r.isCurrentPrayer);
    if (currentIdx != -1 && currentIdx + 1 < rows.length) {
      rows[currentIdx + 1] = rows[currentIdx + 1].copyWith(isNextPrayer: true);
    }

    return rows;
  }
}

class _Cache {
  _Cache({required this.anchor, required this.today});
  final DateTime anchor;
  final PrayerTimes today;
}
