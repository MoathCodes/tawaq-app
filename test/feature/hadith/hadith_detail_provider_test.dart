import 'package:dorar_hadith/dorar_hadith.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tawaq/feature/hadith/data/repository/hadith_repository.dart';
import 'package:tawaq/feature/hadith/presentation/provider/hadith_provider.dart';

/// Counts [DorarClient.getSharhById] calls for auto-dispose assertions.
class CountingDorarClient extends Mock implements DorarClient {
  new() {
    when(() => getSharhById(any())).thenAnswer((invocation) async {
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
  group('hadithDetailProvider', () {
    late CountingDorarClient client;
    late ProviderContainer container;

    setUp(() {
      client = CountingDorarClient();
      container = ProviderContainer.test(
        overrides: [
          dorarClientProvider.overrideWith((ref) async => client),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('is auto-dispose and refetches after all listeners drop', () async {
      final subA = container.listen(
        hadithDetailProvider(HadithDetailKind.sharh, 'sharh-a'),
        (_, _) {},
      );
      await container.read(
        hadithDetailProvider(HadithDetailKind.sharh, 'sharh-a').future,
      );
      expect(client.sharhCallCount, 1);

      final subB = container.listen(
        hadithDetailProvider(HadithDetailKind.sharh, 'sharh-b'),
        (_, _) {},
      );
      await container.read(
        hadithDetailProvider(HadithDetailKind.sharh, 'sharh-b').future,
      );
      expect(client.sharhCallCount, 2);

      subB.close();
      subA.close();
      await _waitForAutoDispose();

      final subAAgain = container.listen(
        hadithDetailProvider(HadithDetailKind.sharh, 'sharh-a'),
        (_, _) {},
      );
      await container.read(
        hadithDetailProvider(HadithDetailKind.sharh, 'sharh-a').future,
      );
      subAAgain.close();

      expect(
        client.sharhCallCount,
        3,
        reason: 'auto-dispose family should not retain sharh-a after unlisten',
      );
    });
  });
}
