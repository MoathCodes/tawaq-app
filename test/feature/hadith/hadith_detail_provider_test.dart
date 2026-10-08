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
        hadith: DetailedHadith(
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
  group('typed explanation provider', () {
    late CountingDorarClient client;
    late ProviderContainer container;

    setUp(() {
      client = CountingDorarClient();
      container = ProviderContainer.test(
        overrides: [dorarClientProvider.overrideWith((ref) async => client)],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'usul and complete related responses retain metadata and seed scope',
      () async {
        const record = DetailedHadith(
          hadith: 'seed',
          rawi: 'r',
          mohdith: 'm',
          book: 'b',
          numberOrPage: '1',
          grade: 'g',
        );
        const related = [record, record];
        const metadata = SearchMetadata(
          diagnostics: ParseDiagnostics(candidateCount: 2, parsedCount: 2),
        );
        const alternates = ApiResponse(
          data: RelatedHadithResult(
            requestedId: 'abc',
            source: record,
            kind: RelatedHadithKind.alternate,
            related: related,
          ),
          metadata: metadata,
        );
        const similar = ApiResponse(
          data: RelatedHadithResult(
            requestedId: 'abc',
            source: record,
            kind: RelatedHadithKind.similar,
            related: related,
          ),
          metadata: metadata,
        );
        const usul = ApiResponse(
          data: UsulHadith(hadith: record, sources: [], count: 0),
          metadata: metadata,
        );
        when(() => client.getAlternates('abc'))
            .thenAnswer((_) async => alternates);
        when(() => client.getSimilarResult('abc'))
            .thenAnswer((_) async => similar);
        when(() => client.getUsulHadith('abc')).thenAnswer((_) async => usul);
        expect(
          await container.read(
            hadithRelatedProvider(
              HadithRecordId('abc'),
              RelatedHadithKind.alternate,
            ).future,
          ),
          same(alternates),
        );
        final result = await container.read(
          hadithRelatedProvider(
            HadithRecordId('abc'),
            RelatedHadithKind.similar,
          ).future,
        );
        expect(result, same(similar));
        expect(
          result.data.related,
          related,
          reason: 'ambiguous ordered records are not deduplicated',
        );
        expect(
          await container.read(
            hadithUsulProvider(HadithRecordId('abc')).future,
          ),
          same(usul),
        );
      },
    );

    test('is auto-dispose and refetches after all listeners drop', () async {
      final subA = container.listen(
        hadithSharhProvider(SharhId('1')),
        (_, _) {},
      );
      await container.read(hadithSharhProvider(SharhId('1')).future);
      expect(client.sharhCallCount, 1);

      final subB = container.listen(
        hadithSharhProvider(SharhId('2')),
        (_, _) {},
      );
      await container.read(hadithSharhProvider(SharhId('2')).future);
      expect(client.sharhCallCount, 2);

      subB.close();
      subA.close();
      await _waitForAutoDispose();

      final subAAgain = container.listen(
        hadithSharhProvider(SharhId('1')),
        (_, _) {},
      );
      await container.read(hadithSharhProvider(SharhId('1')).future);
      subAAgain.close();

      expect(
        client.sharhCallCount,
        3,
        reason: 'auto-dispose family should not retain sharh-a after unlisten',
      );
    });
  });
}
