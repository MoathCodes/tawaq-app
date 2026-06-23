import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/foundation.dart';
import 'package:tawaq/feature/prayer/domain/models/prayer_day_snapshot.dart';

/// Prayer times, sunnah windows, and timeline for a today/yesterday pair.
@immutable
class PrayerDayBundle {
  /// Creates a [PrayerDayBundle].
  const PrayerDayBundle({
    required this.today,
    required this.yesterday,
    required this.todaySunnah,
    required this.yesterdaySunnah,
    required this.timeline,
  });

  final PrayerTimes today;
  final PrayerTimes yesterday;
  final SunnahTimes todaySunnah;
  final SunnahTimes yesterdaySunnah;
  final PrayerDayTimeline timeline;
}
