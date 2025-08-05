import 'package:adhan_dart/adhan_dart.dart';
import 'package:hasanat/l10n/app_localizations.dart';
import 'package:timezone/timezone.dart';

extension DateTimeDifference on DateTime {
  String timeDifference(DateTime other) {
    final duration = difference(other);
    return '${duration.inHours.toString().padLeft(2, '0')}:'
        '${(duration.inMinutes % 60).toString().padLeft(2, '0')}:'
        '${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  DateTime toLocation(Location location) {
    return TZDateTime.from(this, location);
  }
}

extension DurationFormatting on Duration {
  String toHHMMSS() {
    final hours = inHours;
    final minutes = inMinutes.remainder(60);
    final seconds = inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:'
        '${(minutes % 60).toString().padLeft(2, '0')}:'
        '${(seconds % 60).toString().padLeft(2, '0')}';
  }
}

extension MethodParamsExtension on CalculationMethod {
  CalculationParameters getParams() {
    return switch (this) {
      CalculationMethod.dubai => CalculationMethodParameters.dubai(),
      CalculationMethod.egyptian => CalculationMethodParameters.egyptian(),
      CalculationMethod.karachi => CalculationMethodParameters.karachi(),
      CalculationMethod.kuwait => CalculationMethodParameters.kuwait(),
      CalculationMethod.moonsightingCommittee =>
        CalculationMethodParameters.moonsightingCommittee(),
      CalculationMethod.morocco => CalculationMethodParameters.morocco(),
      CalculationMethod.muslimWorldLeague =>
        CalculationMethodParameters.muslimWorldLeague(),
      CalculationMethod.northAmerica =>
        CalculationMethodParameters.northAmerica(),
      CalculationMethod.other => CalculationMethodParameters.other(),
      CalculationMethod.qatar => CalculationMethodParameters.qatar(),
      CalculationMethod.singapore => CalculationMethodParameters.singapore(),
      CalculationMethod.tehran => CalculationMethodParameters.tehran(),
      CalculationMethod.turkiye => CalculationMethodParameters.turkiye(),
      CalculationMethod.ummAlQura => CalculationMethodParameters.ummAlQura(),
    };
  }
}

extension PrayerLocaleExtension on PrayerTimesData {
  DateTime getCurrentPrayerDateTime(Location location) {
    return switch (
        currentPrayer(date: TZDateTime.from(DateTime.now(), location))) {
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

  DateTime getNextPrayerDateTime(Location location) {
    return switch (
        nextPrayer(date: TZDateTime.from(DateTime.now(), location))) {
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

extension PrayerLocaleNameExtension on Prayer {
  String getLocaleName(AppLocalizations locale) {
    return switch (this) {
      Prayer.fajr => locale.fajr,
      Prayer.sunrise => locale.sunrise,
      Prayer.dhuhr => DateTime.now().toLocal().weekday == DateTime.friday
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
