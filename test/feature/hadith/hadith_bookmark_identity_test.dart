import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tawaq/feature/hadith/data/database/hadith_local_database.dart';
import 'package:tawaq/feature/hadith/data/repository/hadith_repository.dart';

class _Local extends Mock implements HadithLocalDatabase {}

class _Client extends Mock implements DorarClient {}

void main() {
  const record = DetailedHadith(
    hadith: 'saved ID-less wording',
    rawi: 'r',
    mohdith: 'm',
    book: 'b',
    numberOrPage: '1',
    grade: 'g',
  );
  test('legacy durable key controls toggle and repeat save', () async {
    final local = _Local();
    final repository = HadithRepository(
      client: _Client(),
      local: local,
      log: Logger(),
    );
    final entry = SavedHadithEntry(
      key: 'legacy-persisted-key',
      savedAt: DateTime(2020),
      hadith: record,
    );
    when(() => local.getFavoriteEntries()).thenAnswer((_) async => [entry]);
    when(() => local.deleteFavorite('legacy-persisted-key'))
        .thenAnswer((_) async {});
    when(() => local.addFavorite('legacy-persisted-key', record))
        .thenAnswer((_) async {});
    await repository.createFavorite(record);
    verify(() => local.addFavorite('legacy-persisted-key', record)).called(1);
    await repository.toggleFavorite(record);
    verify(() => local.deleteFavorite('legacy-persisted-key')).called(1);
    verify(() => local.getFavoriteEntries()).called(2);
    verifyNoMoreInteractions(local);
  });
}
