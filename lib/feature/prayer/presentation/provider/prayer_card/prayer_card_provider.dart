import 'package:adhan_dart/adhan_dart.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/utils/date_formatter.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_card_model.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_day_snapshot.dart';
import 'package:tawaq/feature/prayer/domain/prayer_extensions.dart';
import 'package:tawaq/feature/prayer/domain/use_cases/compute_prayer_card_decision.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_data_providers.dart';
import 'package:tawaq/feature/settings/presentation/provider/settings_provider.dart';

part 'prayer_card_provider.g.dart';

final PrayerCardInfo _emptyPrayerCard = PrayerCardInfo.empty();

/// Hero prayer card derived from the shared [prayerDayProvider] clock.
@riverpod
PrayerCardInfo prayerCard(Ref ref) {
  final day = ref.watch(prayerDayProvider).value;
  if (day == null) return _emptyPrayerCard;

  final settings = ref.watch(prayerSettingsProvider).value;
  if (settings == null) return _emptyPrayerCard;

  final formatter = ref.watch(timeFormatterProvider);
  final isArabic = ref.watch(localeProvider) == 'ar';

  try {
    return _buildPrayerCard(
      day: day,
      iqamahSettings: settings.iqamahSettings,
      formatter: formatter,
      useHinduArabicNumerals: isArabic,
    );
  } catch (_) {
    return _emptyPrayerCard;
  }
}

PrayerCardInfo _buildPrayerCard({
  required PrayerDaySnapshot day,
  required Map<Prayer, int> iqamahSettings,
  required DateFormat formatter,
  required bool useHinduArabicNumerals,
}) {
  final decision = computePrayerCardDecision(
    currentTime: day.now,
    location: day.location,
    todaysPrayerTimes: day.today,
    yesterdaysPrayerTimes: day.yesterday,
    todaysSunnahTimes: day.todaySunnah,
    yesterdaysSunnahTimes: day.yesterdaySunnah,
  );

  final iqamahMinutes = iqamahSettings[decision.prayer] ?? 0;
  final adhanTime = formatter.format(decision.referenceTime);
  final iqamahTime = formatter.format(
    decision.referenceTime.add(Duration(minutes: iqamahMinutes)),
  );

  final time = decision.isCountdown
      ? decision.referenceTime
            .difference(day.now)
            .toHHMMSS(useHinduArabicNumerals: useHinduArabicNumerals)
      : '+${day.now.difference(decision.referenceTime).toHHMMSS(
          useHinduArabicNumerals: useHinduArabicNumerals,
        )}';

  return PrayerCardInfo(
    time: time,
    prayer: decision.prayer,
    adhanTime: adhanTime,
    iqamahTime: iqamahTime,
    canSetStatus: decision.referenceTime.isBefore(day.now),
    showIqamah: iqamahMinutes > 0,
  );
}
