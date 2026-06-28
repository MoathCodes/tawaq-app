import 'package:adhan_dart/adhan_dart.dart';
import 'package:hisn_elmoslem/hisn_elmoslem.dart';
import 'package:tawaq/feature/muslim_fortress/domain/models/fortress_category.dart';
import 'package:tawaq/feature/prayer/domain/prayer_extensions.dart';
import 'package:timezone/timezone.dart';

/// Resolves [HisnFeaturedTitles] fragments that fit the current time of day.
///
/// Uses prayer windows when both [prayerTimes] and [location] are set;
/// otherwise falls back to clock hour.
///
/// [now] is the instant used to pick the window.
/// [prayerTimes] enables prayer-boundary matching when non-null.
/// [location] converts stored prayer instants to local time for [prayerTimes].
List<String> recommendTitleFragments({
  required DateTime now,
  PrayerTimes? prayerTimes,
  Location? location,
}) {
  if (prayerTimes != null && location != null) {
    return _fragmentsFromPrayerTimes(
      now: now,
      prayerTimes: prayerTimes,
      location: location,
    );
  }
  return _fragmentsFromClockHour(now.hour);
}

/// Maps title [fragments] to categories (deduped, max 4).
List<FortressCategory> fortressCategoriesForFragments({
  required List<FortressCategory> allCategories,
  required List<String> fragments,
}) {
  final result = <FortressCategory>[];
  final seenIds = <int>{};

  for (final fragment in fragments) {
    for (final category in allCategories) {
      if (!category.title.contains(fragment)) continue;
      if (!seenIds.add(category.chapterId)) continue;
      result.add(category);
      break;
    }
    if (result.length >= 4) break;
  }
  return result;
}

List<String> _fragmentsFromPrayerTimes({
  required DateTime now,
  required PrayerTimes prayerTimes,
  required Location location,
}) {
  final fajr = prayerTimes.fajr.toLocation(location);
  final sunrise = prayerTimes.sunrise.toLocation(location);
  final asr = prayerTimes.asr.toLocation(location);
  final maghrib = prayerTimes.maghrib.toLocation(location);
  final isha = prayerTimes.isha.toLocation(location);

  if (now.isBefore(fajr)) {
    return const [HisnFeaturedTitles.sleep];
  }
  if (now.isBefore(sunrise)) {
    return const [HisnFeaturedTitles.waking, HisnFeaturedTitles.morning];
  }
  if (now.isBefore(asr)) {
    return const [HisnFeaturedTitles.morning];
  }
  if (now.isBefore(maghrib)) {
    return const [HisnFeaturedTitles.evening];
  }
  if (now.isBefore(isha)) {
    return const [HisnFeaturedTitles.evening];
  }
  return const [HisnFeaturedTitles.sleep, HisnFeaturedTitles.evening];
}

List<String> _fragmentsFromClockHour(int hour) {
  if (hour >= 21 || hour < 4) {
    return const [HisnFeaturedTitles.sleep, HisnFeaturedTitles.evening];
  }
  if (hour < 12) {
    return const [HisnFeaturedTitles.waking, HisnFeaturedTitles.morning];
  }
  if (hour < 17) {
    return const [HisnFeaturedTitles.morning];
  }
  return const [HisnFeaturedTitles.evening, HisnFeaturedTitles.sleep];
}
