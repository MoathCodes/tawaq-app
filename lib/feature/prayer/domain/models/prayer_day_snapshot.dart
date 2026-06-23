import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/foundation.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_day_bundle.dart';
import 'package:timezone/timezone.dart';

/// Localized prayer boundaries for the cached today / yesterday pair.
@immutable
class PrayerDayTimeline {
  /// Creates a timeline snapshot.
  const PrayerDayTimeline({
    required this.fajrToday,
    required this.sunriseToday,
    required this.dhuhrToday,
    required this.asrToday,
    required this.maghribToday,
    required this.ishaToday,
    required this.ishaYesterday,
    required this.middleOfNightToday,
    required this.middleOfNightYesterday,
    required this.lastThirdToday,
    required this.lastThirdYesterday,
  });

  final TZDateTime fajrToday;
  final TZDateTime sunriseToday;
  final TZDateTime dhuhrToday;
  final TZDateTime asrToday;
  final TZDateTime maghribToday;
  final TZDateTime ishaToday;
  final TZDateTime ishaYesterday;
  final TZDateTime middleOfNightToday;
  final TZDateTime middleOfNightYesterday;
  final TZDateTime lastThirdToday;
  final TZDateTime lastThirdYesterday;
}

/// Live prayer-day context: clock + today's/yesterday's schedules.
@immutable
class PrayerDaySnapshot {
  /// Creates a snapshot.
  const PrayerDaySnapshot({
    required this.now,
    required this.location,
    required this.bundle,
  });

  final TZDateTime now;
  final Location location;
  final PrayerDayBundle bundle;

  PrayerTimes get today => bundle.today;
  PrayerTimes get yesterday => bundle.yesterday;
  SunnahTimes get todaySunnah => bundle.todaySunnah;
  SunnahTimes get yesterdaySunnah => bundle.yesterdaySunnah;
  PrayerDayTimeline get timeline => bundle.timeline;

  /// Stable key for providers that only care about the calendar day.
  int get calendarDayKey => now.year * 10000 + now.month * 100 + now.day;

  /// Whether [date] falls on the same local calendar day as [now].
  bool isSameCalendarDay(DateTime date) =>
      date.year == now.year && date.month == now.month && date.day == now.day;
}
