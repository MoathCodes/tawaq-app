// Need to catch all errors to ensure stream continues.
// ignore_for_file: avoid_catches_without_on_clauses

import 'package:adhan_dart/adhan_dart.dart';
import 'package:hasanat/core/logging/logger_provider.dart';
import 'package:hasanat/core/utils/date_formatter.dart';
import 'package:hasanat/core/utils/prayer_extensions.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_card_decision.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_card_model.dart';
import 'package:hasanat/feature/prayer/domain/services/prayer_service.dart'
    show PrayerService, computePrayerCardDecision, prayerServiceProvider;
import 'package:hasanat/feature/settings/data/models/prayer_settings_model.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timezone/timezone.dart';

part 'prayer_card_provider.g.dart';

const String _prayerCardLogPrefix = '[PrayerCard]';

/// Notifier for the prayer card information.
@riverpod
class PrayerCard extends _$PrayerCard {
  _PrayerCache? _cache;
  PrayerSettings? _cachedSettings;

  @override
  Stream<PrayerCardInfo> build() async* {
    if (!ref.mounted) return;
    final log = ref.watch(loggerProvider);
    final service = ref.watch(prayerServiceProvider);

    final settingsState = ref.watch(prayerSettingsProvider);
    final settings = settingsState.value;

    if (settings == null) {
      log.d('$_prayerCardLogPrefix Settings unavailable – empty stream');
      yield PrayerCardInfo.empty();
    }

    final formatter = ref.watch(timeFormatterProvider);
    final isArabic = ref.read(localeProvider.notifier).isArabic();

    while (true) {
      try {
        final now = DateTime.now().toLocation(settings!.location);

        _ensureCache(settings, now, service, log);

        if (_cache == null) {
          // Shouldn\'t normally happen, but be defensive.
          yield PrayerCardInfo.empty();
        }

        final decision = computePrayerCardDecision(
          currentTime: now,
          location: settings.location,
          todaysPrayerTimes: _cache!.todaysTimes,
          yesterdaysPrayerTimes: _cache!.yesterdaysTimes,
          todaysSunnahTimes: _cache!.todaysSunnah,
          yesterdaysSunnahTimes: _cache!.yesterdaysSunnah,
        );

        yield _generateCard(
          decision,
          settings.location,
          now,
          isArabic,
          formatter,
          settings,
        );
      } catch (e, stackTrace) {
        log.e(
          '$_prayerCardLogPrefix Error producing prayer card',
          error: e,
          stackTrace: stackTrace,
        );
        yield PrayerCardInfo.empty();
      } finally {
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    }
  }

  void _ensureCache(
    PrayerSettings settings,
    DateTime now,
    PrayerService service,
    Logger log,
  ) {
    final todayAnchor = DateTime(now.year, now.month, now.day);

    final needsRefresh =
        _cache == null ||
        _cachedSettings != settings ||
        _cache!.anchorDate != todayAnchor;

    if (!needsRefresh) return;

    log.d('$_prayerCardLogPrefix Building prayer cache …');

    final todaysTimes = service.getTodaysPrayerTimes(
      now,
      roundToMinutes: false,
    );
    final yesterdaysTimes = service.getTodaysPrayerTimes(
      now.subtract(const Duration(days: 1)),
      roundToMinutes: false,
    );

    _cache = _PrayerCache(
      anchorDate: todayAnchor,
      todaysTimes: todaysTimes,
      yesterdaysTimes: yesterdaysTimes,
      todaysSunnah: service.getSunnahTime(todaysTimes),
      yesterdaysSunnah: service.getSunnahTime(yesterdaysTimes),
    );

    _cachedSettings = settings;
  }

  PrayerCardInfo _generateCard(
    PrayerCardDecision decision,
    Location location,
    DateTime currentTime,
    bool useHinduArabicNumerals,
    DateFormat formatter,
    PrayerSettings activeSettingsForIqamah,
  ) {
    final time = decision.isCountdown
        ? decision.referenceTime
              .difference(currentTime)
              .toHHMMSS(useHinduArabicNumerals: useHinduArabicNumerals)
        : '+${currentTime.difference(decision.referenceTime).toHHMMSS(useHinduArabicNumerals: useHinduArabicNumerals)}';

    final iqamahMinutes =
        activeSettingsForIqamah.iqamahSettings[decision.prayer] ?? 0;

    final cardInfo = PrayerCardInfo(
      canSetStatus: currentTime.isAfter(decision.referenceTime),
      showIqamah: iqamahMinutes > 0,
      time: time,
      prayer: decision.prayer,
      adhanTime: formatter.format(decision.referenceTime),
      iqamahTime: formatter.format(
        decision.referenceTime.add(Duration(minutes: iqamahMinutes)),
      ),
    );
    return cardInfo;
  }
}

// Lightweight container for today/yesterday prayer & sunnah times.
class _PrayerCache {
  const _PrayerCache({
    required this.anchorDate,
    required this.todaysTimes,
    required this.yesterdaysTimes,
    required this.todaysSunnah,
    required this.yesterdaysSunnah,
  });

  /// Midnight of the day the cache was built (in the active location).
  final DateTime anchorDate;

  final PrayerTimes todaysTimes;

  final PrayerTimes yesterdaysTimes;
  final SunnahTimes todaysSunnah;
  final SunnahTimes yesterdaysSunnah;
}
