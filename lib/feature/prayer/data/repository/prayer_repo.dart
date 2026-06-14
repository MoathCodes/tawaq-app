import 'package:adhan_dart/adhan_dart.dart';
import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tawaq/core/logging/logger_provider.dart';
import 'package:tawaq/feature/prayer/data/database/prayer_database.dart';
import 'package:tawaq/feature/prayer/data/models/prayer_completion.dart';
import 'package:timezone/timezone.dart';

part 'prayer_repo.g.dart';

/// Provides a singleton instance of the [PrayerRepo].
@riverpod
PrayerRepo prayerRepo(Ref ref) {
  ref.watch(prayerCompletionsRepairProvider);
  final database = ref.read(prayerDatabaseProvider);
  final log = ref.read(loggerProvider);
  return PrayerRepo(prayerDatabase: database, log: log);
}

/// A repository for accessing prayer data.
class PrayerRepo {
  /// Creates a new instance of the [PrayerRepo].
  const PrayerRepo({required this.prayerDatabase, required this.log});

  /// The database for the prayer data.
  final PrayerDatabase prayerDatabase;

  /// The logger for the application.
  final Logger log;

  /// Adds or updates a prayer completion.
  Future<void> addOrUpdateCompletion(
    PrayerCompletion completion,
    Location location,
  ) async {
    try {
      await prayerDatabase.insertOrUpdateCompletion(completion, location);
    } catch (e, stackTrace) {
      log.e(
        'Error adding/updating completion',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Counts deduped completion statuses between [from] and [to].
  Future<Map<CompletionStatus, int>> countAllStatusesOnDate(
    DateTime from,
    DateTime to,
    Location location,
  ) {
    return prayerDatabase.countAllPrayerStatusOnDate(from, to, location);
  }

  /// Counts deduped prayers with [status] between [from] and [to].
  Future<int> countPrayerStatusOnDate(
    CompletionStatus status,
    DateTime from,
    DateTime to,
    Location location,
  ) {
    return prayerDatabase.countPrayerStatusOnDate(status, from, to, location);
  }

  /// Deletes a prayer completion.
  Future<void> deleteCompletion(int id) {
    return prayerDatabase.deleteCompletion(id);
  }

  /// Deletes all completions for [prayer] on [date]'s calendar day.
  Future<void> deleteCompletionForPrayerOnDate(
    Prayer prayer,
    DateTime date,
    Location location,
  ) {
    return prayerDatabase.deleteCompletionForPrayerOnDate(
      prayer,
      date,
      location,
    );
  }

  /// Returns whether a prayer completion exists.
  Future<bool> doesCompletionExists(int id) {
    return prayerDatabase.isCompletionExists(id);
  }

  /// Returns all prayer completions.
  Future<List<PrayerCompletion>> getAllCompletions() {
    return prayerDatabase.getAllCompletions();
  }

  /// Returns the earliest logged completion time, if any.
  Future<DateTime?> getEarliestCompletionTime() {
    return prayerDatabase.getEarliestCompletionTime();
  }

  /// Returns a list of dates on which all prayers were completed.
  Future<List<DateTime>> getFullyCompletedDays(Location loc) {
    return prayerDatabase.getFullyCompletedDays(loc);
  }

  /// Returns prayer completions recorded on [date].
  Future<List<PrayerCompletion>> getPrayerCompletionForDate(
    DateTime date,
    Location location,
  ) {
    return prayerDatabase.getCompletionsForDate(date, location);
  }

  /// Returns all prayer completions between [from] and [to] (inclusive).
  Future<List<PrayerCompletion>> getCompletionsBetween(
    DateTime from,
    DateTime to,
  ) {
    return prayerDatabase.getCompletionsBetween(from, to);
  }

  /// Returns the prayer times for a given date, coordinates, and calculation
  /// parameters.
  PrayerTimes getPrayerTimes(
    DateTime date,
    Coordinates coordinates,
    CalculationMethod calculationMethod, {
    bool roundToMinutes = true,
  }) {
    final prayerTimes = PrayerTimes(
      date: date,
      coordinates: coordinates,
      calculationMethod: calculationMethod,
      roundToMinutes: roundToMinutes,
    );
    return prayerTimes;
  }

  /// Returns a prayer completion by its ID.
  Future<PrayerCompletion?> getSingleCompletion(int id) {
    return prayerDatabase.getCompletionById(id);
  }

  /// Returns the sunnah times for a given prayer times.
  SunnahTimes getSunnahTime(PrayerTimes prayerTimes) {
    final sunnahTimes = SunnahTimes(prayerTimes);
    // print("in repo getSunnahTime: ${sunnahTimes.middleOfTheNight}");
    return sunnahTimes;
  }
}
