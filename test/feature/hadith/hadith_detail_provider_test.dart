import 'package:dorar_hadith/dorar_hadith.dart' hide HadithService;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tawaq/feature/hadith/data/repository/hadith_repository.dart';
import 'package:tawaq/feature/hadith/domain/services/hadith_service.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart'
    show hadithSharhProvider;

class MockHadithRepository extends Mock implements HadithRepository {}

/// Counts [HadithService.getSharh] calls for auto-dispose assertions.
class CountingHadithService extends HadithService {
  CountingHadithService({required super.repository})
    : super(log: Logger());

  int sharhCallCount = 0;

  @override
  Future<Sharh> getSharh(String sharhId) async {
    sharhCallCount++;
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
  }
}

Future<void> _waitForAutoDispose() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  group('hadithSharhProvider', () {
    late CountingHadithService service;
    late ProviderContainer container;

    late MockHadithRepository repository;

    setUp(() {
      repository = MockHadithRepository();
      service = CountingHadithService(repository: repository);
      container = ProviderContainer.test(
        overrides: [
          hadithServiceProvider.overrideWith((ref) async => service),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('is auto-dispose and refetches after all listeners drop', () async {
      final subA = container.listen(hadithSharhProvider('sharh-a'), (_, _) {});
      await container.read(hadithSharhProvider('sharh-a').future);
      expect(service.sharhCallCount, 1);

      final subB = container.listen(hadithSharhProvider('sharh-b'), (_, _) {});
      await container.read(hadithSharhProvider('sharh-b').future);
      expect(service.sharhCallCount, 2);

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
        service.sharhCallCount,
        3,
        reason: 'auto-dispose family should not retain sharh-a after unlisten',
      );
    });
  });
}
