import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tawaq/core/database/asset_database_service.dart';
import 'package:tawaq/feature/quran/data/models/tafsir.dart';
import 'package:tawaq/feature/quran/data/repository/tafsir_repository.dart';
import 'package:tawaq/feature/quran/domain/models/tafsir_source.dart';
import 'package:tawaq/feature/quran/presentation/providers/tafsir_provider.dart';

/// Counts [TafsirRepository.getTafsir] calls for LRU / auto-dispose assertions.
class CountingTafsirRepository extends TafsirRepository {
  CountingTafsirRepository() : super(AssetDatabaseService());

  int callCount = 0;

  @override
  Future<Tafsir?> getTafsir(TafsirId source, int suraNo, int ayaNo) async {
    callCount++;
    return Tafsir(
      id: callCount,
      suraNo: suraNo,
      ayaNo: ayaNo,
      ayaTafseer: 'Commentary for $suraNo:$ayaNo',
    );
  }
}

Future<void> _waitForAutoDispose() async {
  // Riverpod disposes auto-dispose providers one frame after last listener.
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  group('tafsirForAyahProvider', () {
    late CountingTafsirRepository repository;
    late ProviderContainer container;

    setUp(() {
      repository = CountingTafsirRepository();
      container = ProviderContainer.test(
        overrides: [
          tafsirRepositoryProvider.overrideWithValue(repository),
        ],
      );
    });

    test('is auto-dispose and reuses keepAlive LRU after unlisten', () async {
      const source = TafsirId.tafseerMouaser;

      final subA = container.listen(
        tafsirForAyahProvider(source, 1, 1),
        (_, _) {},
      );
      await container.read(tafsirForAyahProvider(source, 1, 1).future);
      expect(repository.callCount, 1);

      final subB = container.listen(
        tafsirForAyahProvider(source, 1, 2),
        (_, _) {},
      );
      await container.read(tafsirForAyahProvider(source, 1, 2).future);
      expect(repository.callCount, 2);

      subB.close();
      subA.close();
      await _waitForAutoDispose();

      final subAAgain = container.listen(
        tafsirForAyahProvider(source, 1, 1),
        (_, _) {},
      );
      await container.read(tafsirForAyahProvider(source, 1, 1).future);
      subAAgain.close();

      expect(
        repository.callCount,
        2,
        reason: 'LRU row + parse caches should satisfy revisit without fetch',
      );
    });
  });
}
