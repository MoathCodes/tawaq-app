import 'package:adhan_dart/adhan_dart.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hasanat/core/logging/talker_provider.dart';
import 'package:hasanat/feature/prayer/data/database/prayer_database.dart';
import 'package:hasanat/feature/prayer/data/models/prayer_completion.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'prayer_repo.g.dart';

@riverpod
PrayerRepo prayerRepo(Ref ref) {
  final database = ref.read(prayerDatabaseProvider);
  final talker = ref.read(talkerNotifierProvider);
  return PrayerRepo(prayerDatabase: database, talker: talker);
}

class PrayerRepo {
  final PrayerDatabase prayerDatabase;
  final Talker talker;
  const PrayerRepo({required this.prayerDatabase, required this.talker});

  Future<void> addOrUpdateCompletion(PrayerCompletion completion) {
    final companion = completion.id != null
        ? PrayerCompletionsCompanion(
            id: Value(completion.id!),
            status: Value(completion.status),
            completionTime: Value(completion.completionTime),
            prayer: Value(completion.prayer),
          )
        : PrayerCompletionsCompanion(
            status: Value(completion.status),
            completionTime: Value(completion.completionTime),
            prayer: Value(completion.prayer),
          );

    return prayerDatabase.insertOrUpdateCompletion(companion);
  }

  Future<void> deleteCompletion(int id) {
    return prayerDatabase.deleteCompletion(id);
  }

  Future<List<PrayerCompletion>> getAllCompletions() {
    return prayerDatabase.getAllCompletions();
  }

  PrayerTimes getPrayerTimes(DateTime date, Coordinates coordinates,
      CalculationParameters calculationParameters) {
    final prayerTimes = PrayerTimes(
      date: date,
      coordinates: coordinates,
      calculationParameters: calculationParameters,
    );
    return prayerTimes;
  }

  Future<PrayerCompletion?> getSingleCompletion(int id) {
    return prayerDatabase.getCompletionById(id);
  }

  SunnahTimes getSunnahTime(PrayerTimes prayerTimes) {
    final sunnahTimes = SunnahTimes(prayerTimes);
    // print("in repo getSunnahTime: ${sunnahTimes.middleOfTheNight}");
    return sunnahTimes;
  }

  Future<bool> isCompletionExists(int id) {
    return prayerDatabase.isCompletionExists(id);
  }

  Stream<List<PrayerCompletion>> watchPrayerCompletionByDate(
      int year, int month, int day) {
    return prayerDatabase.watchCompletionsBasedOnDate(
      day,
      month,
      year,
    );
  }
}
