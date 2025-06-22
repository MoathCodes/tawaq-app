// import 'dart:io';

// import 'package:adhan_dart/adhan_dart.dart';
// import 'package:drift/drift.dart';
// import 'package:drift/native.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:hasanat/feature/prayer/data/models/prayer_completion.dart';
// import 'package:path/path.dart' as p;
// import 'package:path_provider/path_provider.dart';
// import 'package:riverpod_annotation/riverpod_annotation.dart';

// part 'prayer_database.g.dart';

// @Riverpod(keepAlive: true)
// PrayerDatabase prayerDatabase(Ref ref) {
//   final database = LazyDatabase(() async {
//     final dbFolder = await getApplicationDocumentsDirectory();
//     final file = File(p.join(dbFolder.path, 'prayer.db'));
//     return NativeDatabase(file);
//   });
//   final prayerDatabase = PrayerDatabase(database);
//   ref.onDispose(() async {
//     await prayerDatabase.close();
//   });
//   return prayerDatabase;
// }

// @UseRowClass(PrayerCompletion)
// class PrayerCompletions extends Table {
//   DateTimeColumn get completionTime => dateTime()();
//   IntColumn get id => integer().autoIncrement()();
//   IntColumn get prayer => intEnum<Prayer>()();
//   @override
//   Set<Column> get primaryKey => {id};

//   IntColumn get status => intEnum<CompletionStatus>()();
// }

// @DriftDatabase(tables: [PrayerCompletions])
// class PrayerDatabase extends _$PrayerDatabase {
//   PrayerDatabase(super.executor);

//   @override
//   int get schemaVersion => 1;

//   Future<void> deleteCompletion(int id) {
//     final query = managers.prayerCompletions.filter((f) => f.id.equals(id));
//     return query.delete();
//   }

//   Future<List<PrayerCompletion>> getAllCompletions() {
//     final query = select(prayerCompletions);
//     return query.get();
//   }

//   Future<PrayerCompletion?> getCompletionById(int id) {
//     final query = managers.prayerCompletions.filter((f) => f.id.equals(id));
//     return query.getSingleOrNull();
//   }

//   Future<void> insertOrUpdateCompletion(PrayerCompletionsCompanion completion) {
//     final query = into(prayerCompletions);
//     return query.insertOnConflictUpdate(completion);
//   }

//   Future<bool> isCompletionExists(int id) {
//     final query = managers.prayerCompletions.filter(
//       (f) => f.id.equals(id),
//     );
//     return query.exists();
//   }

//   Stream<List<PrayerCompletion>> watchCompletionsBasedOnDate(
//       int day, int month, int year) {
//     final query = managers.prayerCompletions.filter((f) =>
//         f.completionTime.column.year.equals(year) &
//         f.completionTime.column.month.equals(month) &
//         f.completionTime.column.day.equals(day));

//     return query.watch();
//   }
// }
