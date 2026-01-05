import 'package:adhan_dart/adhan_dart.dart';
import 'package:hasanat/core/logging/logger_provider.dart';
import 'package:hasanat/feature/prayer/data/database/prayer_database.dart';
import 'package:hasanat/feature/prayer/data/models/prayer_completion.dart';
import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timezone/timezone.dart';

part 'prayer_repo.g.dart';

/// Provides a singleton instance of the [PrayerRepo].
@riverpod
PrayerRepo prayerRepo(Ref ref) {
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
  Future<void> addOrUpdateCompletion(PrayerCompletion completion) async {
    try {
      await prayerDatabase.insertOrUpdateCompletion(completion);
    } catch (e, stackTrace) {
      log.e(
        'Error adding/updating completion',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Counts the number of all prayers on a given date.
  Future<int> countAllPrayersOnDate(DateTime from, DateTime to) {
    return prayerDatabase.countAllPrayersOnDate(from, to);
  }

  /// Counts the number of prayers for each completion status on a given date.
  Future<Map<CompletionStatus, int>> countAllStatusesOnDate(
    DateTime from,
    DateTime to,
  ) {
    return prayerDatabase.countAllPrayerStatusOnDate(from, to);
  }

  /// Counts the number of prayers with a specific completion status on a given date.
  Future<int> countPrayerStatusOnDate(
    CompletionStatus status,
    DateTime from,
    DateTime to,
  ) {
    return prayerDatabase.countPrayerStatusOnDate(status, from, to);
  }

  /// Deletes a prayer completion.
  Future<void> deleteCompletion(int id) {
    return prayerDatabase.deleteCompletion(id);
  }

  /// Returns whether a prayer completion exists.
  Future<bool> doesCompletionExists(int id) {
    return prayerDatabase.isCompletionExists(id);
  }

  /// Returns all prayer completions.
  Future<List<PrayerCompletion>> getAllCompletions() {
    return prayerDatabase.getAllCompletions();
  }

  /// Returns a list of dates on which all prayers were completed.
  Future<List<DateTime>> getFullyCompletedDays(Location loc) {
    return prayerDatabase.getFullyCompletedDays(loc);
  }

  /// Watches for changes to the prayer completions on a specific date.
  Future<List<PrayerCompletion>> getPrayerCompletionForDate(DateTime date) {
    return prayerDatabase.getCompletionsForDate(date);
  }

  /// Returns the prayer times for a given date, coordinates, and calculation parameters.
  PrayerTimesData getPrayerTimes(
    DateTime date,
    Coordinates coordinates,
    CalculationParameters calculationParameters,
    bool roundToMinutes,
  ) {
    final prayerTimes = PrayerTimesData.calculate(
      date: date,
      coordinates: coordinates,
      calculationParameters: calculationParameters,
      roundToMinutes: roundToMinutes,
    );
    return prayerTimes;
  }

  /// Returns a prayer completion by its ID.
  Future<PrayerCompletion?> getSingleCompletion(int id) {
    return prayerDatabase.getCompletionById(id);
  }

  /// Returns the sunnah times for a given prayer times.
  SunnahTimes getSunnahTime(PrayerTimesData prayerTimes) {
    final sunnahTimes = SunnahTimes(prayerTimes);
    // print("in repo getSunnahTime: ${sunnahTimes.middleOfTheNight}");
    return sunnahTimes;
  }
}
