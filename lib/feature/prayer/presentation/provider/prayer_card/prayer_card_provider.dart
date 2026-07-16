import 'package:adhan_dart/adhan_dart.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/locale/locale_provider.dart';
import 'package:tawaq/core/utils/date_formatter.dart';
import 'package:tawaq/core/utils/prayer_extensions.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_day_snapshot.dart';
import 'package:tawaq/feature/prayer/domain/prayer_slots.dart';
import 'package:tawaq/feature/prayer/presentation/provider/prayer_day.dart';
import 'package:tawaq/feature/settings/presentation/provider/prayer_settings_provider.dart';

part 'prayer_card_provider.g.dart';

final ({String adhanTime, bool canSetStatus, String iqamahTime, bool isCountdown, Prayer prayer, DateTime referenceTime, bool showIqamah}) _emptyPrayerCardStatic = (
  prayer: Prayer.fajrAfter,
  adhanTime: '00:00',
  iqamahTime: '00:00',
  canSetStatus: false,
  showIqamah: false,
  isCountdown: true,
  referenceTime: DateTime.fromMillisecondsSinceEpoch(0),
);

/// Minute-resolution hero card fields (prayer, adhan/iqamah labels, status gate).
@riverpod
PrayerCardStaticInfo prayerCardStatic(Ref ref) {
  ref.watch(currentMinuteBucketProvider);
  final day = ref.read(prayerDayProvider).value;
  if (day == null) return _emptyPrayerCardStatic;

  final iqamahSettings =
      ref.watch(prayerSettingsProvider).value?.iqamahSettings ?? const {};
  final formatter = ref.watch(timeFormatterProvider);

  try {
    return _buildPrayerCardStatic(
      day: day,
      iqamahSettings: iqamahSettings,
      formatter: formatter,
    );
  } catch (_) {
    return _emptyPrayerCardStatic;
  }
}

/// Live countdown / elapsed string for the hero card (1 Hz).
@riverpod
String prayerCardCountdown(Ref ref) {
  final day = ref.watch(prayerDayProvider).value;
  if (day == null) return '00:00:00';

  final static = ref.read(prayerCardStaticProvider);
  final isArabic = ref.watch(localeProvider) == 'ar';

  return _formatCountdown(
    day: day,
    static: static,
    useHinduArabicNumerals: isArabic,
  );
}

/// Static hero card payload without the live countdown string.
typedef PrayerCardStaticInfo = ({
  Prayer prayer,
  String adhanTime,
  String iqamahTime,
  bool canSetStatus,
  bool showIqamah,
  bool isCountdown,
  DateTime referenceTime,
});

PrayerCardStaticInfo _buildPrayerCardStatic({
  required PrayerDaySnapshot day,
  required Map<Prayer, int> iqamahSettings,
  required DateFormat formatter,
}) {
  final decision = computePrayerCardDecision(snapshot: day);

  final iqamahMinutes = iqamahSettings[decision.prayer] ?? 0;
  final adhanTime = formatter.format(decision.referenceTime);
  final iqamahTime = formatter.format(
    decision.referenceTime.add(Duration(minutes: iqamahMinutes)),
  );

  return (
    prayer: decision.prayer,
    adhanTime: adhanTime,
    iqamahTime: iqamahTime,
    canSetStatus: decision.referenceTime.isBefore(day.now),
    showIqamah: iqamahMinutes > 0,
    isCountdown: decision.isCountdown,
    referenceTime: decision.referenceTime,
  );
}

String _formatCountdown({
  required PrayerDaySnapshot day,
  required PrayerCardStaticInfo static,
  required bool useHinduArabicNumerals,
}) {
  if (static.isCountdown) {
    return static.referenceTime
        .difference(day.now)
        .toHHMMSS(useHinduArabicNumerals: useHinduArabicNumerals);
  }
  return '+${day.now.difference(static.referenceTime).toHHMMSS(
    useHinduArabicNumerals: useHinduArabicNumerals,
  )}';
}
