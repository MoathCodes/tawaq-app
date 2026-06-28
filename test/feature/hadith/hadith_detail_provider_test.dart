import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tawaq/feature/hadith/data/repository/hadith_repository.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart'
    show hadithSharhProvider;

class MockHadithRepository extends Mock implements HadithRepository {}

/// Counts [HadithRepository.getSharh] calls for auto-dispose assertions.
class CountingHadithRepository extends Mock implements HadithRepository {
  CountingHadithRepository() {
    when(() => getSharh(any())).thenAnswer((invocation) async {
      sharhCallCount++;
      final sharhId = invocation.positionalArguments[0]! as String;
      return Sharh(
        hadith: ExplainedHadith(
          hadith: 'text for $sharhId',
          rawi: 'rawi',
          mohdith: 'mohdith',
          book: 'book',
          numberOrPage: '1',
          grade: 'sahih',
        ),
      );
    });
  }

  int sharhCallCount = 0;
}

Future<void> _waitForAutoDispose() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  group('hadithSharhProvider', () {
    late CountingHadithRepository repository;
    late ProviderContainer container;

    setUp(() {
      repository = CountingHadithRepository();
      container = ProviderContainer.test(
        overrides: [
          hadithRepositoryProvider.overrideWith((ref) async => repository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('is auto-dispose and refetches after all listeners drop', () async {
      final subA = container.listen(hadithSharhProvider('sharh-a'), (_, _) {});
      await container.read(hadithSharhProvider('sharh-a').future);
      expect(repository.sharhCallCount, 1);

      final subB = container.listen(hadithSharhProvider('sharh-b'), (_, _) {});
      await container.read(hadithSharhProvider('sharh-b').future);
      expect(repository.sharhCallCount, 2);

      subB.close();
      subA.close();
      await _waitForAutoDispose();

      final subAAgain = container.listen(
        hadithSharhProvider('sharh-a'),
        (_, _) {},
      );
      await container.read(hadithSharhProvider('sharh-a').future);
      subAAgain.close();

      expect(
        repository.sharhCallCount,
        3,
        reason: 'auto-dispose family should not retain sharh-a after unlisten',
      );
    });
  });
}
