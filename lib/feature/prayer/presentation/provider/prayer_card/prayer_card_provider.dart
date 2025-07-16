import 'package:adhan_dart/adhan_dart.dart';
import 'package:hasanat/core/logging/talker_provider.dart';
import 'package:hasanat/core/utils/date_formatter.dart';
import 'package:hasanat/core/utils/prayer_extensions.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_card_decision.dart';
import 'package:hasanat/feature/prayer/domain/models/prayer_card_model.dart';
import 'package:hasanat/feature/prayer/domain/services/prayer_service.dart'
    show computePrayerCardDecision, prayerServiceProvider, PrayerService;
import 'package:hasanat/feature/settings/data/models/prayer_settings_model.dart';
import 'package:hasanat/feature/settings/presentation/provider/settings_provider.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:timezone/timezone.dart';

part 'prayer_provider.g.dart';

const String _prayerCardLogPrefix = "[PrayerCard]";

@riverpod
class PrayerCard extends _$PrayerCard {
  _PrayerCache? _cache;
  PrayerSettings? _cachedSettings;

  @override
  Stream<PrayerCardInfo> build() {
    final log = ref.read(talkerNotifierProvider);
    final service = ref.read(prayerServiceProvider);

    final settingsState = ref.watch(prayerSettingsNotifierProvider);
    final settings = settingsState.value;

    if (settings == null) {
      log.debug("$_prayerCardLogPrefix Settings unavailable – empty stream");
      return const Stream.empty();
    }

    final formatter = ref.watch(timeFormatterProvider);

    return Stream.periodic(const Duration(seconds: 1), (_) {
      try {
        final now = DateTime.now().toLocation(settings.location);

        _ensureCache(settings, now, service, log);

        if (_cache == null) {
          // Shouldn\'t normally happen, but be defensive.
          return PrayerCardInfo.empty();
        }

        final decision = computePrayerCardDecision(
          currentTime: now,
          location: settings.location,
          todaysPrayerTimes: _cache!.todaysTimes,
          yesterdaysPrayerTimes: _cache!.yesterdaysTimes,
          todaysSunnahTimes: _cache!.todaysSunnah,
          yesterdaysSunnahTimes: _cache!.yesterdaysSunnah,
        );

        return _generateCard(
          decision,
          settings.location,
          now,
          formatter,
          settings,
        );
      } catch (e, stackTrace) {
        log.handle(
            e, stackTrace, '$_prayerCardLogPrefix Error producing prayer card');
        return PrayerCardInfo.empty();
      }
    });
  }

  void _ensureCache(
    PrayerSettings settings,
    DateTime now,
    PrayerService service,
    Talker log,
  ) {
    final DateTime todayAnchor = DateTime(now.year, now.month, now.day);

    final bool needsRefresh = _cache == null ||
        _cachedSettings != settings ||
        _cache!.anchorDate != todayAnchor;

    if (!needsRefresh) return;

    log.debug("$_prayerCardLogPrefix Building prayer cache …");

    final todaysTimes = service.getTodaysPrayerTimes(now);
    final yesterdaysTimes =
        service.getTodaysPrayerTimes(now.subtract(const Duration(days: 1)));

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
    DateFormat formatter,
    PrayerSettings activeSettingsForIqamah,
  ) {
    final time = decision.isCountdown
        ? decision.referenceTime.difference(currentTime).toHHMMSS()
        : "+${currentTime.difference(decision.referenceTime).toHHMMSS()}";

    final iqamahMinutes =
        activeSettingsForIqamah.iqamahSettings[decision.prayer] ?? 0;

    final cardInfo = PrayerCardInfo(
      time: time,
      prayer: decision.prayer,
      adhanTime: formatter.format(decision.referenceTime),
      iqamahTime: formatter.format(
        decision.referenceTime.add(
          Duration(minutes: iqamahMinutes),
        ),
      ),
    );
    return cardInfo;
  }
}

// Lightweight container for today/yesterday prayer & sunnah times.
class _PrayerCache {
  /// Midnight of the day the cache was built (in the active location).
  final DateTime anchorDate;

  final PrayerTimes todaysTimes;
  final PrayerTimes yesterdaysTimes;
  final SunnahTimes todaysSunnah;
  final SunnahTimes yesterdaysSunnah;
  const _PrayerCache({
    required this.anchorDate,
    required this.todaysTimes,
    required this.yesterdaysTimes,
    required this.todaysSunnah,
    required this.yesterdaysSunnah,
  });
}
