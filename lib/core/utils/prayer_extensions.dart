import 'package:adhan_dart/adhan_dart.dart';
import 'package:hasanat/l10n/app_localizations.dart';
import 'package:timezone/timezone.dart';

/// Formatting helpers for computing human-readable time differences.
extension DateTimeDifference on DateTime {
  /// Returns the absolute difference between this time and [other] formatted
  /// as `HH:mm:ss`.
  String timeDifference(DateTime other) {
    final duration = difference(other);
    return '${duration.inHours.toString().padLeft(2, '0')}:'
        '${(duration.inMinutes % 60).toString().padLeft(2, '0')}:'
        '${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  /// Converts this [DateTime] to the given timezone [location].
  DateTime toLocation(Location location) {
    return TZDateTime.from(this, location);
  }
}

/// Convenience formatter for [Duration] instances.
extension DurationFormatting on Duration {
  /// Returns the duration formatted as `HH:mm:ss`.
  String toHHMMSS({required bool useHinduArabicNumerals}) {
    final hours = inHours;
    final minutes = inMinutes.remainder(60);
    final seconds = inSeconds.remainder(60);
    final time =
        '${hours.toString().padLeft(2, '0')}:'
        '${(minutes % 60).toString().padLeft(2, '0')}:'
        '${(seconds % 60).toString().padLeft(2, '0')}';

    // Map Western digits to Arabic-Indic (Hindu-Arabic) numerals.
    const arabicIndicDigits = [
      '٠',
      '١',
      '٢',
      '٣',
      '٤',
      '٥',
      '٦',
      '٧',
      '٨',
      '٩',
    ];
    if (!useHinduArabicNumerals) return time;
    return time.replaceAllMapped(RegExp(r'\d'), (m) {
      final idx = int.parse(m[0]!);
      return arabicIndicDigits[idx];
    });
  }
}

/// Localized labels for [CalculationMethod] values.
extension MethodLocaleExtension on CalculationMethod {
  /// Returns the localized name for this calculation method.
  String getLocaleName(AppLocalizations locale) {
    return switch (this) {
      OtherCalculationMethod() => locale.other,
      MuslimWorldLeague() => locale.muslimWorldLeague,
      Egyptian() => locale.egyptian,
      Karachi() => locale.karachi,
      UmmAlQura() => locale.ummAlQura,
      Dubai() => locale.dubai,
      MoonsightingCommittee() => locale.moonsightingCommittee,
      NorthAmerica() => locale.northAmerica,
      Kuwait() => locale.kuwait,
      Qatar() => locale.qatar,
      Singapore() => locale.singapore,
      Tehran() => locale.tehran,
      Turkiye() => locale.turkiye,
      Morocco() => locale.morocco,
      CustomCalculationMethod() => locale.other,
    };
  }
}

/// Utilities for reading localized prayer times from [PrayerTimes].
extension PrayerLocaleExtension on PrayerTimes {
  /// Returns the [DateTime] of the currently active prayer in the [location].
  DateTime getCurrentPrayerDateTime(Location location) {
    return switch (currentPrayer(
      time: TZDateTime.from(DateTime.now(), location),
    )) {
      Prayer.fajr => TZDateTime.from(fajr, location),
      Prayer.sunrise => TZDateTime.from(sunrise, location),
      Prayer.dhuhr => TZDateTime.from(dhuhr, location),
      Prayer.asr => TZDateTime.from(asr, location),
      Prayer.maghrib => TZDateTime.from(maghrib, location),
      Prayer.isha => TZDateTime.from(isha, location),
      Prayer.ishaBefore => TZDateTime.from(ishaBefore, location),
      Prayer.fajrAfter => TZDateTime.from(fajrAfter, location),
    };
  }

  /// Returns the [DateTime] of the next prayer in the given [location].
  DateTime getNextPrayerDateTime(Location location) {
    return switch (nextPrayer(
      time: TZDateTime.from(DateTime.now(), location),
    )) {
      Prayer.fajr => TZDateTime.from(fajr, location),
      Prayer.sunrise => TZDateTime.from(sunrise, location),
      Prayer.dhuhr => TZDateTime.from(dhuhr, location),
      Prayer.asr => TZDateTime.from(asr, location),
      Prayer.maghrib => TZDateTime.from(maghrib, location),
      Prayer.isha => TZDateTime.from(isha, location),
      Prayer.ishaBefore => TZDateTime.from(ishaBefore, location),
      Prayer.fajrAfter => TZDateTime.from(fajrAfter, location),
    };
  }

  /// Returns the localized [DateTime] for [prayer] in the supplied [location].
  DateTime getTimesForPrayer(Prayer prayer, Location location) {
    return switch (prayer) {
      Prayer.fajr => TZDateTime.from(fajr, location),
      Prayer.sunrise => TZDateTime.from(sunrise, location),
      Prayer.dhuhr => TZDateTime.from(dhuhr, location),
      Prayer.asr => TZDateTime.from(asr, location),
      Prayer.maghrib => TZDateTime.from(maghrib, location),
      Prayer.isha => TZDateTime.from(isha, location),
      Prayer.ishaBefore => TZDateTime.from(ishaBefore, location),
      Prayer.fajrAfter => TZDateTime.from(fajrAfter, location),
    };
  }
}

/// Localized display names for [Prayer] values.
extension PrayerLocaleNameExtension on Prayer {
  /// Returns true if this prayer is one of the five obligatory prayers.
  bool get isObligatory => switch (this) {
    Prayer.sunrise => false,
    Prayer.ishaBefore => false,
    Prayer.fajrAfter => false,
    _ => true,
  };

  /// Returns the localized label for this prayer, including Friday handling
  /// for Jumu'ah.
  String getLocaleName(AppLocalizations locale) {
    return switch (this) {
      Prayer.fajr => locale.fajr,
      Prayer.sunrise => locale.sunrise,
      Prayer.dhuhr =>
        DateTime.now().toLocal().weekday == DateTime.friday
            ? locale.jumuah
            : locale.dhuhr,
      Prayer.asr => locale.asr,
      Prayer.maghrib => locale.maghrib,
      Prayer.isha => locale.isha,
      Prayer.ishaBefore => locale.lastThirdOfTheNight,
      Prayer.fajrAfter => locale.midnight,
    };
  }
}
