import 'package:adhan_dart/adhan_dart.dart';
import 'package:tawaq/feature/prayer/data/models/prayer_completion.dart';
import 'package:tawaq/feature/prayer/domain/prayer_calendar.dart';
import 'package:tawaq/feature/prayer/domain/prayer_slots.dart';
import 'package:timezone/timezone.dart';

export 'package:tawaq/feature/prayer/domain/prayer_calendar.dart'
    show completionCalendarDay, completionDayKey;

String completionGroupKey(PrayerCompletion completion, Location location) {
  return '${completionDayKey(completion.completionTime, location)}_'
      '${completion.prayer.name}';
}

/// Picks the canonical row for [prayer] on [day] from [rows].
///
/// Highest [PrayerCompletion.id] wins; tie-break by latest [completionTime].
PrayerCompletion? pickCanonical(
  List<PrayerCompletion> rows, {
  required Prayer prayer,
  required Location location,
  required DateTime day,
}) {
  final matches = rows.where(
    (c) =>
        c.prayer == prayer &&
        completionDayKey(c.completionTime, location) ==
            completionDayKey(day, location),
  );
  if (matches.isEmpty) return null;
  return matches.reduce(preferCanonicalCompletion);
}

/// Returns one canonical row per `(calendar_day, prayer)` in [location].
List<PrayerCompletion> dedupeCompletions(
  List<PrayerCompletion> rows,
  Location location,
) {
  final groups = <String, List<PrayerCompletion>>{};
  for (final row in rows) {
    groups.putIfAbsent(completionGroupKey(row, location), () => []).add(row);
  }
  return [
    for (final group in groups.values) group.reduce(preferCanonicalCompletion),
  ];
}

/// Maps obligatory prayers to their canonical status on [day].
Map<Prayer, CompletionStatus> mapPrayerStatuses(
  List<PrayerCompletion> rows,
  Location location,
  DateTime day,
) {
  final statuses = {
    for (final prayer in kObligatoryPrayers) prayer: CompletionStatus.none,
  };
  for (final prayer in kObligatoryPrayers) {
    final canonical = pickCanonical(
      rows,
      prayer: prayer,
      location: location,
      day: day,
    );
    if (canonical != null) {
      statuses[prayer] = canonical.status;
    }
  }
  return statuses;
}

/// Counts completion statuses after deduping per `(calendar_day, prayer)`.
Map<CompletionStatus, int> countDedupedStatuses(
  List<PrayerCompletion> rows,
  Location location,
) {
  final counts = {
    for (final status in CompletionStatus.values) status: 0,
  };
  for (final completion in dedupeCompletions(rows, location)) {
    counts[completion.status] = (counts[completion.status] ?? 0) + 1;
  }
  return counts;
}

/// Highest [PrayerCompletion.id] wins; tie-break by latest [completionTime].
PrayerCompletion preferCanonicalCompletion(
  PrayerCompletion a,
  PrayerCompletion b,
) {
  final aId = a.id ?? -1;
  final bId = b.id ?? -1;
  if (aId != bId) {
    return aId > bId ? a : b;
  }
  return a.completionTime.isAfter(b.completionTime) ? a : b;
}
